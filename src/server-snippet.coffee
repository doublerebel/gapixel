Express = require 'express'
GAPixel = require 'gapixel'

app = Express()
app.use Express.logger format: ':method :url'
app.get '/px.gif', GAPixel.expressServer()

app.listen 9009
    