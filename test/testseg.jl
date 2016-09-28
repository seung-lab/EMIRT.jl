using EMIRT
info("--------- test segmentation ---------")

seg = rand(UInt32, 256,256,64)

## test relabel_seg
println("test relabel_seg ....")
@time relabel_seg(seg)

## test segid1N!
println("test segid1N! ...")
seg2 = deepcopy(seg)
# seg3 = deepcopy(seg)

println("test modified serial version ...")
@time segid1N!(seg2)

# println("test multiple threads version: segid1N!_V3")
# @time segid1N!_V3(seg3)

# @assert all(seg2 .== seg3)
