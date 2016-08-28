include("types.jl")
include("evaluate.jl")
include("errorcurve.jl")

export merge, merge!, segment, segment!, sgm2error, sgm2ec
#
# """
# equality
# """
# function Base.is(sgm1::Tsgm, sgm2::Tsgm)
#   sgm1.seg==sgm2.seg && sgm1.dend==sgm2.dend && sgm1.dendValues==sgm2.dendValues
# end

"""
merge supervoxels with high affinity
"""
function Base.merge!(sgm::Tsgm, thd::AbstractFloat)
    # the dict of parent and child
    # key->child, value->parent
    pd = Dict{UInt32,UInt32}()
    idxlst = Vector{Int64}()
    for idx in 1:length(sgm.dendValues)
        if sgm.dendValues[idx] > thd
            # the first one is child, the second one is parent
            pd[sgm.dend[idx,1]] = sgm.dend[idx,2]
        end
    end

    # find the root id
    for (c,p) in pd
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
    for i in eachindex(sgm.seg)
        sgm.seg[i] = get(pd, sgm.seg[i], sgm.seg[i])
    end

    # update the dendrogram
    sgm.dendValues = sgm.dendValues[idxlst]
    sgm.dend = sgm.dend[:, idxlst]

    return sgm
end

function Base.merge(sgm::Tsgm, thd::AbstractFloat)
  sgm2 = deepcopy(sgm)
  return merge!(sgm2, thd)
end

"""
segment the sgm, only return segmentation
"""
function segment(sgm::Tsgm, thd::AbstractFloat)
  sgm2 = merge(sgm, thd)
  return sgm2.seg
end

function segment!(sgm::Tsgm, thd::AbstractFloat)
  sgm = merge!(sgm, thd)
  return sgm.seg
end

"""
compute segmentation error using one threshold
"""
function sgm2error(sgm::Tsgm, lbl::Tseg, thd::AbstractFloat)
    @assert thd<=1 && thd>=0
    seg = segment(sgm, thd)
    return evaluate(seg, lbl)
end

"""
compute error curve based on a segmentation (including dendrogram) and groundtruth label
"""
function sgm2ec(sgm::Tsgm, lbl::Tseg, thds = 0:0.1:1)
    ec = Tec()
    for thd in thds
        e = sgm2error(sgm, lbl, thd)
        e[:thd] = thd
        append!(ec, e)
    end
    ec
end
