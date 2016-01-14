

type Tdjsets
    sets::Array{UInt32}
    setsz::Array{UInt32}
    numsets::UInt32
    size::UInt32
end

# constructor
function Tdjsets(N)
    sets = Array(1:N)
    setsz = ones(sets)
    numsets = N
    size = N
    Tdjsets(sets, setsz, numsets, size)
end

function find!( djsets::Tdjsets, vid )
    # find root id or domain id
    rid = vid
    while rid != djsets.sets[rid]
        rid = djsets.sets[rid]
    end

    # patch compression
    # current id
    cid = vid
    while rid != cid
        # parent id
        pid = djsets.sets[cid]
        djsets.sets[cid] = rid
        cid = pid
    end
    return rid
end

# import Base.union! for extention
import Base.union!
function union!( djsets::Tdjsets, sid1, sid2 )
    if sid1 == sid2
        # already in the same domain
        return sid1
    end

    # reduce set number
    djsets.numsets -= 1
    if djsets.setsz[ sid1 ] >= djsets.setsz[ sid2 ]
        # assign sid1 as the parent of sid2
        djsets.sets[ sid2 ] = sid1
        djsets.setsz[ sid1 ] += djsets.setsz[ sid2 ]
        return sid1
    else
        djsets.sets[ sid1 ] = sid2
        djsets.setsz[ sid2 ] += djsets.setsz[ sid1 ]
        return sid2
    end
end

# label all the singletones as boundary
function markbdr!( seg::Array{Integer, 3} )

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

function setallroot!( djsets::Tdjsets )
    # label all the voxels to root id
    for vid in 1:djsets.size
        # with patch compress
        # all the voxels will be labeled as root id
        rid = find!(djsets, vid)
    end
    return djsets.sets
end


type Tdomainlabelsizes
    sizes::Dict
end

function Tdomainlabelsizes( lid=nothing, lsz=1 )
    sizes = Dict()
    if isdefined(lid)
        sizes[lid] = lsz
    end
    return Tdomainlabelsizes(sizes)
end


# union dm2 to dm1, only dm1 was changed
function union!( dm1::Tdomainlabelsizes, dm2::Tdomainlabelsizes )
    for (lid2, sz2) in dm2
        if haskey(dm1, lid2)
            # have common segment id, merge together
            dm1[lid2] += sz2
        else
            # do not have common id, create new one
            dm1[lid2] = sz2
        end
    end
end

function clear!( dlszes::Tdomainlabelsizes )
    dlszes = Dict()
end

function get_merge_split_errors(dm1::Tdomainlabelsizes, dm2::Tdomainlabelsizes)
    # merging and splitting error
    me = 0
    se = 0
    for (lid1, sz1) in dm1
        for (lid2, sz2) in dm2
            # ignore the boudaries
            if lid1>0 && lid2>0
                if lid1==lid2
                    # they should be merged together
                    # this is a split error
                    se += sz1 * sz2
                else
                    # they should be splitted
                    # this is a merging error
                    me += sz1 * sz2
                end
            end
        end
    end
end

type Tdomains
    # domain label sizes
    dlszes::Array{Tdomainlabelsizes, 1}
    # disjoint sets
    djsets::Tdjsets
end

function Tdomains(lbl::Array)
    @assert ndims(lbl)==2 || ndims(lbl)==3

    # initialize the disjoint sets
    djsets = Tdisjointsets( length(lbl) )

    # initialize the dms as an empty vector/list/1D array
    dlszes = []
    lbl1d = reshape(lbl, length(lbl) )
    for vid in 1:legth(lbl)
        # manual labeled segment id
        lid = lbl1d[vid]
        push!(dlszes, Tdomainlabelsizes(lid) )
    end
    return Tdomains(dlszes, djsets)
end

# find the corresponding domain of a voxel
function find!(dm::Tdomains, vid)
    rid = find!(dm.djsets, vid)
    dm = dm.dlszes[ rid ]
    return rid, dm
end

# union the two domains of two voxel ids
function union!(dm::Tdomains, vid1, vid2)
    # domain id and domain
    rid1, dm1 = find!(vid1)
    rid2, dm2 = find!(vid2)

    # alread in one domain
    if rid1 == rid2
        return 0,0
    end

    # compute error
    me, se = get_merge_split_errors( dm1, dm2 )

    # attach the small one to the big one
    if dm.djsets.setsz[ rid1 ] < dm.djsets.setsz[ rid2 ]
        rid1, rid2 = rid2, rid1
        dm1, dm2 = dm2, dm1
    end

    # merge these two domains
    union!(dm1, dm2)
    dm.dlszes[rid1] = dm1
    clear!( dm.dlszes[rid2] )

    # join the sets
    union!( dm.djsets, rid1, rid2 )
    return me, se
end
