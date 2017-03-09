export seg2aff, markbdr!, relabel_seg, reassign_segid1N!, add_lbl_boundary!, seg2rgb, seg_overlay_img!, seg2sgm, segid1N!
using Colors
using FixedPointNumbers
include("domains.jl")

include("types.jl")

"""
construct affinity map from segmentation
"""
function seg2aff(seg::Segmentation)
  aff = zeros(Float32, (size(seg)..., 3))
  aff[2:end, :,:,1] = (seg[2:end, :,:] .== seg[1:end-1, :,:])
  aff[:, 2:end,:,2] = (seg[:, 2:end,:] .== seg[:, 1:end-1,:])
  aff[:,:, 2:end,3] = (seg[:,:, 2:end] .== seg[:,:, 1:end-1])
  aff
end

# label all the singletones as boundary
function markbdr!( seg::Segmentation )

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
function relabel_seg( lbl::Segmentation, dim=3 )
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
function segid1N!( lbl::Segmentation )
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
    return N
end

# add boundary between contacting segments
function add_lbl_boundary!(lbl::Array, conn=8)
    # neighborhood definition
    @assert conn==8 || conn==4
    sx,sy,sz = size(lbl)
    for z = 1:sz
        for y = 1:sy
            for x = 1:sx
                if lbl[x,y,z]==0
                    # ignore the existing boundary
                    continue
                end
                # flag of central pixel
                cf = false
                # x direction
                if x<sx && lbl[x+1,y,z]>0 && lbl[x,y,z]!=lbl[x+1,y,z]
                    cf = true
                    lbl[x+1,y,z] = 0
                end
                # y direction
                if y<sy && lbl[x,y+1,z]>0 && lbl[x,y,z]!=lbl[x,y+1,z]
                    cf = true
                    lbl[x,y+1,z] = 0
                end
                if x>1 && lbl[x-1,y,z]>0 && lbl[x,y,z]!=lbl[x-1,y,z]
                    cf = true
                    lbl[x-1,y,z] = 0
                end
                if y>1 && lbl[x,y-1,z]>0 && lbl[x,y,z]!=lbl[x,y-1,z]
                    cf = true
                    lbl[x,y-1,z] = 0
                end

                if conn==8
                    if x<sx && y<sy && lbl[x+1,y+1,z]>0 && lbl[x,y,z]!=lbl[x+1,y+1,z]
                        cf = true
                        lbl[x+1,y+1,z] = 0
                    end

                    if x>1 && y<sy && lbl[x-1,y+1,z]>0 && lbl[x,y,z]!=lbl[x-1,y+1,z]
                        cf = true
                        lbl[x-1,y+1,z] = 0
                    end
                    if x<sx && y>1 && lbl[x+1,y-1,z]>0 && lbl[x,y,z]!=lbl[x+1,y-1,z]
                        cf = true
                        lbl[x+1,y-1,z] = 0
                    end
                    if x>1 && y>1 && lbl[x-1,y-1,z]>0 && lbl[x,y,z]!=lbl[x-1,y-1,z]
                        cf = true
                        lbl[x-1,y-1,z] = 0
                    end
                end
                if cf
                    print("$x,$y, ")
                    lbl[x,y,z] = 0
                end
            end
        end
    end
end


"""
transform segmentation to domains
Inputs:
seg: a segmentation or label of image volume

Outputs:
dms: domains for fast union-find algorithm defined in "domains.jl"
"""
function seg2dms(seg::Segmentation, is_merge = true)
    # initialize a domain as singletons
    @assert ndims(seg)==2 || ndims(seg)==3
    dms = Tdomains( length(seg) )

    # if do not merge, return directly
    if !is_merge
        return dms
    end

    # volume size
    sx,sy,sz = size(seg)

    # union all the voxel with same segment ID
    for z in 1:sz
        for y in 1:sy
            for x in 1:sx
                # voxel id
                vid1 = x + (y-1)*sx + (z-1)*sx*sy
                # segmentation ID
                sid1 = seg[x,y,z]

                # x affinity
                if x>1 && sid1==seg[x-1,y,z]
                    vid2 = x-1 + (y-1)*sx + (z-1)*sx*sy
                    union!(dms, vid1, vid2)
                end

                # y affinity
                if y>1 && sid1==seg[x,y-1,z]
                    vid2 = x + (y-2)*sx + (z-1)*sx*sy
                    union!(dms, vid1, vid2)
                end

                # z affinity
                if z>1 && sid1==seg[x,y,z-1]
                    vid2 = x + (y-1)*sx + (z-2)*sx*sy
                    union!(dms, vid1, vid2)
                end
            end
        end
    end
    return dms
end

"""
transform indexed segmentation image to RGB image with random color label
seg: segmentation, an indexed array

Outputs:
ret: rgb image array with a size of X x Y x Z x 3, the color dim is the last one
"""
function seg2rgb(seg::Segmentation)
    # the color dict, key is segment id, value is color
    dcol = Dict{UInt32, RGB{N0f8}}()
    # set the boundary color to be black
    dcol[0] = RGB{N0f8}(0,0,0)

    # create RGB image
    sx,sy,sz = size(seg)
    ret = Array(RGB{N0f8}, (sx,sy,sz))
    # assign random color
    for z = 1:sz
        for y = 1:sy
            for x = 1:sx
                key = seg[x,y,z]
                if !haskey(dcol, key)
                    dcol[key] = rand(RGB{N0f8})
                end
                ret[x,y,z] = dcol[key]
            end
        end
    end
    return ret
end

"""
overlay segmentation to gray image using Alpha compositing
https://en.wikipedia.org/wiki/Alpha_compositing
Inputs:
img: gray image array
seg: segmentation, an indexed array
alpha1: the alpha value of the image
alpha2: the alpha value of the segmentation

Outputs:
ret: composited RGBA image array
"""
function seg_overlay_img(img, seg, alpha1=0.5, alpha2=0.5)
    @assert size(img)==size(seg)
    @assert alpha1>0 && alpha1<1
    @assert alpha2>0 && alpha2<1
    sx,sy,sz = size(img)

    # initialize the returned RGBA image
    ret = zeros(Float32,(sx,sy,sz,3))

    # colorful segmentation image
    cseg = seg2rgb(Segmentation(seg))

    # transform img to 0-1
    fimg = Array{Float32,3}(img)
    fimg = ( fimg-minimum(fimg) ) ./ (maximum(fimg) - minimum(fimg))

    for z in 1:sz
        for y in 1:sy
            for x in 1:sx
                if seg[x,y,z]==0
                    # completely transparent in boundary regions
                    ret[x,y,z,1] = fimg[x,y,z]
                    ret[x,y,z,2] = fimg[x,y,z]
                    ret[x,y,z,3] = fimg[x,y,z]
                else
                    # only composite in non-boundary regions
                    ret[x,y,z,1] = ( fimg[x,y,z]*alpha1 + cseg[x,y,z,1]*alpha2*(1-alpha1) ) / (alpha1+alpha2*(1-alpha1))
                    ret[x,y,z,2] = ( fimg[x,y,z]*alpha1 + cseg[x,y,z,2]*alpha2*(1-alpha1) ) / (alpha1+alpha2*(1-alpha1))
                    ret[x,y,z,3] = ( fimg[x,y,z]*alpha1 + cseg[x,y,z,3]*alpha2*(1-alpha1) ) / (alpha1+alpha2*(1-alpha1))
                end
            end
        end
    end
    return ret
end

"""
transform segmentation to sgm by making fake mst
"""
function seg2sgm(seg::Segmentation)
    # making fake mst
    segmentPairs = zeros(UInt32, (1,2))
    segmentPairs[1] = seg[1]
    segmentPairs[2] = seg[end]
    segmentPairAffinities = Vector{Float32}( [0.001] )

    return SegMST(seg, segmentPairs, segmentPairAffinities)
end
