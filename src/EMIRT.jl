VERSION >=v"0.4.0-dev+6521" && __precompile__()

module EMIRT
include("types.jl")
#include("domains.jl")
include("img.jl")
include("aff.jl")
include("bdr.jl")
#include("emshow.jl")
include("io.jl")
include("seg.jl")
include("sgm.jl")
include("evaluate.jl")
include("parser.jl")
include("sys.jl")
include("utils.jl")
#include("aws.jl")
#include("core/errorcurve.jl")

end
