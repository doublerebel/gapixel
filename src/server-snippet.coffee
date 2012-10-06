Express = require('express')
GAPixel = require('./gapixel')

app = Express.createServer()
app.use Express.logger format: ':method :url'
app.get '/', GAPixel.expressServer()

app.listen 9009
    