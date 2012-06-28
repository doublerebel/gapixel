Express = require('express')
NodeGA = require('./node-ga')

app = Express.createServer()
app.use Express.logger format: ':method :url'
app.use NodeGA.expressClient()

createGALink = (req, res) ->
  res.end '<a href="' + NodeGA.googleAnalyticsGetImageUrl() + '">Link to GIF</a>'

app.get '/', createGALink

app.listen 9010
    