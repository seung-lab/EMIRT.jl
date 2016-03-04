export configparser

function str2list(s)
    ret = Array
    for e in split(s, ',')
        append!(ret, parse(e))
    end
end

function str2array(s)
    ret = Array
    for r in split(s, ';')
        append!(ret, str2list(r))
    end
end

# auto conversion of string
function str2auto(s)
    if contains(s, ';')
        return str2array(s)
    elseif contains(s, ',')
        return str2list(s)
    else
        # automatic transformation
        return parse(s)
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
        if ismatch(r"^\s*#", l) || ismatch(r"^\s*\n")
            continue
        elseif ismatch(r"^\s*\[.*\]", l)
            # update the section name
            m = match(r"\[.*\]", l)
            sec = m.match[2:end-1]
            pd[sec] = Dict()
        elseif ismatch(r"^\s*.*\s*=", l)
            k, v = split(l, '=')
            k = replace(k, " ", "")
            v = replace(v, " ", "")
            # assign value to dictionary
            pd[sec][k] = v
        end
    end
end
