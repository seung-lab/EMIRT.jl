using EMIRT
info("--------- test segmentation ---------")

seg = rand(UInt32, 516,516,64)

## test relabel_seg
println("test relabel_seg ....")
@time relabel_seg(seg)

## test segid1N!
println("test segid1N! ...")
seg2 = deepcopy(seg)

println("test modified serial version ...")
@time segid1N!(seg2)

println("test modified serial version ...")
@time segid1N!(seg2)

println("test multiple threads version: segid1N!_V3")
seg3 = deepcopy(seg)
@time segid1N!_V3(seg3)
@assert all(seg2 .== seg3)
