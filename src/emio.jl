using HDF5
using PyCall
using Compose

export img2svg, imread, imsave

function imread(fname)
    print("reading file: $(fname) ......")
    if contains(fname, ".h5") || contains(fname, ".hdf5")
        ret =  h5read(fname, "/main")
        println("done :)")
        return ret
    elseif contains(fname, ".tif")
        @pyimport tifffile
        vol = tifffile.imread(fname)
        # transpose the dims from z,y,x to x,y,z
        vol = permutedims(vol, Array(ndims(vol):-1:1))
        println("done :)")
        return vol
    else
        error("invalid file type! only support hdf5 and tif now.")
    end
end

function imsave(vol::Array, fname, is_overwrite=true)
    print("saving file: $(fname); ......")
    # remove existing file
    if isfile(fname) && is_overwrite
        rm(fname)
    end

    if contains(fname, ".h5") || contains(fname, ".hdf5")
        h5write(fname, "/main", vol)
    elseif contains(fname, ".tif")
        emio.imsave(vol, fname)
    else
        error("invalid image format! only support hdf5 and tif now.")
    end
    println("done!")
end

function img2svg( img::Array, fname )
    # reshape to vector
    v = reshape( img, length(img))
    draw(SVG(fname, 3inch, 3inch), compose(context(), bitmap("image/png", Array{UInt8}(v), 0, 0, 1, 1)))
end
