
export Timg, Tseg, Taff, Tpd, Tsgm, Tdend, TdendValues, Tec, Tecs

# type of raw image
typealias Timg Array{UInt8,3}

# type of segmentation
typealias Tseg Array{UInt32,3}

# type of affinity map
typealias Taff Array{Float32,4}

# type of parameter dictionary
typealias Tpd Dict{Symbol, Dict{Symbol, Any}}

typealias Tdend Array{UInt32,2}

typealias TdendValues Vector{Float32}

immutable Tsgm
    seg::Tseg
    dend::Tdend
    dendValues::TdendValues
end

# error curve
typealias Tec Dict{Symbol, Vector{Float32}}
# error curves
typealias Tecs Dict{Symbol, Tec}
