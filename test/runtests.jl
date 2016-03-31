# test the seg error functions
using EMIRT

# get test data
lbl = imread("../assets/stack1-label.tif")

lbl = Array{UInt32,3}(lbl)

# dict of evaluation curve
@time ecd = segerror(lbl,lbl)
@show ecd
@assert abs(ecd["rf"]-1) < 0.01

seg = Array{UInt32,3}(reshape(range(1,length(lbl)), size(lbl)))
@time ecd = segerror(seg,lbl)
@show ecd
@assert abs(ecd["rf"]-0) < 0.01
