using HDF5
using FileIO

import FileIO: save

export imread, imsave, readimg, saveimg, readseg, saveseg, readaff, saveaff, issgmfile, readsgm, savesgm, readec, saveec, readecs, saveecs, save

function imread(fname::AbstractString)
    print("reading file: $(fname) ......")
    if ishdf5(fname)
        ret =  h5read(fname, "/main")
        println("done :)")
        return ret
    else
        # handled by FileIO
        return load(fname)
    end
end


function imsave(fname::AbstractString, vol::Array, is_overwrite=true)
    print("saving file: $(fname); ......")
    # remove existing file
    if isfile(fname) && is_overwrite
        rm(fname)
    end

    if contains(fname, ".h5") || contains(fname, ".hdf5")
        h5write(fname, "/main", vol)
    else
        # handled by FileIO
        save(fname, vol)
    end
    println("done!")
end


"""
read raw image
"""
function readimg(fimg::AbstractString)
    if ishdf5(fimg)
        f = h5open(fimg)
        if has(f, "img")
            img = read(f["img"])
        else
            img = read(f["main"])
        end
        close(f)
    else
        img = reinterpret(UInt8, load(fimg).data)
        if contains(fimg, ".tif")
            # transpose the X and Y
            perm = Vector{Int64}( 1:ndims(img) )
            perm[1:2] = [2,1]
            img = permutedims(img, perm)
        end
    end
    return img
end

"""
save raw image
"""
function save(fimg::AbstractString, img::Timg, dname::AbstractString="img")
    f = h5open(fimg, "w")
    f[dname] = img
    close(f)
end

function saveimg(fimg::AbstractString, img::Timg, dname::AbstractString="img")
    save(fimg, img, dname)
end

"""
read segmentation
"""
function readseg(fseg::AbstractString)
    if ishdf5(fseg)
        f = h5open(fseg)
        if has(f, "seg")
            seg = read(f["seg"])
        else
            @assert has(f, "main")
            seg = read(f["main"])
        end
        close(f)
    else
        seg = reinterpret(UInt32, load(fseg).data)
        if contains(fimg, ".tif")
            # transpose the X and Y
            perm = Vector{Int64}( 1:ndims(seg) )
            perm[1:2] = [2,1]
            seg = permutedims(seg, perm)
        end

    end
    return Tseg(seg)
end

"""
"""
function save(fseg::AbstractString, seg::Tseg, dname::AbstractString="seg")
    f = h5open(fseg, "w")
    f[dname] = seg
    close(f)
end

function saveseg(fseg::AbstractString, seg::Tseg, dname::AbstractString="seg")
    save(fseg,seg, dname)
end

"""
read affinity map
"""
function readaff(faff::AbstractString)
    f = h5open(faff)
    if has(f, "aff")
        aff = read(f["aff"])
    else
        @assert has(f, "main")
        aff = read(f["main"])
    end
    close(f)
    return Taff(aff)
end

"""
save affinity map
"""
function save(faff::AbstractString, aff::Taff, dname::AbstractString="aff")
    f = h5open(faff, "w")
    f[dname] = aff
    close(f)
end

function saveaff(faff::AbstractString, aff::Taff, dname::AbstractString="aff")
    save(faff, aff, dname)
end

"""
whether a file is a sgm file
if the file do not exist, reture false
"""
function issgmfile(fname::AbstractString)
    if !isfile(fname)
        return false
    else
        f = h5open(fname)
        if has(f, "dend")
            return true
        else
            return false
        end
    end
end

"""
read segmentation with maximum spanning tree
"""
function readsgm(fname::AbstractString)
    f = h5open(fname)
    if has(f, "seg")
        seg = read(f["seg"])
    else
        @assert has(f, "main")
        seg = read(f["main"])
    end
    dend = read(f["dend"])
    dendValues = read(f["dendValues"])
    Tsgm(seg, dend, dendValues)
end

"""
save segmentation with dendrogram
"""
function save(fsgm::AbstractString, sgm::Tsgm)
    f = h5open(fsgm, "w")
    f["main"] = sgm.seg
    f["dend"] = sgm.dend
    f["dendValues"] = sgm.dendValues
    close(f)
end
function save(fsgm::AbstractString, seg::Tseg, dend::Tdend, dendValues::TdendValues)
    savesgm( fsgm, Tsgm(seg,dend,dendValues) )
end

function savesgm(fsgm::AbstractString, sgm)
    save(fsgm, sgm)
end

"""
read the error curve
"""
function readec(fname::AbstractString, tag::AbstractString="ec")
    ec = Tec()
    f = h5open(fname)
    f = f["/errorcurve/$tag"]
    ec = readec(f)
    close(f)
    return ec
end

function readec(f::HDF5.HDF5Group)
    ec = Tec()
    for k in names(f)
        ec[ASCIIString(k)] = read(f[k])
    end
    return ec
end

"""
save the error curve
"""
function save(fname::AbstractString, ec::Tec, tag::AbstractString="ec")
    for (k,v) in ec
        h5write(fname, "/errorcurve/$tag/$k", v)
    end
end
function saveec(fec::AbstractString, ec::Tec, tag::AbstractString="ec")
    save(fec, ec, tag)
end

"""
read multiple error curves
"""
function readecs(fname::AbstractString)
    ret = Tecs()
    f = h5open(fname)
    f = f["errorcurve"]
    for tag in names(f)
        ret[tag] = readec(f[tag])
    end
    close(f)
    return ret
end

"""
save learning curves
"""
function save(fname::AbstractString, ecs::Tecs)
    for (tag,ec) in ecs
        saveec(fname, ec, tag)
    end
end
function saveecs(fecs::AbstractString, ecs::Tecs)
    save(fecs, ecs)
end
