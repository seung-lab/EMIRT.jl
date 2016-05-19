using HDF5

export img2svg, imread, imsave, ecread, readtxt, readaff, saveaff

function imread(fname)
    print("reading file: $(fname) ......")
    if ishdf5(fname)
        ret =  h5read(fname, "/main")
        println("done :)")
        return ret
    #elseif contains(fname, ".tif")
        # @pyimport tifffile
        # vol = tifffile.imread(fname)
        # # transpose the dims from z,y,x to x,y,z
        # vol = permutedims(vol, Array(ndims(vol):-1:1))
        # println("done :)")
        # return vol
    else
        error("invalid file type! only support hdf5 now.")
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
    # elseif contains(fname, ".tif")
    #     @pyimport tifffile
    #     tifffile.imsave(fname, vol)
    #     # emio.imsave(vol, fname)
    else
        error("invalid image format! only support hdf5 now.")
    end
    println("done!")
end

"""
save segmentation with dendrogram
"""
function imsave(fseg::AbstractString, seg::Tseg, dend::Array, dendValues::Vector)
    # save result
    println("save the segments and the mst...")
    h5write(fseg, "/dend", dend)
    h5write(fseg, "/dendValues", dendValues)
    h5write(fseg, "/main", seg)
end

"""
read the evaluation curve in a hdf5 file
`Inputs`:
fname: ASCIIString, file name which contains the evaluation curve

`Outputs`:
dec: Dict of evaluation curve
"""
function ecread(fname)
    ret = Dict{ASCIIString, Vector{Float32}}()
    f = h5open(fname)
    a = f["/processing/znn/forward/"]
    b = a[names(a)[1]]
    c = b[names(b)[1]]
    d = c["evaluate_curve"]
    for key in names(d)
        ret[key] = read(d[key])
    end
    return ret
end

"""
read affinity map
"""
function readaff(faff::AbstractString)
    f = h5open(faff)
    if "aff" in names(f)
        aff = read(f["aff"])
    else
        @assert "main" in names(f)
        aff = read(f["main"])
    end
    close(f)
    return aff
end

"""
save affinity map
"""
function saveaff(faff::AbstractString, aff::Taff)
    f = h5open(faff, "r+")
    f["aff"] = aff
    close(f)
end
