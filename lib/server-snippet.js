// Generated by CoffeeScript 1.3.3
(function() {
  var Express, GAPixel, app;

  Express = require('express');

  GAPixel = require('gapixel');

  app = Express();

  app.use(Express.logger({
    format: ':method :url'
  }));

  app.get('/px.gif', GAPixel.expressServer());

  app.listen(9009);

}).call(this);
