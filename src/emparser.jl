export configparser, argparser!

function str2list(s)
    ret = []
    for e in split(s, ',')
        append!(ret, [autoparse(e)])
    end
    return ret
end

function str2array(s)
    ret = []
    for r in split(s, ';')
        t = str2list(r)
        if length(t)>0
            append!(ret, collect(t))
        end
    end
    return ret
end

# auto conversion of string
function autoparse(s)
    if contains(s, ";")
        return str2array(s)
    elseif contains(s, ",")
        return str2list(s)
    elseif s=="yes" || s=="Yes"|| s=="y" || s=="Y" || s=="true" || s=="True"
        return true
    elseif s=="no" || s=="No" || s=="n" || s=="N" || s=="false" || s=="False"
        return false
    elseif contains(s, "/") || ismatch(r"^[A-z]", s) || typeof(parse(s))==Symbol || typeof(parse(s)) == Expr
        # directory or containing alphabet not all number
        return s
    else
        return parse(s)
    end
end

"""
parse the lines
`Inputs:`
lines: cofiguration file name or lines of configuration file

`Outputs:`
pd: Dict, dictionary containing parameters
"""
function configparser(lines)
    if isfile(lines)
        lines = readtxt(lines)
    end
    # initialize the parameter dictionary
    pd = Dict()
    # default section name
    sec = "section"
    # analysis the lines
    for l in lines
        # remove space and \n
        l = replace(l, " ", "")
        l = replace(l, "\n", "")
        if ismatch(r"^\s*#", l) || ismatch(r"^\s*\n", l)
            continue
        elseif ismatch(r"^\s*\[.*\]", l)
            # update the section name
            m = match(r"\[.*\]", l)
            sec = m.match[2:end-1]
            pd[sec] = Dict()
        elseif ismatch(r"^\s*.*\s*=", l)
            k, v = split(l, '=')
            # assign value to dictionary
            pd[sec][k] = autoparse( v )
        end
    end
    return pd
end

"""
parameter dictionary
input can be some default dictionary

Note that all the key was one character, which is the first non '-' character!
suppose that the argument is as follows:
--flbl label.h5 --range 2,4-6
the returned dictionary will be
pd['f'] = "label.h5"
pd['r'] = [2,4,5,6]
"""
function argparser!(pd=Dict() )
    println("default parameters: $(pd)")
    # argument table, two rows
    @assert length(ARGS) % 2 ==0
    argtbl = reshape(ARGS, 2,Int64( length(ARGS)/2))

    # traverse all the argument table columns
    for c in 1:size(argtbl,2)
        @assert argtbl[1,c][1]=='-'
        # key and value
        k = replace(argtbl[1,c],"-","")[1]
        v = autoparse( argtbl[2,c] )
        pd[k] = v
    end
    println("parameters after command line parsing: $(pd)")
end
