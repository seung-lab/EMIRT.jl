using EMIRT

info("--------- test image functions -----------")

img = rand(UInt8, 128,128,16)

@time EMIRT.normalize(img)
