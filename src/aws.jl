using AWS
#using AWS.SQS
#using AWS.S3

export build_env, iss3, s32local

"""
build aws envariament
automatically fetch key from awscli credential file
"""
function build_env()
    if haskey(ENV, "ACCESS_KEY_ID") && haskey(ENV, "SECRET_ACCESS_KEY")
        id = ENV["ACCESS_KEY_ID"]
        key = ENV["SECRET_ACCESS_KEY"]
    else
        # get key from aws credential file
        pd = configparser(joinpath(homedir(), ".aws/credentials"))
        id = pd["default"]["aws_access_key_id"]
        key = pd["default"]["aws_secret_access_key"]
    end
    return AWSEnv(; id=id, key=key, ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
end


"""
whether this file is in s3
"""
function iss3(fname)
    return ismatch(r"^(s3://)", fname)
end

"""
transfer s3 file to local and return local file name
`Inputs:`
env: AWS enviroment
s3name: String, s3 file path
lcname: String, local temporal folder path or local file name

`Outputs:`
lcname: String, local file name
"""
function s32local(env::AWSEnv, s3name::AbstractString, tmpdir::AbstractString)
    # directly return if not s3 file
    if !iss3(s3name)
        return s3name
    end

    @assert isdir(tmpdir)
    # get the file name

    dir, fname = splitdir(s3name)
    dir = replace(dir, "s3://", "")
    # local directory
    lcdir = joinpath(tmpdir, dir)
    # local file name
    lcfname = joinpath(lcdir, fname)
    # remove existing file
    if isfile(lcfname)
        rm(lcfname)
    else
        # create local directory
        mkpath(lcdir)
    end
    # download s3 file using awscli
    run(`aws s3 cp $(s3name) $(lcfname)`)
    return lcfname
end
