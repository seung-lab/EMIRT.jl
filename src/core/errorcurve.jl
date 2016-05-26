import Base: push!, fetch, take!

"""
push to error curve
"""
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
    for (k,v) in err
        push!(ec, k, v)
    end
    ec
end

# error curves containing multiple error curves
"""
push an error curve
"""
function push!(ecs::Tecs, key::AbstractString, value::Float32, tag::AbstractString="ec")
    push!(ecs[tag], key, value)
end

function push!(ecs::Tecs, err::Dict{AbstractString, Float32}, tag::AbstractString="ec")
    push!(ecs[tag], err)
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
