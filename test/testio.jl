info("----------test io---------------")
using EMIRT

# test image IO
img = Timg(rand(UInt8, 30,30,10))
saveimg("/tmp/img.h5", img)
@assert img == readimg("/tmp/img.h5")

# test segmentation IO
seg = Tseg(rand(UInt32, 30,30,10))
saveseg("/tmp/seg.h5", seg)
@assert seg == readseg("/tmp/seg.h5")

# test affinity IO
aff = Taff(rand(Float32, 30,30,30,3))
saveaff("/tmp/aff.h5", aff)
@assert aff == readaff("/tmp/aff.h5")

# test sgm IO
sgm = seg2sgm(seg)
savesgm("/tmp/sgm.h5", sgm)
sgm2 = readsgm("/tmp/sgm.h5")
# Note! we can only compare by internal field
# julia == function only compare the memory address for mutable objects.
# see https://github.com/JuliaLang/julia/issues/5340
@assert sgm2.seg == sgm.seg
@assert sgm2.dend == sgm.dend
@assert sgm2.dendValues == sgm.dendValues
