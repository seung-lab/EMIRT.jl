using AWS
using AWS.SQS
#using AWS.S3

export build_env, get_qurl, fetchSQSmessage, takeSQSmessage, iss3, s32local

"""
build aws envariament
automatically fetch key from awscli credential file
"""
function build_env()
    # get key from aws credential file
    pd = configparser(joinpath(homedir(), ".aws/credentials"))
    env = AWSEnv(; id=pd["default"]["aws_access_key_id"], key=pd["default"]["aws_secret_access_key"], ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    return env
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
