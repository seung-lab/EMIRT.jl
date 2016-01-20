export random_color_show
using PyCall

@pyimport emirt.show as emshow

function random_color_show( seg )
    if ndims(seg)==3
        @assert size(seg,3) == 1
        seg = seg[:,:,1]
    end
    @assert ndims(seg) == 2

    # note that the seg was transposed to be consistent with python plot
    # because julia use column major and python use row major
    emshow.random_color_show( seg' )
end
