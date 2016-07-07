include("types.jl")

export normalize

function normalize( img::Timg )
    sx,sy,sz = size(img)
    I   = zeros(Float32, (sx,sy))
    ret = zeros(Float32, (sx,sy,sz))
    for z in 1:sz
        I = Array{Float32, 2}(img[:,:,z]) ./ 256
        ret[:,:,z] = (I.-mean(I)) ./ std(I)
    end
    ret
end
