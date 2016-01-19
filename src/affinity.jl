include( "domains.jl" )
include("label.jl")

export aff2seg

typealias Taffmap Array{Float32,4}

# transform affinity to segmentation
function aff2seg( affs::Taffmap, dim = 3, thd = 0.5 )
    @assert dim==2 || dim==3
    xaff = affs[:,:,:,3]
    yaff = affs[:,:,:,2]
    zaff = affs[:,:,:,1]

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
