https = require('https')
crypto = require('crypto')
url = require('url')
# Local memory cache for PEM certificates
pem_cache = {}
# keys required in a valid SNS request
REQUIRED_KEYS = [
  'Type'
  'MessageId'
  'TopicArn'
  'Message'
  'Timestamp'
  'SignatureVersion'
  'Signature'
  'SigningCertURL'
]

validateRequest = (opts, message, cb) ->
  # Let's make sure all keys actually exist to avoid errors
  i = 0
  while i < REQUIRED_KEYS.length
    if !(REQUIRED_KEYS[i] of message)
      return cb(new Error('Invalid request'))
    i++
  # short circuit to be able to bypass validation
  if 'verify' of opts and opts.verify == false
    return cb()
  cert = url.parse(message.SigningCertURL)
  arn = message.TopicArn.split(':')
  # TopicArn Format:  arn:aws:sns:{{ region }}:{{ account }}:{{ topic }}
  if opts.region and opts.region != arn[3]
    return cb(new Error('Invalid request'))
  if opts.account and opts.account != arn[4]
    return cb(new Error('Invalid request'))
  if opts.topic and opts.topic != arn[5]
    return cb(new Error('Invalid request'))
  # Make sure the certificate comes from the same region
  if cert.host != 'sns.' + arn[3] + '.amazonaws.com'
    return cb(new Error('Invalid request'))
  # check if certificate has been downloaded before and cached
  if message.SigningCertURL of pem_cache
    pem = pem_cache[message.SigningCertURL]
    return validateMessage(pem, message, cb)
  else
    https.get cert, (res) ->
      chunks = []
      res.on 'data', (chunk) ->
        chunks.push chunk
        return
      res.on 'end', ->
        `var pem`
        pem = chunks.join('')
        pem_cache[message.SigningCertURL] = pem
        validateMessage pem, message, cb
      res.on 'error', ->
        cb new Error('Could not download certificate.')
      return
  return

validateMessage = (pem, message, cb) ->
  msg = buildSignatureString(message)
  if !msg
    return cb(new Error('Invalid request'))
  verifier = crypto.createVerify('RSA-SHA1')
  verifier.update msg, 'utf8'
  if verifier.verify(pem, message.Signature, 'base64') then cb() else cb(new Error('Invalid request'))

buildSignatureString = (message) ->
  chunks = []
  if message.Type == 'Notification'
    chunks.push 'Message'
    chunks.push message.Message
    chunks.push 'MessageId'
    chunks.push message.MessageId
    if message.Subject
      chunks.push 'Subject'
      chunks.push message.Subject
    chunks.push 'Timestamp'
    chunks.push message.Timestamp
    chunks.push 'TopicArn'
    chunks.push message.TopicArn
    chunks.push 'Type'
    chunks.push message.Type
  else if message.Type == 'SubscriptionConfirmation'
    chunks.push 'Message'
    chunks.push message.Message
    chunks.push 'MessageId'
    chunks.push message.MessageId
    chunks.push 'SubscribeURL'
    chunks.push message.SubscribeURL
    chunks.push 'Timestamp'
    chunks.push message.Timestamp
    chunks.push 'Token'
    chunks.push message.Token
    chunks.push 'TopicArn'
    chunks.push message.TopicArn
    chunks.push 'Type'
    chunks.push message.Type
  else
    return false
  chunks.join('\n') + '\n'

SNSClient = (opts, cb) ->
  # opts is entirely optional, but cb is not
  if typeof opts == 'function'
    cb = opts
    opts = {}
  (req, res) ->
    chunks = []
    req.on 'data', (chunk) ->
      chunks.push chunk
      return
    req.on 'end', ->
      message = undefined
      try
        message = JSON.parse(chunks.join(''))
      catch e
        # catch a JSON parsing error
        return cb(new Error('Error parsing JSON'))
      validateRequest opts, message, (err) ->
        if err
          return cb(err)
        if message.Type == 'SubscriptionConfirmation'
          return https.get(url.parse(message.SubscribeURL))
        if message.Type == 'Notification'
          return cb(null, message)
        return
      return
    # end the request always before doing anything with the request.
    # There isn't any reason to let it hang.
    res.end()
    return

module.exports = SNSClient

