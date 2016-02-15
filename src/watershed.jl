using Watershed

export wsseg2d, watershed, mergert!, mergert

function wsseg2d(affs, low=0.3, high=0.9, thresholds=[(256,0.3)], dust_size=100, thd_rt=0.5)
    seg = zeros(UInt32, size(affs)[1:3] )
    for z in 1:size(affs,3)
        seg[:,:,z], rt = watershed(affs[:,:,z,:], low, high, thresholds, dust_size)
        mergert!(seg[:,:,z], rt, thd_rt)
    end
    return seg
end

function watershed(affs, low=0.3, high=0.9, thresholds=[(256, 0.3)], dust_size=100)
    sag = steepestascent(affs, low, high)
    divideplateaus!(sag)
    (seg, counts, counts0) = findbasins(sag)
    rg = regiongraph(affs, seg, length(counts))
    new_rg = mergeregions(seg, rg, counts, thresholds, dust_size)
    rt = mst(new_rg, length(counts))
    return (seg, rt)
end

function mergert(seg, rt, thd=0.5)
    # the returned segmentation
    ret = deepcopy(seg)
    mergert!(ret, rt, thd)
    return ret
end

function mergert!(seg, rt, thd=0.5)
    # get the ralative parent dict
    pd = Dict()
    # initialized as children and parents
    for t in rt
        a, c, p = t
        @assert p>0 && c>0
        pd[c] = (p, a)
    end

    # get the relative root id
    # dictionary of root id
    rd = Dict()
    for t in rt
        # get affinity and segment IDs of parent and child
        a, c, p = t

        # find the real root
        path = []
        while a >= thd && p!=c
            # record path for path compression
            push!(path, c)
            # reset the child as parent
            c = p
            # next pair of child and parent
            if haskey(pd, p)
                a = pd[p][2]
            else
                break
            end
        end
        # path compression
        for n in path
            rd[n] = (p, a)
        end
    end

    #println("root dict: $rd")
    # set the segment id as relative root id
    for i in eachindex(seg)
        v = seg[i]
        if haskey(rd, v)
            root = rd[v][1]
            println("root: $(UInt64(root))")
            seg[i] = root
        end
    end
end
