export cleardir, memory

"""
clear a floder
"""
function cleardir(dir::AbstractString)
    for fname in readdir(dir)
        rm(joinpath(dir, fname), recursive=true)
    end
end

"""
get memory info of current machine
"""
function memory()
    info = split(readall(`free -g`))
    total = parse(info[8])
    free = parse(info[9])
    return total, free
end
