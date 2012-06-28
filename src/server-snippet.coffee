Express = require('express')
NodeGA = require('./node-ga')

app = Express.createServer()
app.use Express.logger format: ':method :url'
app.get '/', NodeGA.expressServer()

app.listen 9009
    