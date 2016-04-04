export affs_fr_rand_error, seg_fr_rand_error, seg_fr_rand_f_score, affs_error_curve, affs_fr_rand_errors, pysegerror, segerror, patch_segerror

include("affinity.jl")
include("label.jl")
include("domains.jl")

# use a log version which is faster and more accurate
import Base.Math.JuliaLibm.log

import PyCall.@pyimport

# rand error curve
function affs_error_curve(affs::Taffs, lbl::Tseg, dim=3, step=0.1, seg_method="watershed", is_patch=false, is_remap=true)
    @show size(affs)
    @show size(lbl)
    @assert size(affs)[1:3] == size(lbl)
    sx,sy,sz = size(lbl)
    # transform to uniform distribution
    if is_remap
        affs = affs2uniform(affs);
    end
    # initialize the curve
    ret = Dict{ASCIIString, Vector{Float32}}()

    # thresholds
    if seg_method=="connected_component"
        thds = Vector{Float32}( Array( 0 : step : 1 ) )
    else
        thds = Vector{Float32}( Array( 0 : step : 0.9) )
    end
    # rand index
    ret["ri"] = zeros(thds)
    ret["rim"] = zeros(thds)
    ret["ris"] = zeros(thds)
    # rand f score
    ret["rf"] =  zeros(thds)
    ret["rfm"] = zeros(thds)
    ret["rfs"] = zeros(thds)
    # information theory metrics
    ret["VIFS"] = zeros(thds)
    ret["VIFSm"] = zeros(thds)
    ret["VIFSs"] = zeros(thds)

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
        # wsdms, rt = watershed(affs, 0, 0.95, [], 0)
        wsdms, rt = watershed(affs, 0.3, 0.95, [(600,0.3)], 1000)
    end

    for i in eachindex(thds)

        if seg_method == "watershed"
            if dim==2
                # seg = wsseg(affs, 2, 0,  0.95, [], 0, thds[i])
                seg = wsseg(affs, 2, 0,  0.95, [(600,0.3)], 1000, thds[i])
            else
                seg = mergert(wsdms, rt, thds[i])
            end
        else
            seg = aff2seg( affs, dim, thds[i] )
        end

        segs[i,:,:,:]  = seg
        # rand f score and rand error
        if dim==3
            if is_patch
                @time ed = patch_segerror(seg, lbl)
            else
                @time ed = segerror(seg, lbl)
            end
            # get value
            for k in keys(ret)
                ret[k][i] = ed[k]
            end
        else
            # 2D rand error and rand f score
            for z in 1:sz
                if is_patch
                    @time edz = patch_segerror(seg[:,:,z], lbl[:,:,z])
                else
                    @time edz = segerror(seg[:,:,z], lbl[:,:,z])
                end
                # increase for each z
                for k in keys(ret)
                    ret[k][i] += edz[k]
                end
            end
            # get the average over Z
            for k in keys(ret)
                ret[k][i] /= sz
            end
        end
    end
    # print the scores
    ret["thds"] = thds
    @show ret
    return ret
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

"""
compute the segmentation metrics using python segerror package
https://github.com/seung-lab/segascorus
"""
function pysegerror(seg::Array, lbl::Array, is_fr=true, is_selfpair=true)
    PyCall.@pyimport segascorus.error as serror
    ret = Dict{ASCIIString, Float32}()
    re, rem, res = serror.seg_fr_rand_error(seg, lbl, true, true)
    ret["ri"] = 1-re
    ret["rf"], ret["rfm"], ret["rfs"] = serror.seg_fr_rand_f_score(seg, lbl, true, true)
    ret["VIFS"], ret["VIFSm"], ret["VIFSs"] = serror.seg_fr_variation_f_score(seg, lbl, true, true)
    return ret
end

function segerror(seg::Array, lbl::Array, is_fr=true, is_selfpair=true)
    ret = Dict{ASCIIString, Float32}()
    # overlap matrix reprisented by dict
    om = Dict{Tuple{UInt32,UInt32},Float32}()
    si = Dict{UInt32,Float32}()
    li = Dict{UInt32,Float32}()

    # number of voxels
    N = Float32(0)
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
        TP = sum(pmap(x->x*x/2, values(om)))
        # total number of voxel pair
        Np = N*N/2

        # information theory metrics
        HS = - sum( pmap(x->x/N*log(x/N), values(si)) )
        HT = - sum( pmap(x->x/N*log(x/N), values(li)) )
        HST = Float32(0)
        HTS = Float32(0)
        IST = Float32(0)
        # i = UInt32(0); j = UInt32(0); v = Float32(0);
        # HST = @parallel (-) for ((i, j),v) in om
        #     v/Np * log( v/li[j] )
        # end

        # HTS = @parallel (-) for ((i, j),v) in om
        #     v/Np * log( v/si[i] )
        # end

        # IST = @parallel (+) for ((i, j),v) in om
        #     v/Np * log( v*Np / ( si[i] * li[j] ) )
        # end

        for ((i::UInt32, j::UInt32),v::Float32) in om
            # segment id pair
            pij = v / N
            HTS -= pij * log( v / si[i] )
            HST -= pij * log( v / li[j] )
            IST += pij * log( v * N / (si[i] * li[j]) )
        end
        ret["VI"] = HS + HT - 2*IST
        ret["VIs"] = HST
        ret["VIm"] = HTS
        ret["VIS"] = - ret["VI"]
        ret["VIFSs"] = IST / HS
        ret["VIFSm"] = IST / HT
        ret["VIFS"] = 2*IST / (HT + HS)
    else
        ssum  = sum(pmap(x->x*(x-1)/2, values(si)))
        lsum  = sum(pmap(x->x*(x-1)/2, values(li)))
        TP = sum(pmap(x->x*(x-1)/2, values(om)))
        # total number of voxel pair
        Np = Float32( N*(N-1)/2 )
    end
    FP = ssum - TP
    FN = lsum - TP
    TN = Np - TP - FP - FN

    # rand error
    ret["res"] = FN / Np
    ret["rem"] = FP / Np
    ret["re"] = ret["rem"] + ret["res"]
    # rand index
    ret["ris"] = TN / Np
    ret["rim"] = TP / Np
    ret["ri"] = ret["rim"] + ret["ris"]

    # rand f score
    ret["rfs"] = TP / (TP + FN)
    ret["rfm"] = TP / (TP + FP)
    ret["rf"] = 2*TP / (2*TP + FP + FN)
    return ret
end

"""
patch-based segmentation error
`Inputs`
`seg`: segmentation, indexed array
`lbl`: ground true label, indexed array
`ptsz`: patch size

`Outputs`
`ri`: rand index
`rim`: rand index of mergers
`ris`: rand index of splitters
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

    # initialize the evaluate result dict
    ret = Dict{ASCIIString, Float32}()
    ret["ri"] = 0;   ret["ris"] = 0;   ret["rim"] = 0;
    ret["rf"] = 0;   ret["rfs"] = 0;   ret["rfm"] = 0;
    ret["VIFS"] = 0; ret["VIFSs"] = 0; ret["VIFSm"] = 0;

    # number of patches
    Np = 0
    # the patch-based errors
    pri = 0; prim = 0; pris = 0;
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
                ed = segerror(pseg, plbl)
                # increas the errors
                for k in keys(ret)
                    ret[k] += ed[k]
                end
                # increase the number of patches
                Np += 1
            end
        end
    end
    # normalize across all the patches
    for k in keys(ret)
        ret[k] /= Np
    end
    return ret
end
