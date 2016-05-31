export append!, fetch, take!

import Base: append!, fetch, take!

"""
push to error curve
"""
function append!(ec::Tec, key::AbstractString, value::Float32)
    if haskey(ec,key)
        ec[key] = push!(ec[key], value)
    else
        ec[key] = [value]
    end
    ec
end

function append!(ec::Tec, thd::Float32, rf::Float32, rfm::Float32,
               rfs::Float32, re::Float32, rem::Float32, res::Float32)
    append!(ec, "thd", thd)
    append!(ec, "rf",  rf)
    append!(ec, "rfm", rfm)
    append!(ec, "rfs", rfs)
    append!(ec, "re",  re)
    append!(ec, "rem", rem)
    append!(ec, "res", res)
    ec
end

function append!(ec::Tec, thd::Float32, err::Dict{AbstractString, Float32})
    @assert !haskey(err, "thd")
    append!(ec, "thd", thd)
    append!(ec, err)
end

function append!(ec::Tec, err::Dict{ASCIIString, Float32})
    for (k,v) in err
        append!(ec, k, v)
    end
    ec
end

# error curves containing multiple error curves
"""
push an error curve
"""
function append!(ecs::Tecs, key::AbstractString, value::Float32, tag::AbstractString="ec")
    append!(ecs[tag], key, value)
    ecs
end

function append!(ecs::Tecs, err::Dict{AbstractString, Float32}, tag::AbstractString="ec")
    append!(ecs[tag], err)
    ecs
end

"""
fetch an error curve
"""
function fetch(ecs::Tecs, tag::AbstractString="ec")
    return ecs[tag]
end

"""
take an error curve
"""
function take!(ecs::Tecs, tag::AbstractString="ec")
    ec = ecs[tag]
    delete!(ecs, tag)
    return ec
end
