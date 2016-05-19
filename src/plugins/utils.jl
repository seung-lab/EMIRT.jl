using DataFrame

"""
transform error curve to dataframe
"""
function ec2df(ec::Tec, tag::AbstractString="ec")
    df = DataFrame()
    for k,v in ec
        df[Symbol(k)] = v
    end
    df[:tag] = [tag for i in 1:length(values(ec)[1])]
    return df
end

"""
transfer error curves to dataframe
"""
function ecs2df(ecs::Tecs)
    df = DataFrame()
    for tag, ec in ecs
        if isempty(df)
            df = ec2df(ec,tag)
        else
            df = join(df, ec2df(ec, tag), on=:tag)
        end
    end
    return df
end
