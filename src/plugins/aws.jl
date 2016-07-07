using AWS
using AWS.SQS
using AWS.S3
export build_env, iss3, s3_list_objects, fetchSQSmessage, takeSQSmessage!, sendSQSmessage

"""
build aws envariament
automatically fetch key from awscli credential file
"""
function build_env()
    if haskey(ENV, "ACCESS_KEY_ID") && haskey(ENV, "SECRET_ACCESS_KEY")
        id = ENV["ACCESS_KEY_ID"]
        key = ENV["SECRET_ACCESS_KEY"]
        return AWSEnv(; id=id, key=key, ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    elseif isfile(joinpath(homedir(), ".aws/credentials"))
        # get key from aws credential file
        pd = configparser(joinpath(homedir(), ".aws/credentials"))
        id = pd[:default][:aws_access_key_id]
        key = pd[:default][:aws_secret_access_key]
        return AWSEnv(; id=id, key=key, ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    else
        return AWSEnv(; ec2_creds=true, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    end
end

"""
get the url of queue
"""
function get_qurl(env::AWSEnv, qname::AbstractString="spipe-tasks")
    return GetQueueUrl(env; queueName=qname).obj.queueUrl
end

"""
fetch SQS message from queue url
`Inputs:`
env: AWS enviroment
qurl: String, url of queue or queue name
"""
function fetchSQSmessage(env::AWSEnv, qurl::AbstractString)
    if !contains(qurl, "https://sqs.")
        # this is not a url, should be a queue name
        qurl = get_qurl(env, qurl)
    end
    resp = ReceiveMessage(env, queueUrl = qurl)
    msg = resp.obj.messageSet[1]
    return msg
end

"""
take SQS message from queue
will delete mssage after fetching
"""
function takeSQSmessage!(env::AWSEnv, qurl::AbstractString="")
    if !contains(qurl, "https://sqs.")
        # this is not a url, should be a queue name
        qurl = get_qurl(env, qurl)
    end

    msg = fetchSQSmessage(env, qurl)
    # delete the message in queue
    resp = DeleteMessage(env, queueUrl=qurl, receiptHandle=msg.receiptHandle)
    # resp = DeleteMessage(env, msg)
    if resp.http_code < 299
        println("message deleted")
    else
        println("message taking failed!")
    end
    return msg
end


"""
put a task to SQS queue
"""
function sendSQSmessage(env::AWSEnv, qurl::AbstractString, msg::AbstractString)
    if !contains(qurl, "https://sqs.")
        qurl = get_qurl(env, qurl)
    end
    resp = SendMessage(env; queueUrl=qurl, delaySeconds=0, messageBody=msg)
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
function Base.download(env::AWSEnv, s3name::AbstractString, tmpdir::AbstractString)
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

"""
split the path to bucket name and prefix
"""
function splitbktprefix(path::AbstractString)
    path = replace(path, "s3://", "")
    bkt, prefix = split(path, "/", limit = 2)
    bkt = ASCIIString(bkt)
    prefix = ASCIIString(prefix)
    return bkt, prefix
end

"""
list objects of s3. no directory/folder in the list

`Inputs`:
env: AWS environment
bkt: bucket name
path: path

`Outputs`:
ret: list of objects
"""
function s3_list_objects(env::AWSEnv, path::AbstractString, re::Regex = r"^\s*")
    bkt, prefix = splitbktprefix(path)
    return s3_list_objects(env, bkt, prefix, re)
end
function s3_list_objects(path::AbstractString, re::Regex = r"^\s*")
    bkt, prefix = splitbktprefix(path)
    return s3_list_objects(bkt, prefix, re)
end
function s3_list_objects(bkt::AbstractString, prefix::AbstractString, re::Regex = r"^\s*")
    return s3_list_objects(env, bkt, prefix, re)
end
function s3_list_objects(env::AWSEnv, bkt::AbstractString, prefix::AbstractString, re::Regex = r"^\s*")
    prefix = lstrip(prefix, '/')
    # prefix = path=="" ? path : rstrip(path, '/')*"/"
    bucket_options = AWS.S3.GetBucketOptions(delimiter="/", prefix=prefix)
    resp = AWS.S3.get_bkt(env, bkt; options=bucket_options)

    keylst = Vector{ASCIIString}()
    for content in resp.obj.contents
        fname = replace(content.key, prefix, "")
        if fname!="" && ismatch(re, fname)
            push!(keylst, content.key)
        end
    end
    # the prefix is alread a single file
    if keylst == []
        push!(keylst, prefix)
    end
    return bkt, keylst
end
