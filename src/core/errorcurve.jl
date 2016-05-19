typealias Tec Dict{AbstractString, Vector{Float32}}

function push!(ec::Tec, key::AbstractString, value::Float32)
    if haskey(ec,key)
        ec[key] = push!(ec[key], value)
    else
        ec[key] = [value]
    end
end

function push!(ec::Tec, thd::Float32, rf::Float32, rfm::Float32,
               rfs::Float32, re::Float32, rem::Float32, res::Float32)
    push!(ec, "thd", thd)
    push!(ec, "rf",  rf)
    push!(ec, "rfm", rfm)
    push!(ec, "rfs", rfs)
    push!(ec, "re",  re)
    push!(ec, "rem", rem)
    push!(ec, "res", res)
end

function push!(ec::Tec, thd::Float32, err::Dict{AbstractString, Float32})
    @assert !haskey(err, "thd")
    push!(ec, "thd", thd)
    push!(ec, err)
end

function push!(ec::Tec, err::Dict{AbstractString, Float32})
    for k,v in err
        push!(ec, k, v)
    end
    ec
end

"""
save the error curve
"""
function save(fname::AbstractString, ec::Tec, tag::AbstractString="ec")
    for k,v in ec
        h5write(fname, "/errorcurve/$tag/$k", v)
    end
end
function saveec(fname::AbstractString, ec::Tec, tag::AbstractString="ec")
    save(fname, ec, tag)
end

"""
read the error curve
"""
function readerrorcurve(fname::AbstractString, tag::AbstractString="ec")
    readec(fname, tag)
end
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


typealias Tecs Dict{AbstractString, Tec}

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

function saveecs(fname::AbstractString, ecs::Tecs)
    for tag,ec in ecs
        saveec(fname, ec, tag)
    end
end
