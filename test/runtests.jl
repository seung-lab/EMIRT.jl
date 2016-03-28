# test the seg error functions
using EMIRT

# get test data
lbl = imread("../assets/stack1-label.tif")

lbl = Array{UInt32,3}(lbl)

@time re, rem, res, rf, rfm, rfs = segerror(lbl,lbl)
@show re, rem, res, rf, rfm, rfs
@assert abs(rf-1) < 0.01

seg = Array{UInt32,3}(reshape(range(1,length(lbl)), size(lbl)))
@time re, rem, res, rf, rfm, rfs = segerror(seg,lbl)
@show re, rem, res, rf, rfm, rfs
@assert abs(rf-0) < 0.01
