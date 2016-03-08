export configparser

function eparse(s)
    if contains(s, "/") || typeof(parse(s))==Symbol
        # directory or containing alphabet not all number
        return s
    else
        return parse(s)
    end
end

function str2list(s)
    ret = []
    for e in split(s, ',')
        append!(ret, [eparse(e)])
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
    elseif s=="yes" || s=="Yes"|| s=="y" || s=="true" || s=="True"
        return true
    elseif s=="no" || s=="No" || s=="n" || s=="false" || s=="False"
        return false
    else
        # automatic transformation
        return eparse(s)
    end
end

function configparser(fconf::ASCIIString)
    # read text file
    f = open(fconf)
    lines = readlines(f)
    close(f)

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
