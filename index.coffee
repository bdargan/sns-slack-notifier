'use strict'
secrets = require './secrets'
http = require 'http'
bunyan = require 'bunyan'
app = require './sns'

port = process.env.PORT or 3002

log = bunyan.createLogger
  name: 'sns-slack-notifier'
  level: process.env.LOG_LEVEL or 'info'
  serializers:
    req: bunyan.stdSerializers.req,
    res: bunyan.stdSerializers.res


handler = (req, res) ->
  log.info "handler called for #{req.url}"
  res.writeHead(200, {
    'Content-Type': 'text/plain'
  });
  res.end('Hello HTTP!');


log.info "start server"

server = http.createServer(handler)
server.listen(port, ->
  log.info "Secure Listener on port: #{port}")
