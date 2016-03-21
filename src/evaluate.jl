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
        affs2uniform!(affs);
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
    for i in eachindex(thds)

        if seg_method == "watershed"
            if dim==2
                seg = wsseg(affs, 2, 0,  0.95, [], 0, thds[i])
            else
                seg = wsseg(affs, 3, 0, 0.9, [], 0, thds[i])
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

    # initialize the rand errors
    mes = zeros(Float32, size(thds))
    ses = ones(Float32, size(thds))* nnb*(nnb-1)
    res = zeros(Float32, size(thds))

    # initialize domains for affinity map
    adms = Tdomains( length(lbl) )

    # get the sorted affinity edge list
    print("get the sorted affinity edge list......")
    elst = affs2edgelist( affs )
    println("done :)")

    # merge the voxels by traversing the sorted affinity edges
    # thresholds index
    ti = 1
    lbl_flat = lbl[:]
    for (a, vid1, vid2) in elst
        # skip the boundaries
        if lbl_flat[vid1]==0 || lbl_flat[vid2]==0
            continue
        end
        print("$a, ")

        # correct or incorrect merge
        if lbl_flat[vid1] == lbl_flat[vid2]
            # shold merge
            for i in 1:length(thds)
                if a >= thds[i]
                   mes =
            se[] -= ses[]
        else
            # merge error
            me[]

        # union the voxel pair
        #print("union of two voxels: $(vid1), $(vid2) ...")
        union!(adms, vid1, vid2)
        #println("done :)")
    end
    return res, mes, ses
end
