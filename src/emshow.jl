export random_color_show
using PyPlot

include("label.jl")

function random_color_show( seg )
    if ndims(seg)==3
        seg2 = seg[:,:,1]
    end

    sx,sy = size(seg2)
    seg2 = reshape(seg2, (sx,sy,1))
    seg2 = copy(Tseg(seg2))

    @assert ndims(seg2)==3
    rgbseg = seg2rgb!(seg2)
    # note that the seg was transposed to be consistent with python plot
    # because julia use column major and python use row major
    rgbseg = permutedims(rgbseg[:,:,:,1], [3,2,1])
    imshow( rgbseg )
end
