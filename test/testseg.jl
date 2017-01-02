using EMIRT
info("--------- test segmentation ---------")

seg = rand(UInt32, 516,516,64)

Threads.@threads for i in eachindex(seg)
    if seg[i] < UInt32(50000)
        seg[i] = UInt32(1)
    end
end

println("test creating fake mst ...")
sgm = seg2segMST(seg)

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

# println("test multiple threads version: segid1N!_V3")
# seg3 = deepcopy(seg)
# @time segid1N!_V3(seg3)
# @assert all(seg2 .== seg3)

println("test mask singletons ...")
EMIRT.singleton2boundary!(seg)
EMIRT.singleton2boundary!(seg, seg)

# test mask singleton code
println("test removing singletons by masking ...")
thd = typemax(UInt32) / 0x00000002
function parallel_threshold(seg)
    ret1 = deepcopy(seg)
    Threads.@threads for i in eachindex(seg)
        if seg[i] < thd
            ret1[i] = 0x00000000
        end
    end
    return ret1
end

function serial_threshold(seg)
    ret2 = deepcopy(seg)
    for i in eachindex(seg)
        if seg[i] < thd
            ret2[i] = 0x00000000
        end
    end
    return ret2
end

@time ret1 = parallel_threshold(seg)
@time ret2 = serial_threshold(seg)

@assert all(ret1 .== ret2)
