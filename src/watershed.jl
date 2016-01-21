using Watershed

export wsseg2d, watershed, mergert!

function wsseg2d(affs, low=0.3, high=0.9, thresholds=[(256,0.3)], dust_size=100, thd_rt=0.5)
    seg = zeros(Array{UInt32,3}, size(affs(:,:,:,1)) )
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

function mergert!(tp::Tuple{Array{UInt32,3},Array{Any,1}}, thd=0.5)
    seg, rt = tp
    mergert!(seg, rt, thd)
end

function mergert!(seg, rt, thd=0.5)
    # get the ralative root dict
    rd = Dict()
    # initialized as children and parents
    for t in rt
        a, p, c = t
        rd[c] = (p, a)
    end

    # get the relative root id
    for t in rt
        # get affinity and segment IDs of parent and child
        a, p, c = t
        # since the rt is descending ordered
        if a < thd
            break
        end

        # find the real root
        path = []
        while a >= thd
            p = rd[c][1]
            if p == c
                # reach a root
                break
            end
            # print("a: $a, c: $c, p: $p ;")

            # record path for path compression
            push!(path, p)
            # reset the child
            c = p
            if haskey(rd, p)
                a = rd[p][2]
            else
                break
            end
        end
        # path compression
        for n in path
            rd[n] = (p, a)
        end
    end

    # set the segment id as relative root id
    for v in seg
        if haskey(rd, v)
            v = rd[v][1]
        end
    end
    return seg
end
