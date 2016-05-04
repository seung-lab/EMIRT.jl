
export Tseg, Taff, Tpd

# type of segmentation
typealias Tseg Array{UInt32,3}

# type of affinity map
typealias Taff Array{Float32,4}

# type of parameter dictionary
typealias Tpd Dict{AbstractString, Dict{AbstractString, Any}}
