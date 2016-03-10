using HDF5
using PyCall
@pyimport emirt.emio as emio

export img2svg, imread, imsave

function imread(fname)
    if contains(fname, ".h5") || contains(fname, ".hdf5")
        return h5read(fname, "/main")
    elseif contains(fname, ".tif")
        vol = emio.imread(fname)
        # transpose the dims from z,y,x to x,y,z
        vol = permutedims(vol, Array(ndims(vol):-1:1))
        return vol
    else
        error("invalid file type! only support hdf5 and tif now.")
    end
end

function imsave(vol::Array, fname, is_overwrite=true)
    # remove existing file
    if isfile(fname) && is_overwrite
        rm(fname)
    end

    if contains(fname, ".h5") || contains(fname, ".hdf5")
        h5write(fname, "/main", vol)
    elseif contains(fname, ".tif")
        # transpose the dims from x,y,z to z,y,x
        ret = permutedims(vol, Array(ndims(vol):-1:1))
    else
        error("invalid image format! only support hdf5 and tif now.")
    end
end

function img2svg( img::Array, fname )
    using Compose
    # reshape to vector
    v = reshape( img, length(img))
    draw(SVG(fname, 3inch, 3inch), compose(context(), bitmap("image/png", Array{UInt8}(v), 0, 0, 1, 1)))
end
