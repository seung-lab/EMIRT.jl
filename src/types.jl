
export Tseg, Taff, Tpd, Tsgm

# type of segmentation
typealias Tseg Array{UInt32,3}

# type of affinity map
typealias Taff Array{Float32,4}

# type of parameter dictionary
typealias Tpd Dict{AbstractString, Dict{AbstractString, Any}}

typealias Tdend Vector{Tuple{UInt32,UInt32}}

typealias TdendValues Vector{Float32}

immutable Tsgm
    seg::Tseg
    dend::Tdend
    dendValues::TdendValues
end
