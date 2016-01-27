'use strict'
secrets = require './secrets'
http = require 'http'
bunyan = require 'bunyan'
app = require './sns'
Slack = require 'slack-client'

# Config
port = process.env.PORT or 3002
autoReconnect = false                 # Automatically reconnect after an error response from Slack.
autoMark = true                       # Automatically mark each message as read after it is processed.


log = bunyan.createLogger
  name: 'sns-slack-notifier'
  level: process.env.LOG_LEVEL or 'info'
  serializers:
    req: bunyan.stdSerializers.req,
    res: bunyan.stdSerializers.res


handler = (req, res) ->
  log.info "handler called for #{req.url}"
  if req.url is '/ping'
    slack.
    res.writeHead(200, {
      'Content-Type': 'text/plain'
    });
    res.end('Pong')
  else
    res.writeHead(404)
    res.end('Not Found')


log.info "start server"

server = http.createServer(handler)
server.listen(port, ->
  log.info "Secure Listener on port: #{port}")
