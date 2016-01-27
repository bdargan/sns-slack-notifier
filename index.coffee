'use strict'
_ = require 'lodash'
secrets = require './secrets'
http = require 'http'
bunyan = require 'bunyan'
app = require './sns'
request = require 'request'

# Config
port = process.env.PORT or 3002
autoReconnect = false                 # Automatically reconnect after an error response from Slack.
autoMark = true                       # Automatically mark each message as read after it is processed.
slackServiceOpts =
  method: 'POST'
  json: true
  uri: secrets.SLACK_INCOMING_WEB_HOOK

log = bunyan.createLogger
  name: 'sns-slack-notifier'
  level: process.env.LOG_LEVEL or 'info'
  serializers:
    req: bunyan.stdSerializers.req,
    res: bunyan.stdSerializers.res


handler = (req, res) ->
  log.info "handler called for #{req.url}"
  if req.url is '/ping'
    msg = _.cloneDeep(slackServiceOpts)
    msg.body =  text: 'ping message'

    request(msg, (e, resp, respBody) ->
      log.info "message sent",e, respBody
      res.writeHead(resp.statusCode, {
        'Content-Type': 'text/plain'
      });
      res.end('Pong')
    )

  else
    res.writeHead(404)
    res.end('Not Found')


log.info "start server"

server = http.createServer(handler)
server.listen(port, ->
  log.info "Secure Listener on port: #{port}")
