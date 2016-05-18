export random_color_show
using PyPlot

include("label.jl")
include("evaluate.jl")

function random_color_show( seg )
    seg2 = seg
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


function plot(ec::Terrorcurve, clr="blue")
    plot(layer(x=ec["thd"], y=ec["rf"],
               Geom.line, Theme(default_color=color(clr))),
         Guide.xlabel("threshold"), Guide.ylabel("rand f score")))
    plot(layer(x=ec["thd"], y=ec["re"],
               Geom.line, Theme(default_color=color(clr))),
         Guide.xlabel("threshold"), Guide.ylabel("rand error")))

    plot(layer(x=ec["rfm"], y=ec["rfs"],
               Geom.line, Theme(default_color=color(clr))),
         Guide.xlabel("rand f score of merging"), Guide.ylabel("rand f score of splitting")))
    plot(layer(x=ec["rem"], y=ec["res"],
               Geom.line, Theme(default_color=color(clr))),
         Guide.xlabel("rand error of mergers"), Guide.ylabel("rand error of splitters")))
end
