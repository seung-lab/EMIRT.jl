export random_color_show
using PyPlot

include("label.jl")

function random_color_show( seg )
    seg2 = copy(seg)
    if ndims(seg2)==2
        sx,sy = size(seg2)
        seg = reshape(seg2, [sx,sy,1])
    end
    @assert ndims(seg2)==3
    rgbseg = seg2rgb!(seg2)
    # note that the seg was transposed to be consistent with python plot
    # because julia use column major and python use row major
    rgbseg = permutedims(rgbseg, [3,2,1])
    imshow( rgbseg[1,:,:] )
end
