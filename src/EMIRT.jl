VERSION >=v"0.4.0-dev+6521" && __precompile__()

module EMIRT
include("types.jl")
include("domains.jl")
include("common.jl")
include("sys.jl")
include("image.jl")
include("affinitymap.jl")
include("io.jl")
include("segmentation.jl")
include("segmentmst.jl")
include("evaluate.jl")
include("parser.jl")
end
