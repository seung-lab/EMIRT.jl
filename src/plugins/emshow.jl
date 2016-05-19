export random_color_show, plot
using PyPlot
using Gadfly

include("../core/label.jl")
include("../core/evaluate.jl")
include("../core/errorcurve.jl")
include("utils.jl")

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

"""
plot multiple error curves
"""
function plot(ecs::Tecs)
    # transform to dataframe
    df = ecs2df(ecs)
    # plot the dataframe
    prf = plot(df, x="thd", y="rf", color="tag", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand f score"))
    pre = plot(df, x="thd", y="re", color="tag", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand error"))
    prfms = plot(df, x="rfm", y="rfs", color="tag", Geom.line,
                 Guide.xlabel("rand f score of mergers"),
                 Guide.ylabel("rand f score of splitters"))
    prems = plot(df, x="rem", y="res", color="tag", Geom.line,
                 Guide.xlabel("rand error of mergers"),
                 Guide.ylabel("rand error of splitters"))
    # stack the subplots
    plt = vstack(hstack(prf,prfms), hstack(pre, prems))
end
