export show, plot
import Images: Image
import ImageView: view
import Base: show
#import Gadfly: plot
using Gadfly

include("../src/seg.jl")
include("../src/evaluate.jl")
include("../src/errorcurve.jl")
include("utils.jl")

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
    imgc, imgslice = view(Image(cmb, colordim=4, spatialorder=["x","y","z"]))
    # return imgc and imgslice for visualization in a script
    # https://github.com/timholy/ImageView.jl#calling-view-from-a-script-file
    return imgc, imgslice
end

# show affinity map
function show(aff::Taff)
    view(Image(aff, colordim=4, spatialorder=["x","y","z"]))
end

"""
plot multiple error curves
"""
function plotecs(ecs::Tecs)
    # transform to dataframe
    df = ecs2df(ecs)
    # plot the dataframe
    prf = plot(df, x="thd", y="rf", Geom.line,
               Guide.XLabel("threshold"),
               Guide.YLabel("rand f score"))
    pre = plot(df, x="thd", y="re", Geom.line,
               Guide.xlabel("threshold"),
               Guide.ylabel("rand error"))
    prfms = plot(df, x="rfm", y="rfs", Geom.line,
                 Guide.xlabel("rand f score of mergers"),
                 Guide.ylabel("rand f score of splitters"))
    prems = plot(df, x="rem", y="res", Geom.line,
                 Guide.xlabel("rand error of mergers"),
                 Guide.ylabel("rand error of splitters"))
    # stack the subplots
    plt = vstack(hstack(prf,prfms), hstack(pre, prems))
end

"""
plot single error curve
"""
function plotec(ec::Tec)
    ecs = Tecs()
    append!(ecs, ec)
    plot(ecs)
end
