using HDF5
using FileIO
using Formatting

# interprete argument
srcDir = ARGS[1]
dstFile = ARGS[2]

# read images
buffer = zeros(Float32, (2048,2048,102,3))

lst_fname = readdir(srcDir)

for c in 0:2
    for z in 0:101
        fname = joinpath(srcDir, "c$(c)_z$(format(z, width=5, zeropadding=true)).tiff")
        img = Array{Float32,2}( load(fname).data )
        buffer[:,:,z+1,c+1] = img
    end
end

# write result
h5write(dstFile, "main", buffer)
