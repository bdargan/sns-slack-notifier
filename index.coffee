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
  if req.url is '/ping'
    res.writeHead(200, {
      'Content-Type': 'text/plain'
    });
    res.end('Pong')
  else
    res.writeHead(404)
    res.end('Not Found')


log.info "initialize slack connection"

autoReconnect = true # Automatically reconnect after an error response from Slack.
autoMark = true # Automatically mark each message as read after it is processed.

slack = new Slack(slackToken, autoReconnect, autoMark)

slack.on 'open', ->
    console.log "Connected to #{slack.team.name} as @#{slack.self.name}"

slack.on 'message', (message) ->
    console.log message

slack.on 'error', (err) ->
    console.error "Error", err

slack.login()

log.info "start server"

server = http.createServer(handler)
server.listen(port, ->
  log.info "Secure Listener on port: #{port}")
