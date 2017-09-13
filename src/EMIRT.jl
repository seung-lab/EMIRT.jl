VERSION >=v"0.5.0" && __precompile__()

module EMIRT
include("types.jl")
include("ios.jl")
include("domains.jl")
include("common.jl")
include("sys.jl")
include("images.jl")
include("segmentations.jl")
include("affinitymaps.jl")
include("evaluate.jl")
include("segmentmsts.jl")
include("parser.jl")

using .Types
using .Images
using .IOs
using .AffinityMaps
using .Segmentations
using .Evaluate
using .SegmentMSTs

export EMImage, Segmentation, AffinityMap, ParamDict, SegMST, SegmentPairs, SegmentPairAffities

end
