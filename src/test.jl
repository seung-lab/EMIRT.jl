using HDF5

affs = h5read("/znn/experiments/malis21/N4_A_1000/out_sample91_output.h5", "/main");

include("affinity.jl")

seg = aff2seg(affs,2)

using PyCall
@pyimport emirt.show as emshow
emshow.random_color_show(seg[:,:,1])
