include("types.jl")

using HDF5

"""
read segmentation with maximum spanning tree
"""
function readsgm(fname::AbstractString)
    f = h5open(fname)
    if "seg" in names(f)
        seg = read(f["seg"])
    else
        @assert "main" in names(f)
        seg = read(f["main"])
    end
    dend = read(f["dend"])
    dendValues = read(f["dendValues"])
    Tsgm(seg, dend, dendValues)
end

"""
save seg-mst
"""
function savesgm(fname::AbstractString, sgm::Tsgm)
    h5write(fname, "seg", sgm.seg)
    h5write(fname, "dend", sgm.dend)
    h5write(fname, "dendValues", sgm.dendValues)
end
function savesgm(fname::AbstractString, seg::Tseg, dend::Tdend, dendValues::TdendValues)
    savesgm( fname, Tsgm(seg,dend,dendValues) )
end

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
compute error curve
"""
