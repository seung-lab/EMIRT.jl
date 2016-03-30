export affs_fr_rand_error, seg_fr_rand_error, seg_fr_rand_f_score, affs_error_curve, affs_fr_rand_errors, segerror, patch_segerror

#using PyCall

include("affinity.jl")
include("label.jl")
include("domains.jl")

# rand error curve
function affs_error_curve(affs::Taffs, lbl::Tseg, dim=3, step=0.1, seg_method="watershed", is_patch=false, redist = "uniform")
    @assert size(affs)[1:3] == size(lbl)
    sx,sy,sz = size(lbl)
    # transform to uniform distribution
    if redist == "uniform"
        affs = affs2uniform(affs);
    end
    # thresholds
    if seg_method=="connected_component"
        thds = Array( 0 : step : 1 )
    else
        thds = Array( 0 : step : 0.9)
    end
    # rand error
    re = zeros(thds)
    rem = zeros(thds)
    res = zeros(thds)
    # rand f score
    rf =  zeros(thds)
    rfm = zeros(thds)
    rfs = zeros(thds)

    @assert seg_method=="connected_component" || seg_method=="watershed"
    # handle the dimension
    @assert dim==2 || dim==3
    if dim==2
        lbl = relabel_seg(lbl, 2)
    end
    lbl = Array{UInt64,3}(lbl)

    segs = zeros(UInt32, (length(thds), sx,sy,sz))

    # if watershed, get watershed domains and mst first
    if seg_method == "watershed" && dim==3
        wsdms, rt = watershed(affs, 0, 0.95, [], 0)
    end

    for i in eachindex(thds)

        if seg_method == "watershed"
            if dim==2
                seg = wsseg(affs, 2, 0,  0.95, [], 0, thds[i])
            else
                seg = mergert(wsdms, rt, thds[i])
            end
        else
            seg = aff2seg( affs, dim, thds[i] )
        end

        #seg = Array{UInt64,3}(seg)
        segs[i,:,:,:]  = seg
        # rand f score and rand error
        if dim==3
            #@pyimport segerror.error as serror
            #rf[i], rfm[i], rfs[i] = serror.seg_fr_rand_f_score(seg, lbl, true, true)
            #re[i], rem[i], res[i] = serror.seg_fr_rand_error(seg, lbl, true, true)
            if is_patch
                @time re[i], rem[i], res[i], rf[i], rfm[i], rfs[i] = patch_segerror(seg, lbl)
            else
                @time re[i], rem[i], res[i], rf[i], rfm[i], rfs[i] = segerror(seg, lbl)
            end
        else
            # 2D rand error and rand f score
            for z in 1:sz
                if is_patch
                    @time rez, remz, resz, rfz, rfmz, rfsz = patch_segerror(seg[:,:,z], lbl[:,:,z])
                    # @pyimport segerror.error as serror
                    # rfz, rfmz, rfsz = serror.seg_fr_rand_f_score(seg[:,:,z], lbl[:,:,z], true, true)
                    # rez, remz, resz = serror.seg_fr_rand_error(seg[:,:,z], lbl[:,:,z], true, true)
                else
                    # @pyimport segerror.error as serror
                    # rfz, rfmz, rfsz = serror.seg_fr_rand_f_score(seg[:,:,z], lbl[:,:,z], true, true)
                    # rez, remz, resz = serror.seg_fr_rand_error(seg[:,:,z], lbl[:,:,z], true, true)
                    @time rez, remz, resz, rfz, rfmz, rfsz = segerror(seg[:,:,z], lbl[:,:,z])
                end
                #println("rand error: $(rez), rand f score: $(rfz)")
                rf[i] += rfz; rfm[i] += rfmz; rfs[i] += rfsz;
                re[i] += rez; rem[i] += remz; res[i] += resz;
            end
            rf[i] /= sz; rfm[i] /= sz; rfs[i] /= sz;
            re[i] /= sz; rem[i] /= sz; res[i] /= sz;
        end
        println("rand error: $(re[i]), rand f score: $(rf[i])")
    end
    # print the scores
    println("rand f score: $rf")
    println("rand error: $re")
    return thds, segs, rf, rfm, rfs, re, rem, res
end

"""
compute the foreground restricted rand error

Inputs:
affs: affinity map
lbl: ground truth labeling
thds: a list of thresholds to segment the affinity map using connected component

Outputs:
a list of foreground restricted rand errors corresponds to the thresholds
"""
function affs_fr_rand_errors(affs::Taffs, lbl::Tseg, thds::Array=Array(linspace(1,0,11)))
    @assert size(affs)[1:3] == size(lbl)
    # sizes
    sx,sy,sz = size(lbl)

    # number of non-boundary voxels of label
    nnb = Float32( countnz(lbl) )
    # number of foreground pixel pairs
    Np = nnb*(nnb-1)/2

    # initialize the true positive, false positive, true negative, false negative
    tps = zeros(Float32, size(thds))
    fps = zeros(Float32, size(thds))
    tns = zeros(Float32, size(thds))
    fns = zeros(Float32, size(thds))

    # initialize domains for affinity map
    adms = Tdomains( lbl )

    # get the sorted affinity edge list
    print("get the sorted affinity edge list......")
    elst = affs2edgelist( affs )
    println("done :)")

    # merge the voxels by traversing the sorted affinity edges
    lbl_flat = lbl[:]
    for (a, vid1, vid2) in elst
        # find the rood/segment id and the corresponding domain label sizes
        rid1, dlsz1 = find!(adms, vid1)
        rid2, dlsz2 = find!(adms, vid2)
        if rid1 == rid2
            # already in a same segment, no need to merge
            continue
        end

        # get foreground restricted voxel pair number
        n_same_pair, n_diff_pair = get_pair_num(dlsz1, dlsz2)
        #println("n_same_pair: $(n_same_pair), \t n_diff_pair: $(n_diff_pair)")
        for i in 1:length(thds)
            if a > thds[i]
                # positive, will merge
                fps[i] += n_diff_pair
                tps[i] += n_same_pair
            else
                # negative, will split
                fns[i] += n_same_pair
                tns[i] += n_diff_pair
            end
        end

        # union the voxel pair
        union!(adms, rid1, dlsz1, rid2, dlsz2)
    end
    println("tps: $tps")
    println("fps: $fps")
    println("tns: $tns")
    println("fns: $fns")
    println("non-boundary voxel number: $nnb")
    println("non-boundary voxel pair number: $(Np)")
    @assert tps + fps + tns + fns == ones(Float32,size(thds))*Np
    # normalize the error
    mes = fps / Np
    ses = fns / Np
    # compute rand error
    res = mes + ses
    return res, mes, ses
end


function segerror(seg::Array, lbl::Array, is_fr=true, is_selfpair=false)
    om = Dict{Tuple{UInt32,UInt32},UInt32}()
    si = Dict{UInt32,UInt32}()
    li = Dict{UInt32,UInt32}()

    # number of voxels
    N = 0
    for iter in eachindex(lbl)
        lid = lbl[iter]
        # foreground restriction
        if is_fr && lid == 0
            continue
        end
        N += 1
        if haskey(li, lid)
            li[lid] += 1
        else
            li[lid] = 1
        end

        sid = seg[iter]
        if haskey(si, sid)
            si[sid] += 1
        else
            si[sid] = 1
        end

        if haskey(om, (sid,lid))
            om[(sid,lid)] += 1
        else
            om[(sid,lid)] = 1
        end
    end

    # compute the errors
    if is_selfpair
        ssum  = sum(pmap(x->x*x/2, values(si)))
        lsum  = sum(pmap(x->x*x/2, values(li)))
        omsum = sum(pmap(x->x*x/2, values(om)))

    else
        ssum  = sum(pmap(x->x*(x-1)/2, values(si)))
        lsum  = sum(pmap(x->x*(x-1)/2, values(li)))
        omsum = sum(pmap(x->x*(x-1)/2, values(om)))
    end

    # rand error
    rem = (ssum -omsum) / (N*(N-1)/2)
    res = (lsum -omsum) / (N*(N-1)/2)
    re = rem + res

    # rand f score
    rfm = omsum / ssum
    rfs = omsum / lsum
    rf = 2*omsum / (ssum + lsum)
    return re, rem, res, rf, rfm, rfs
end


"""
compute foreground restricted segment error by comparing segmentation with ground truth
it is recommanded to reassign the segment id to 1,2,3,...,N using function of segid1N!

`Note that this function does not pass the test yet!!!`
"""
function segerror_V1(seg_in, lbl_in)
    seg = copy(seg_in)
    lbl = copy(lbl_in)

    @assert size(seg)==size(lbl)
    if ndims(seg) == 2
        sx,sy = size(seg)
        sz = 1
        seg = reshape(seg, (sx,sy,sz))
    else
        sx,sy,sz = size(seg)
    end

    # reassigns the segment ID to 1-N to avoid huge sparse matrix
    Ns = segid1N!(seg)
    Nl = segid1N!(lbl)
    #Ns = maximum(seg)
    #Nl = maximum(lbl)

    # initialize a sparse overlap matrix
    om = spzeros(Float32, Ns+1, Nl+1)

    # create overlap matrix
    for z in 1:sz
        for y in 1:sy
            for x in 1:sx
                # foreground restriction
                if lbl[x,y,z]>0
                    # the index 1 represent the 0 label
                    om[seg[x,y,z]+1, lbl[x,y,z]+1] += 1
                end
            end
        end
    end

    # number of non-zero voxels
    N = Float32( countnz(lbl) )

    # compute si and tj using cumulative sum
    si = cumsum(om, 1)
    tj = cumsum(om, 2)

    # building blocks of error metrics
    som = sum( om.*(om-1)/2 )
    ssi = sum(si.*(si-1)/2)
    stj = sum(tj.*(tj-1)/2)

    # rand error of mergers and splitters
    rem = (ssi - som) / (N*(N-1)/2)
    res = (stj - som) / (N*(N-1)/2)
    re = rem + res

    # building blocks of error metrics
    som = sum( om.^2 )
    ssi = sum(si.^2)
    stj = sum(tj.^2)

    # rand f score of mergers and splitters
    rfm = som/ssi
    rfs = som/stj
    # harmonic mean
    rf = 2*som / (ssi + stj)
    return re, rem, res, rf, rfm, rfs
end

"""
patch-based segmentation error
`Inputs`
`seg`: segmentation, indexed array
`lbl`: ground true label, indexed array
`ptsz`: patch size

`Outputs`
`re`: rand error
`rem`: rand error of mergers
`res`: rand error of splitters
`rf`: rand f score
`rfm`: rand f score of mergers
`rfs`: rand f score of splitters
"""
function patch_segerror(seg_in, lbl_in, ptsz=[100,100,1], step=[100,100,1])
    @assert size(seg_in)==size(lbl_in)
    # @assert Tuple(ptsz) < size(seg)

    if ndims(seg_in)==2
        sx,sy = size(seg_in)
        sz = 1
        seg = reshape(seg_in, (sx,sy,sz))
        lbl = reshape(lbl_in, (sx,sy,sz))
    else
        sx,sy,sz = size(seg_in)
        seg = seg_in
        lbl = lbl_in
    end

    # number of patches
    Np = 0
    # the patch-based errors
    pre = 0; prem = 0; pres = 0;
    prf = 0; prfm = 0; prfs = 0;
    # get patches and measure
    for z1 in 1:step[3]:sz
        for y1 in 1:step[2]:sy
            for x1 in 1:step[1]:sx
                # get patch
                z2 = z1+ptsz[3]-1
                if z2 > sz
                    z2 = sz
                    z1 = z2 - ptsz[3] + 1
                end

                y2 = y1+ptsz[2]-1
                if y2 > sy
                    y2 = sy
                    y1 = y2 - ptsz[2] + 1
                end

                x2 = x1+ptsz[1]-1
                if x2 > sx
                    x2 = sx
                    x1 = x2 - ptsz[1] + 1
                end
                # patch of seg and lbl
                pseg = seg[x1:x2,y1:y2,z1:z2]
                plbl = lbl[x1:x2,y1:y2,z1:z2]
                # compute the error
                re, rem, res, rf, rfm, rfs = segerror(pseg, plbl)
                # @pyimport segerror.error as serror
                # rf, rfm, rfs = serror.seg_fr_rand_f_score(seg, lbl, true, true)
                # re, rem, res = serror.seg_fr_rand_error(seg, lbl, true, true)
                # increas the errors
                pre += re; prem += rem; pres += res;
                prf += rf; prfm += rfm; prfs += rfs;
                # increase the number of patches
                Np += 1
            end
        end
    end
    # normalize across all the patches
    pre /= Np; prem /= Np; pres /= Np;
    prf /= Np; prfm /= Np; prfs /= Np;
    return pre, prem, pres, prf, prfm, prfs
end
