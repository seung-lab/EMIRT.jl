export affs_fr_rand_error, seg_fr_rand_error, seg_fr_rand_f_score, affs_error_curve, affs_fr_rand_errors

using PyCall
@pyimport segerror.error as serror

include("affinity.jl")
include("label.jl")
include("domains.jl")

# measure 2D rand error of affinity
function affs_fr_rand_error(affs::Taffs, lbl::Tseg, dim=3, thd=0.5)
    @assert dim==3 || dim==2
    seg = aff2seg(affs, dim, thd)
    return seg_fr_rand_error( seg, lbl, dim )
end

# rand error of segmentation
function seg_fr_rand_error( seg::Tseg, lbl::Tseg, dim=3 )
    @assert dim==2 || dim==3
    if dim==2
        # relabel in 2D
        lbl = relabel_seg(lbl, 2)
    end

    # also get merge and split score
    re, rem, res = serror.seg_fr_rand_error(seg, lbl, true, true)
    return re, rem, res
end

# rand F score of segmentation
function seg_fr_rand_f_score( seg::Tseg, lbl::Tseg, dim=3 )
    @assert dim==3 || dim==2
    if dim == 2
        # relabel in 2D
        lbl = relabel_seg( lbl, 2 )
    end

    #
    rf, rfm, rfs = serror.seg_fr_rand_f_score(seg, lbl, true, true)

    return rf, rfm, rfs
end


# rand error curve
function affs_error_curve(affs::Taffs, lbl::Tseg, dim=3, step=0.1, seg_method="connected_component", redist = "uniform")
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

    segs = zeros(UInt32, (length(thds), size(lbl,1), size(lbl,2), size(lbl,3)))

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

        seg = Array{UInt64,3}(seg)
        segs[i,:,:,:]  = seg
        # rand f score and rand error
        if dim==3
            rf[i], rfm[i], rfs[i] = serror.seg_fr_rand_f_score(seg, lbl, true, true)
            re[i], rem[i], res[i] = serror.seg_fr_rand_error(seg, lbl, true, true)
        else
            # 2D rand error and rand f score
            for z in 1:size(seg,3)
                rfz, rfmz, rfsz = serror.seg_fr_rand_f_score(seg, lbl, true, true)
                rez, remz, resz = serror.seg_fr_rand_error(seg, lbl, true, true)
                rf[i] += rfz; rfm[i] += rfmz; rfs[i] += rfsz;
                re[i] += rez; rem[i] += remz; res[i] += resz;
            end
            rf[i] /= size(seg,3); rfm[i] /= size(seg,3); rfs[i] /= size(seg,3);
            re[i] /= size(seg,3); rem[i] /= size(seg,3); res[i] /= size(seg,3);
        end
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
    # thresholds index
    ti = 1
    lbl_flat = lbl[:]
    for (a, vid1, vid2) in elst
        # compute the number of pairs
        rid1, dlsz1 = find!(adms, vid1)
        rid2, dlsz2 = find!(adms, vid2)
        if rid1 == rid2
            # already in a same segment, no need to merge
            continue
        end

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
    println("non-boundary voxel pair number: $(nnb*(nnb-1)/2)")
    @assert tps + fps + tns + fns == ones(Float32,size(thds))* (nnb*(nnb-1)/2)
    # normalize the error
    mes = fps / (nnb*(nnb-1))
    ses = fns / (nnb*(nnb-1))
    # compute rand error
    res = mes + ses
    return res, mes, ses
end


"""
compute foreground restricted segment error by comparing segmentation with ground truth
"""
function segerror!(seg, lbl)
    @assert size(seg)==size(lbl)

    # reassigns the segment ID to 1-N to avoid huge sparse matrix
    Ns = reassign_segid1N!(seg)
    Nl = reassign_segid1N!(lbl)

    # initialize a sparse overlap matrix
    om = spzeros(Float32, Ns+1, Nl+1)

    # create overlap matrix
    for z in 1:size(seg,3)
        for y in 1:size(seg,2)
            for x in 1:size(seg,1)
                # foreground restriction
                if lbl[z,y,x]>0
                    # the index 1 represent the 0 label
                    om[seg[z,y,x]+1, lbl[z,y,x]+1] += 1
                end
            end
        end
    end

    # number of non-zero voxels
    N = Float32( countnz(lbl) )

    # normalize the overlap matrix
    om = om / N

    # compute si and tj using cumulative sum
    si = cumsum(om, 1)
    tj = cumsum(om, 2)

    # building blocks of error metrics
    som = sum( om.^2 )
    ssi = sum(si.^2)
    stj = sum(tj.^2)

    # rand error of mergers and splitters
    rem = ssi - som
    res = stj - som
    re = rem + res

    # rand f score of mergers and splitters
    rfsm = som/ssi
    rfss = som/stj
    # harmonic mean
    rfs = 2*som / (ssi + stj)

    return re, rem, res, rfs, rfsm, rfss
end
