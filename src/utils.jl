#=doc
Utilities
=#

export percent2thd, crop_border

#=doc
.. function::
   Transform ralative threshold to absolute threshold
   Args:
   -
=#
function percent2thd(e::FloatRange{Float64}, count::Vector{Int64}, rt::AbstractFloat)
    # total number
    tn = sum(count)
    # the rank of voxels corresponding to the threshold
    rank = tn * rt
    # accumulate the voxel number
    avn = 0
    for i in 1:length(e)
        avn += count[i]
        if avn >= rank
            return e[i]
        end
    end
end

function percent2thd(arr::Array, rt::AbstractFloat, nbin=100000)
    e, count = hist(arr[:], nbin)
    return percent2thd(e, count, rt)
end

"""
throwaway the border region of an array (ndims > 3), currently only works for 3D cropsize.
"""
function crop_border(arr::Array, cropsize::Union{Vector,Tuple})
    @assert ndims(arr) >= 3
    sz = size(arr)
    @assert sz[1]>cropsize[1]*2 &&
            sz[2]>cropsize[2]*2 &&
            sz[3]>cropsize[3]*2
    return arr[ cropsize[1]+1:sz[1]-cropsize[1],
                cropsize[2]+1:sz[2]-cropsize[2],
                cropsize[3]+1:sz[3]-cropsize[3]]
end
