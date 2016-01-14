typealias Tbdrmap Array{Float32,4}

include("label.jl")

# add boundary between contacting segments
function add_lbl_boundary!(lbl::Array)
    for z = 1:size(lbl,3)
        for y = 1: ( size(lbl,2)-1 )
            for x = 1: ( size(lbl,1)-1 )
                # x direction
                if lbl[x,y,z]>0 & lbl[x+1,y,z]>0 & lbl[x,y,z]!=lbl[x+1,y,z]
                    println("$x,$y, ")
                    lbl[x,y,z] = 0
                    lbl[x+1,y,z] = 0
                end
                # y direction
                if lbl[x,y,z]>0 & lbl[x,y+1,z]>0 & lbl[x,y,z]!=lbl[x,y+1,z]
                    println("$x,$y, ")
                    lbl[x,y,z] = 0
                    lbl[x,y+1,z] = 0
                end
            end
        end
    end
    return lbl
end
