VERSION >=v"0.4.0-dev+6521" && __precompile__()

module EMIRT

function __init__()
    # use the maximum cores for parallel computation
    if nprocs() < CPU_CORES
        addprocs(CPU_CORES - nprocs())
    end
end

include("domains.jl")
include("affinity.jl")
#include("boundary.jl")
include("emshow.jl")
include("emio.jl")
include("label.jl")
include("evaluate.jl")
include("emparser.jl")
include("filesystem.jl")
include("utils.jl")
include("types.jl")
end
