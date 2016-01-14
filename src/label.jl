
typealias Tlabel Array{UInt32,3}


# label all the singletones as boundary
function markbdr!( seg::Tlabel )

    # a flag array indicating whether it is segment
    flg = falses(seg)
    # size
    X,Y,Z = size(seg)

    # traverse the segmentation
    for z in 1:Z
        for y in 1:Y
            for x in 1:X
                if flg[x,y,z]
                    continue
                end
                if x>1 && seg[x,y,z]==seg[x-1,y,z]
                    flg[x,  y,z] = true
                    flg[x-1,y,z] = true
                    continue
                end
                if x<X && seg[x,y,z]==seg[x+1,y,z]
                    flg[x,  y,z] = true
                    flg[x+1,y,z] = true
                    continue
                end
                if y>1 && seg[x,y,z]==seg[x,y-1,z]
                    flg[x,y,z] = true
                    flg[x,y-1,z] = true
                    continue
                end
                if y<Y && seg[x,y,z]==seg[x,y+1,z]
                    flg[x,y,  z] = true
                    flg[x,y+1,z] = true
                end
                if z>1 && seg[x,y,z]==seg[x,y,z-1]
                    flg[x,y,z  ] = true
                    flg[x,y,z-1] = true
                    continue
                end
                if z<Z && seg[x,y,z]==seg[x,y,z+1]
                    flg[x,y,z  ] = true
                    flg[x,y,z+1] = true
                    continue
                end
                # it is a singletone
                seg[x,y,z] = 0
            end
        end
    end
end


# relabel the segment according to connectivity
# where N is the total number of segments
# Note that this is different from relabel1N in segerror package, which relabeles in 2D and labeled the segment ID to 1-N, where N is the total number of segments.
function relabel_seg( lbl::Tlabel, dim=3 )
    @assert dim==2 || dim==3
    N = length(lbl)
    X,Y,Z = size(lbl)

    # initialize the disjoint sets
    djs = Tdjsets(N)

    # x affinity
    for x in 2:X
        for y in 1:Y
            for z in 1:Z
                if lbl[x,y,z]>0 && lbl[x,y,z]==lbl[x-1,y,z]
                    # should union these two sets
                    vid1 = x   + (y-1)*X + (z-1)*X*Y
                    vid2 = x-1 + (y-1)*X + (z-1)*X*Y
                    # find tree root
                    r1 = find!(djs, vid1)
                    r2 = find!(djs, vid2)
                    # union two sets
                    union!(djs, r1, r2)
                end
            end
        end
    end

    # y affinity
    for x in 1:X
        for y in 2:Y
            for z in 1:Z
                if lbl[x,y,z]>0 && lbl[x,y,z]==lbl[x,y-1,z]
                    vid1 = x + (y-1)*X + (z-1)*X*Y
                    vid2 = x + (y-2)*X + (z-1)*X*Y
                    r1 = find!(djs, vid1)
                    r2 = find!(djs, vid2)
                    union!(djs, r1, r2)
                end
            end
        end
    end

    # z affinity
    if dim==3
        for x in 1:X
            for y in 1:Y
                for z in 2:Z
                    if lbl[x,y,z]>0 && lbl[x,y,z] == lbl[x,y,z-1]
                        vid1 = x + (y-1)*X + (z-1)*X*Y
                        vid2 = x + (y-1)*X + (z-2)*X*Y
                        r1 = find!(djs, vid1)
                        r2 = find!(djs, vid2)
                        union!(djs, r1, r2)
                    end
                end
            end
        end
    end

    # get current segmentation
    setallroot!( djs )
    seg = deepcopy(djs.sets)
    seg = reshape(seg, size(lbl))
    # mark all the singletons to 0 as boundary
    markbdr!(seg)
    return seg
end


# reassign segment ID as 1-N
function reassign_segid1N!( lbl::Tlabel )
    # dictionary of ids
    did = Dict()
    did[0] = 0

    # number of segments
    N = 0
    # get the segment ID map
    for v in lbl
        if v > 0
            if !haskey(did, v)
                # a new segment ID
                N += 1
                did[v] = N
            end
        end
    end

    # assign the map to a new segment
    for x in 1:size(lbl, 1)
        for y in 1:size(lbl, 2)
            for z in 1:size(lbl, 3)
                lbl[x,y,z] = did[ lbl[x,y,z] ]
            end
        end
    end
    return lbl
end
