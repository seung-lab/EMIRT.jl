info("-----------test evaluate----------")
# test the seg error functions
using EMIRT

# get test data
aff = imread(joinpath(dirname(@__FILE__),"../assets/aff.h5"))
lbl = imread(joinpath(dirname(@__FILE__),"../assets/lbl.h5"))

lbl = Array{UInt32,3}(lbl)

# compare python code and julia
seg = aff2seg(aff)
judec = evaluate(seg, lbl)
@show judec

# dict of evaluation curve
@time ecd = evaluate(lbl,lbl)
@show ecd
@assert abs(ecd[:rf]-1) < 0.01

seg = Array{UInt32,3}(reshape(range(1,length(lbl)), size(lbl)))
@time ecd = evaluate(seg,lbl)
@show ecd
@assert abs(ecd[:rf]-0) < 0.01
