export show, plot
using Gadfly
import Images: Image
import ImageView: view

include("../core/seg.jl")
include("../core/evaluate.jl")
include("../core/errorcurve.jl")
include("utils.jl")

import Base: show
# show segmentationx
function show( seg::Tseg )
    @assert ndims(seg)==3
    rgbseg = seg2rgb(seg)
    view(Image(rgbseg, colordim=4, spatialorder=["x","y","z"]))
end

# show raw image
function show(img::Timg)
    view(Image(img, spatialorder=["x","y","z"]))
end

# show raw image and segmentation combined together
function show(img::Timg, seg::Tseg)
    # combined rgb image stack
    cmb = seg_overlay_img(img, seg)
    view(Image(cmb, colordim=4, spatialorder=["x","y","z"]))
end

# show affinity map
function show(aff::Taff)
    view(Image(aff, colordim=4, spatialorder=["x","y","z"]))
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
