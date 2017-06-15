info("----------test io---------------")
using EMIRT

fileName = "$(tempname()).h5"
# test image IO
img = EMImage(rand(UInt8, 300,300,10))
saveimg(fileName, img)
@assert img == readimg(fileName)
rm(fileName)

# test segmentation IO
seg = Segmentation(rand(UInt32, 300,300,10))
saveseg(fileName, seg)
@assert seg == readseg(fileName)
rm(fileName)

# test affinity IO
aff = AffinityMap(rand(Float32, 300,300,30,3))
saveaff(fileName, aff)
@assert aff == readaff(fileName)
rm(fileName)

# test sgm IO
sgm = seg2sgm(seg)
savesgm(fileName, sgm)
sgm2 = readsgm(fileName)
# Note! we can only compare by internal field
# julia == function only compare the memory address for mutable objects.
# see https://github.com/JuliaLang/julia/issues/5340
@assert sgm2.segmentation == sgm.segmentation
@assert sgm2.segmentPairs == sgm.segmentPairs
@assert sgm2.segmentPairAffinities == sgm.segmentPairAffinities
rm(fileName)
