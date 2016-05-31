using DataFrames
using EMIRT

"""
transform error curve to dataframe
"""
function ec2df(ec::Tec, tag::Symbol=:ec)
    df = DataFrame()
    for (k,v) in ec
        df[k] = v
    end
    df[:tag] = tag
    return df
end

"""
transfer error curves to dataframe
"""
function ecs2df(ecs::Tecs)
    df = DataFrame()
    for (tag,ec) in ecs
        if isempty(df)
            df = ec2df(ec,tag)
        else
            df = join(df, ec2df(ec, tag), on=:tag)
        end
    end
    return df
end
