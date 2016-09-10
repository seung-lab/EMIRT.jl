using EMIRT
using AWS
using AWS.SQS
using AWS.S3

"""
build aws awsEnvariament
automatically fetch key from awscli credential file
"""
function build_awsEnv()
    if haskey(ENV, "AWS_ACCESS_KEY_ID") && haskey(ENV, "AWS_SECRET_ACCESS_KEY")
        id = ENV["AWS_ACCESS_KEY_ID"]
        key = ENV["AWS_SECRET_ACCESS_KEY"]
        return AWSEnv(; id=id, key=key, ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    elseif isfile(joinpath(homedir(), ".aws/config")) || isfile(joinpath(homedir(), ".aws/credentials"))
        # get key from aws credential file
        if isfile(joinpath(homedir(), ".aws/credentials"))
            pd = configparser(joinpath(homedir(), ".aws/credentials"))
        else
            pd = configparser(joinpath(homedir(), ".aws/config"))
        end
        id = pd[:default][:aws_access_key_id]
        key = pd[:default][:aws_secret_access_key]
        return AWSEnv(; id=id, key=key, ec2_creds=false, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    else
        return AWSEnv(; ec2_creds=true, scheme="https", region="us-east-1", ep="", sig_ver=4, timeout=0.0, dr=false, dbg=false)
    end
end

# build global
global const awsEnv = build_awsEnv()


"""
get the url of queue
"""
function get_qurl(awsEnv::AWSEnv, qname::AbstractString="spipe-tasks")
    return GetQueueUrl(awsEnv; queueName=qname).obj.queueUrl
end

"""
fetch SQS message from queue url
`Inputs:`
awsEnv: AWS awsEnviroment
qurl: String, url of queue or queue name
"""
function fetchSQSmessage(awsEnv::AWSEnv, qurl::AbstractString)
  qurl = ASCIIString(qurl)
  if !contains(qurl, "https://sqs.")
      # this is not a url, should be a queue name
      qurl = get_qurl(awsEnv, qurl)
  end
  resp = ReceiveMessage(awsEnv, queueUrl = qurl)
  msg = resp.obj.messageSet[1]
  return msg
end

function fetchSQSmessage(qurl::AbstractString)
  fetchSQSmessage(awsEnv, qurl)
end

"""
take SQS message from queue
will delete mssage after fetching
"""
function takeSQSmessage!(awsEnv::AWSEnv, qurl::AbstractString="")
  qurl = ASCIIString(qurl)
  if !contains(qurl, "https://sqs.")
      # this is not a url, should be a queue name
      qurl = get_qurl(awsEnv, qurl)
  end

  msg = fetchSQSmessage(awsEnv, qurl)
  # delete the message in queue
  deleteSQSmessage!(awsEnv, msg, qurl)
  return msg
end
function takeSQSmessage!(qurl::AbstractString)
  takeSQSmessage!(awsEnv, qurl)
end

"""
delete SQS message
"""
function deleteSQSmessage!(awsEnv::AWSEnv, msgHandle::AbstractString, qurl::AbstractString)
  qurl = ASCIIString(qurl)
  if !contains(qurl, "https://sqs.")
      qurl = get_qurl(awsEnv, ASCIIString(qurl))
  end
  resp = DeleteMessage(awsEnv, queueUrl=qurl, receiptHandle=msgHandle)
  if resp.http_code < 299
      println("message deleted")
  else
      println("message taking failed!")
  end
end
function deleteSQSmessage!(msgHandle::AbstractString, qurl::AbstractString)
  deleteSQSmessage!(awsEnv, msgHandle, qurl)
end

function deleteSQSmessage!(awsEnv::AWSEnv, msg::AWS.SQS.MessageType, qurl::AbstractString="")
    deleteSQSmessage!(awsEnv, msg.receiptHandle, ASCIIString(qurl))
end
function deleteSQSmessage!(msg::AWS.SQS.MessageType, qurl::AbstractString)
  deleteSQSmessage!(awsEnv, msg, qurl)
end

"""
put a task to SQS queue
"""
function sendSQSmessage(awsEnv::AWSEnv, qurl::AbstractString, msg::AbstractString)
  qurl = ASCIIString(qurl)
  if !contains(qurl, "https://sqs.")
    # AWS/src/sqs_operations.jl:62 requires ASCIIString
    qurl = get_qurl(awsEnv, ASCIIString(qurl))
  end
  resp = SendMessage(awsEnv; queueUrl=ASCIIString(qurl), delaySeconds=0, messageBody=msg)
end
function sendSQSmessage(qurl::AbstractString, msg::AbstractString)
  sendSQSmessage(awsEnv, qurl, msg)
end

"""
whether this file is in s3
"""
function iss3(fname)
    return ismatch(r"^(s3://)", fname)
end
isAWSS3 = iss3

"""
whether this file is google storage
"""
function isGoogleStorage(fname)
  return ismatch(r"^(gs://)", fname)
end

"""
split a s3 path to bucket name and key
"""
function splits3(path::AbstractString)
    path = replace(path, "s3://", "")
    bkt, key = split(path, "/", limit = 2)
    return ASCIIString(bkt), ASCIIString(key)
end

"""
download file from AWS S3
"""
function downloads3(remoteFile::AbstractString, localFile::AbstractString)
  # get bucket name and key
  bkt,key = splits3(remoteFile)
  # download s3 file using awscli
  f = open(localFile, "w")
  resp = S3.get_object(awsEnv, bkt, key)
  # check that the file exist
  @assert resp.http_code == 200
  write( f, resp.obj )
  close(f)
  return localFile
end

"""
transfer s3 file to local and return local file name
`Inputs:`
awsEnv: AWS awsEnviroment
s3name: String, s3 file path
lcname: String, local temporal folder path or local file name

`Outputs:`
lcname: String, local file name
"""
function Base.download(remoteFile::AbstractString, localFile::AbstractString)
    # directly return if not s3 file
    if !iss3(remoteFile)
        return remoteFile
    end

    if isdir(localFile)
        localFile = joinpath(localFile, basename(remoteFile))
    end
    # remove existing file
    if isfile(localFile)
        rm(localFile)
    elseif !isdir(dirname(localFile))
        # create local directory
        mkdir(dirname(localFile))
    end

    if isAWSS3(remoteFile)
      downloads3(remoteFile, localFile)
      # run(`aws s3 cp $(s3name) $(localFile)`)
    elseif isGoogleStorage(remoteFile)
      run(`gsutil -m cp $remoteFile $localFile`)
    end
    return localFile
end

function upload(localFile::AbstractString, remoteFile::AbstractString)
  if iss3(remoteFile)
    # relies on awscli because the upload of AWS.S3 is not really working!
    # https://github.com/JuliaCloud/AWS.jl/issues/70
    if isdir(localFile)
      run(`aws s3 cp --recursive $(localFile) $(remoteFile)`)
    else
      @assert isfile(localFile)
      run(`aws s3 cp $(localFile) $(remoteFile)`)
    end
  elseif isGoogleStorage(remoteFile)
    if isdir(localFile)
      run(`gsutil -m cp -r $localFile $remoteFile`)
    else
      @assert isfile(localFile)
      run(`gsutil -m cp $localFile $remoteFile`)
    end
  else
    error("unsupported remote file link: $(remoteFile)")
  end
end

function sync(awsEnv::AWSEnv, srcDir::AbstractString, dstDir::AbstractString)
  run(`aws s3 sync $srcDir $dstDir`)
end

"""
list objects of s3. no directory/folder in the list

`Inputs`:
awsEnv: AWS awsEnvironment
bkt: bucket name
path: path

`Outputs`:
ret: list of objects
"""
function s3_list_objects(awsEnv::AWSEnv, path::AbstractString, re::Regex = r"^\s*")
    bkt, prefix = splits3(path)
    return s3_list_objects(awsEnv, bkt, prefix, re)
end
function s3_list_objects(path::AbstractString, re::Regex = r"^\s*")
    bkt, prefix = splits3(path)
    return s3_list_objects(bkt, prefix, re)
end
function s3_list_objects(bkt::AbstractString, prefix::AbstractString, re::Regex = r"^\s*")
    return s3_list_objects(awsEnv, bkt, prefix, re)
end
function s3_list_objects(awsEnv::AWSEnv, bkt::AbstractString, prefix::AbstractString, re::Regex = r"^\s*")
    prefix = lstrip(prefix, '/')
    # prefix = path=="" ? path : rstrip(path, '/')*"/"
    bucket_options = AWS.S3.GetBucketOptions(delimiter="/", prefix=prefix)
    resp = AWS.S3.get_bkt(awsEnv, bkt; options=bucket_options)

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
