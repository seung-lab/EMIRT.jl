export affs_fr_rand_error, seg_fr_rand_error, seg_fr_rand_f_score, affs_error_curve

using PyCall
@pyimport segerror.error as serror

include("affinity.jl")

# measure 2D rand error of affinity
function affs_fr_rand_error(affs::Taffs, lbl::Tlabel, dim=3, thd=0.5)
    @assert dim==3 || dim==2
    seg = aff2seg(affs, dim, thd)
    return seg_fr_rand_error( seg, lbl, dim )
end

# rand error of segmentation
function seg_fr_rand_error( seg::Tlabel, lbl::Tlabel, dim=3 )
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
function seg_fr_rand_f_score( seg::Tlabel, lbl::Tlabel, dim=3 )
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
function affs_error_curve(affs::Taffs, lbl::Tlabel, dim=3, step=0.1, seg_method="connected_component", redist = "uniform")
    # transform to uniform distribution
    if redist == "uniform"
        for c in 1:3
            affs[:,:,:,c] = uniform_transformation(affs[:,:,:,c]);
        end
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
    rf = zeros(thds)
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
                seg = wsseg2d(affs, 0,  0.95, [], 0, thds[i])
            else
                seg = wsseg(affs, 0, 0.9, [], 0, thds[i])
            end
        else
            seg = aff2seg( affs, dim, thds[i] )
        end

        seg = Array{UInt64,3}(seg)
        segs[i,:,:,:]  = seg
        # rand f score and rand error
        rf[i], rfm[i], rfs[i] = serror.seg_fr_rand_f_score(seg, lbl, true, true)
        re[i], rem[i], res[i] = serror.seg_fr_rand_error(seg, lbl, true, true)
    end
    # print the scores
    println("rand f score: $rf")
    println("rand error: $re")
    return thds, segs, rf, rfm, rfs, re, rem, res
end
