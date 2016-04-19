# test the seg error functions
using EMIRT

# get test data
affs = imread("../assets/affs.h5")
lbl = imread("../assets/lbl.h5")

lbl = Array{UInt32,3}(lbl)

# test affinity curve, dict of error curve
dec = affs_error_curve(affs, lbl)
@show dec

# compare python code and julia
seg = aff2seg(affs)
pydec = pysegerror(seg, lbl)
judec = segerror(seg, lbl)
@show pydec
@show judec

for (k,v1) in pydec
    v2 = judec[k]
    @show k
    @assert maximum(abs(v2.-v1)) < 0.01
end

# dict of evaluation curve
@time ecd = segerror(lbl,lbl)
@show ecd
@assert abs(ecd["rf"]-1) < 0.01

seg = Array{UInt32,3}(reshape(range(1,length(lbl)), size(lbl)))
@time ecd = segerror(seg,lbl)
@show ecd
@assert abs(ecd["rf"]-0) < 0.01
