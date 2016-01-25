# sns-slack-notifier

AWS SNS Slack Notifier.

If you live in a region with AWS Lambda then there are easier ways to integrate. See the various blog articles, or AWS Lambda Slack integration blueprint.

## Assumptions
1. you are running behind a webserver, with https and authentication

## Config
1. cp secrets-default.coffee secrets.coffee file.
1. Add your SLACK_TOKEN

## Test

### test locally
1. curl localhost:3002/ping

### deploy to web server
1. in AWS console
...




