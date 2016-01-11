using PyCall

@pyimport emirt.show as emshow

function random_color_show( seg )
    @assert ndims(seg) == 2
    emshow.random_color_show( seg )
end
