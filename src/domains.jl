include("types.jl")

export Tdjsets, find!, union!, setallroot!, Tdomains, get_merge_split_errors

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

    # path compression
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
    # find root id
    rid1 = find!(djsets, sid1)
    rid2 = find!(djsets, sid2)

    if rid1 == rid2
        # already in the same domain
        return rid1
    end

    # reduce set number
    djsets.numsets -= 1
    if djsets.setsz[ rid1 ] >= djsets.setsz[ rid2 ]
        # assign sid1 as the parent of sid2
        djsets.sets[ rid2 ] = rid1
        djsets.setsz[ rid1 ] += djsets.setsz[ rid2 ]
        return rid1
    else
        djsets.sets[ rid1 ] = rid2
        djsets.setsz[ rid2 ] += djsets.setsz[ rid1 ]
        return rid2
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

typealias Tdmls Dict

# union dm2 to dm1, only dm1 was changed
function union!( dmls1::Tdmls, dmls2::Tdmls )
    for (lid2, sz2) in dmls2
        if haskey(dmls1, lid2)
            # have common segment id, merge together
            dmls1[lid2] += sz2
        else
            # do not have common id, create new one
            dmls1[lid2] = sz2
        end
    end
    # clear the dmls2
    dmls2 = Dict()
end

typealias Tdlszes Array{Tdmls,1}

function get_merge_split_errors(dlszes1::Tdlszes, dlszes2::Tdlszes)
    # merging and splitting error
    me = 0
    se = 0
    for dlsz1 in dlszes1
        for dlsz2 in dlszes2
            for (lid1, sz1) in dlsz1
                for (lid2, sz2) in dlsz2
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
    end
    return me, se
end

type Tdomains
    # domain label sizes
    dlszes::Tdlszes
    # disjoint sets
    djsets::Tdjsets
end

function Tdomains(N::Number)
    # initialize the disjoint sets
    djsets = Tdjsets( N )

    # initialize the dms as an empty vector/list/1D array
    dlszes = []
    for vid in 1:N
        # initial manual labeled segment id
        push!(dlszes, Tdmls(vid=>1) )
    end
    return Tdomains(dlszes, djsets)
end

# find the corresponding domain of a voxel
function find!(dms::Tdomains, vid)
    rid = find!(dms.djsets, vid)
    dmlsz = dms.dlszes[ rid ]
    return rid, dmlsz
end

# union the two domains of two voxel ids
function union!(dms::Tdomains, vid1, vid2)
    # domain id and domain
    rid1, dmsz1 = find!(dms, vid1)
    rid2, dmsz2 = find!(dms, vid2)

    # alread in one domain
    if rid1 == rid2
        return
    end

    # attach the small one to the big one to make the tree as flat as possible
    if dms.djsets.setsz[ rid1 ] < dms.djsets.setsz[ rid2 ]
        # merge these two domains
        union!(dms.dlszes[rid2], dms.dlszes[rid1])
        # join the sets
        union!( dms.djsets, rid1, rid2 )
    else
        # merge these two domain label sizes
        union!(dms.dlszes[rid1], dms.dlszes[rid2])
        # join the sets
        union!( dms.djsets, rid1, rid2 )
    end

end
