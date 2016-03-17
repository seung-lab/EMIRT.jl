include( "domains.jl" )
include("label.jl")

export aff2seg, exchangeaffsxz!, arr2uniform, affs2uniform!, gaffs2saffs

typealias Taffs Array{Float32,4}

"""
transform google affinity to seung lab affinity
"""
function gaffs2saffs( gaffs )
    @assert ndims(gaffs)==3
    sx,sy,sz = size(gaffs)
    saffs = reshape(gaffs, (sx,sy,Int64(sz/3),Int64(3)));
    #saffs = permutedims(saffs, [2,1,3,4]);

    # transform the x y and z channel
    #saffs[:,:,2:end, 1] = gaffs[:,:,1:end-1, 1]
    #saffs[:,:,2:end, 2] = gaffs[:,:,1:end-1, 2]
    #saffs[:,:,2:end, 3] = gaffs[:,:,1:end-1, 3]
    #saffs[:,:,1,1] = 0
    #saffs[:,:,1,2] = 0
    #saffs[:,:,1,3] = 0

    saffs[:,:,2:end, :] = saffs[:,:,1:end-1, :]
    saffs[:,:,1,:] = 0
    return saffs
end

# exchang X and Z channel of affinity
function exchangeaffsxz!(affs::Taffs)
    println("exchange x and z of affinity map")
    taffx = deepcopy(affs[:,:,:,1])
    affs[:,:,:,1] = deepcopy(affs[:,:,:,3])
    affs[:,:,:,3] = taffx
    return affs
end

# transform affinity to segmentation
function aff2seg( affs::Taffs, dim = 3, thd = 0.5 )
    @assert dim==2 || dim==3
    # note that should be column major affinity map
    # the znn V4 output is row major!!! should exchangeaffxz first!
    xaff = affs[:,:,:,1]
    yaff = affs[:,:,:,2]
    zaff = affs[:,:,:,3]

    # number of voxels in segmentation
    N = length(xaff)

    # initialize and create the disjoint sets
    djsets = Tdjsets( N )

    # union the segments by affinity edges
    X,Y,Z = size( xaff )

    # x affinity
    for z in 1:Z
        for y in 1:Y
            for x in 2:X
                if xaff[x,y,z] > thd
                    vid1 = x   + (y-1)*X + (z-1)*X*Y
                    vid2 = x-1 + (y-1)*X + (z-1)*X*Y
                    rid1 = find!(djsets, vid1)
                    rid2 = find!(djsets, vid2)
                    union!(djsets, rid1, rid2)
                end
            end
        end
    end

    # y affinity
    for z in 1:Z
        for y in 2:Y
            for x in 1:X
                if yaff[x,y,z] > thd
                    vid1 = x + (y-1)*X + (z-1)*X*Y
                    vid2 = x + (y-2)*X + (z-1)*X*Y
                    rid1 = find!(djsets, vid1)
                    rid2 = find!(djsets, vid2)
                    union!(djsets, rid1, rid2)
                end
            end
        end
    end

    # z affinity
    if dim > 2
        # only computed in 3D case
        for z in 2:Z
            for y in 1:Y
                for x in 1:X
                    if zaff[x,y,z] > thd
                        vid1 = x + (y-1)*X + (z-1)*X*Y
                        vid2 = x + (y-1)*X + (z-2)*X*Y
                        rid1 = find!(djsets, vid1)
                        rid2 = find!(djsets, vid2)
                        union!(djsets, rid1, rid2)
                    end
                end
            end
        end
    end

    # get current segmentation
    setallroot!( djsets )
    # marking the singletones as boundary
    # copy the segment to avoid overwritting of djsets
    seg = deepcopy( djsets.sets )
    seg = reshape(seg, size(xaff) )
    markbdr!( seg )
    return seg
end

function arr2uniform(x, alg=MergeSort)
    tp = typeof(x)
    sz = size(x)
    # flatten the array
    x = x[:]
    # get the indices
    idx = sortperm( sortperm(x, alg=alg), alg=alg )

    # generating values
    v = linspace(0, 1, length(x))
    # making new array
    v = v[idx]
    v = reshape(v, sz)
    v = tp( v )

    return v
end

function affs2uniform!(affs::Taffs)
    println("transfer to uniform distribution...")
    for z in 1:size(affs,3)
        affs[:,:,z,:] = arr2uniform( affs[:,:,z,:] )
    end
end
