Express = require 'express'
GAPixel = require 'gapixel'

app = Express.createServer()
app.use Express.logger format: ':method :url'
app.use GAPixel.expressClient()

createGALink = (req, res) ->
  res.end '<a href="' + GAPixel.googleAnalyticsGetImageUrl() + '">Link to GIF</a>'

app.get '/', createGALink

app.listen 9010
    