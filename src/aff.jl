include( "domains.jl" )
include("seg.jl")
include("types.jl")

export aff2seg, exchangeaffxz!, aff2uniform, gaff2saff, aff2edgelist

"""
transform google affinity to seung lab affinity
"""
function gaff2saff( gaff )
    @assert ndims(gaff)==3
    sx,sy,sz = size(gaff)
    saff = reshape(gaff, (sx,sy,Int64(sz/3),Int64(3)));

    # transform the x y and z channel
    ret = zeros(saff)
    ret[2:end,:,:, 1] = saff[1:end-1,:,:, 1]
    ret[:,2:end,:, 2] = saff[:,1:end-1,:, 2]
    ret[:,:,2:end, 3] = saff[:,:,1:end-1, 3]

    return ret
end

# exchang X and Z channel of affinity
function exchangeaffxz!(aff::Taff)
    println("exchange x and z of affinity map")
    taffx = deepcopy(aff[:,:,:,1])
    aff[:,:,:,1] = deepcopy(aff[:,:,:,3])
    aff[:,:,:,3] = taffx
    #aff[:,:,:,1], aff[:,:,:,3] = aff[:,:,:,3], aff[:,:,:,1]
    return aff
end

# transform affinity to segmentation
function aff2seg( aff::Taff, dim = 3, thd = 0.5 )
    @assert dim==2 || dim==3
    # note that should be column major affinity map
    # the znn V4 output is row major!!! should exchangeaffxz first!
    xaff = aff[:,:,:,1]
    yaff = aff[:,:,:,2]
    zaff = aff[:,:,:,3]

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

function aff2uniform(aff, alg=QuickSort)
    print("map to uniform distribution...")
    tp = typeof(aff)
    sz = size(aff)
    N = length(aff)

    # get the indices
    print("get the permutation by sorting......")
    @time p = sortperm(aff[:], alg=alg)
    println("done :)")
    q = zeros(p)
    q[p[1:N]] = 1:N

    # generating values
    v = linspace(0, 1, N)
    # making new array
    v = v[q]
    v = reshape(v, sz)
    v = tp( v )
    println("done!")
    return v
end

#function aff2uniform!(aff::Taff)
 #   println("transfer to uniform distribution...")
 #   for z in 1:size(aff,3)
 #       aff[:,:,z,:] = arr2uniform( aff[:,:,z,:] )
 #   end
#end

"""
transfer affinity map to edge list
"""
function aff2edgelist(aff::Taff, is_sort=true)
    # initialize the edge list
    elst = Array{Tuple{Float32,UInt32,UInt32},1}([])
    # get the sizes
    sx,sy,sz,sc = size(aff)
    @assert sc==3

    for z in 1:sz
        for y in 1:sy
            for x in 1:sx
                vid1 = x + (y-1)*sx + (z-1)*sx*sy
                # x affinity
                if x>1
                    vid2 = x-1 + (y-1)*sx + (z-1)*sx*sy
                    push!(elst, (aff[x,y,z,1], vid1, vid2))
                end
                # y affinity
                if y>1
                    vid2 = x + (y-2)*sx + (z-1)*sx*sy
                    push!(elst, (aff[x,y,z,2], vid1, vid2))
                end
                # z affinity
                if z>1
                    vid2 = x + (y-1)*sx + (z-2)*sx*sy
                    push!(elst, (aff[x,y,z,3], vid1, vid2))
                end
            end
        end
    end
    if is_sort
        @time sort!(elst, rev=true)
    end
    return elst
end
