VERSION >=v"0.4.0-dev+6521" && __precompile__()

module EMIRT
include("core/types.jl")
#include("core/domains.jl")
include("core/img.jl")
include("core/aff.jl")
include("core/bdr.jl")
#include("emshow.jl")
include("core/io.jl")
include("core/seg.jl")
include("core/sgm.jl")
include("core/evaluate.jl")
include("core/parser.jl")
include("core/sys.jl")
include("core/utils.jl")
#include("aws.jl")
#include("core/errorcurve.jl")

end
