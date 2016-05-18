using DataFrames

typealias Terrorcurve DataFrame

function push!(ec::Terrorcurve, key::AbstractString, value::Float32)
    if haskey(ec,key)
        ec[key] = push!(ec[key], value)
    else
        ec[key] = [value]
    end
end

function push!(ec::Terrorcurve, thd::Float32, rf::Float32, rfm::Float32,
               rfs::Float32, re::Float32, rem::Float32, res::Float32)
    push!(ec, "thd", thd)
    push!(ec, "rf",  rf)
    push!(ec, "rfm", rfm)
    push!(ec, "rfs", rfs)
    push!(ec, "re",  re)
    push!(ec, "rem", rem)
    push!(ec, "res", res)
end

function push!(ec::Terrorcurve, thd::Float32, err::Dict{AbstractString, Float32})
    @assert !haskey(err, "thd")
    push!(ec, "thd", thd)
    push!(ec, err)
end

function push!(ec::Terrorcurve, err::Dict{AbstractString, Float32})
    for k,v in err
        push!(ec, k, v)
    end
    ec
end

"""
save the error curve
"""
function save(fname::AbstractString, ec::Terrorcurve)
    for k,v in ec
        h5write(fname, "/errorcurve/$k", v)
    end
end
function saveec(fname::AbstractString, ec::Terrorcurve)
    save(fname, ec)
end

"""
read the error curve
"""
function readerrorcurve(fname::AbstractString)
    readec(fname)
end
function readec(fname::AbstractString)
    ec = Terrorcurve()
    f = h5open(fname, "/errorcurve")
    for k in names(f)
        ec[ASCIIString(k)] = read(f[k])
    end
    return ec
end
