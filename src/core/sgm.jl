include("types.jl")

export segment, sgm2ec

"""
get the segment with a threshold
"""
function segment(sgm::Tsgm, thd::AbstractFloat)
    # the dict of parent and child
    # key->child, value->parent
    pd = Dict{UInt32,UInt32}
    for idx in 1:length(sgm.dendValues)
        if sgm.dendValues[idx] > thd
            # the first one is child, the second one is parent
            pd[sgm.dend[idx,1]] = pd[sgm.dend[idx,2]]
        end
    end

    # find the root id
    for c,p in pd
        # list of child node, for path compression
        clst = [c]
        # find the root
        while haskey(pd, p)
            push!(clst, p)
            p = pd[p]
        end
        # now p is the root id
        # path compression
        for c in clst
            pd[c] = p
        end
    end

    # set each segment id as root id
    sharedseg = SharedArray(sgm.seg)
    @parallel for i in eachindex(sharedseg)
        sharedseg[i] = get(pd, sharedseg[i], sharedseg[i])
    end
    return sharedseg
end

"""
compute segmentation error using one threshold
"""
function sgm2error(sgm::Tsgm, lbl, thd::AbstractFloat)
    @assert thd<=1 && thd>=0
    seg = segment(sgm, thd)
    return segerror(seg, thd)
end

"""
compute error curve based on a segmentation (including dendrogram) and groundtruth label
"""
function sgm2ec(sgm::Tsgm, lbl::Tseg, thds = 0:0.1:1)

end
