# test the seg error functions
using EMIRT

# get test data
lbl = imread("../assets/stack1-label.tif")

lbl = Array{UInt32,3}(lbl)

@time re, rem, res, rf, rfm, rfs = segerror(lbl,lbl)
@show re, rem, res, rf, rfm, rfs
@assert abs(rf-1) < 0.01
