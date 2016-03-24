VERSION >=v"0.4.0-dev+6521" && __precompile__()

module EMIRT

include("domains.jl")
include("affinity.jl")
#include("boundary.jl")
include("emshow.jl")
include("emio.jl")
include("label.jl")
include("evaluate.jl")
include("watershed.jl")
include("emparser.jl")
end
