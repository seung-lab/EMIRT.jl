using EMIRT
using Watershed

#aff = readaff(joinpath(dirname(@__FILE__),"../assets/piriform.aff.h5"))
aff = readaff("../assets/piriform.aff.h5")

seg, rg = watershed(aff; is_threshold_relative=true);
dend, dendValues = rg2dend(rg)

sgm = Tsgm(seg, dend, dendValues)

merge!(sgm, 0.5);


include(joinpath(Pkg.dir(), "EMIRT/plugins/emshow.jl"))
show(sgm.seg)
#save(joinpath(dirname(@__FILE__),"../assets/sgm.h5", sgm)
