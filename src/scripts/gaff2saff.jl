using HDF5
using FileIO
using Formatting

# interprete argument
srcDir = ARGS[1]
dstFile = ARGS[2]

# read images
aff = zeros(Float32, (2048,2048,102,3))

lst_fname = readdir(srcDir)

for c in 0:2
    for z in 0:101
        fname = joinpath(srcDir, "c$(c)_z$(format(z, width=5, zeropadding=true)).tiff")
        img = Array{Float32,2}( load(fname).data )
        aff[:,:,z+1,c+1] = img
    end
end

# correct the affinity definition
sx,sy,sz,sc = size(aff)
aff[2:sx, :, :, 1] = aff[1:sx-1, :, :, 1]
aff[:, 2:sy, :, 2] = aff[:, 1:sy-1, :, 2]
aff[:, :, 2:sz, 3] = aff[:, :, 1:sz-1, 3]

# write result
h5write(dstFile, "main", aff)
