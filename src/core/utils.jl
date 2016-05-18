#=doc
Utilities
=#

export percent2thd

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
