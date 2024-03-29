// Generated by CoffeeScript 1.3.3
(function() {
  var Express, GAPixel, app, createGALink;

  Express = require('express');

  GAPixel = require('gapixel');

  app = Express();

  app.use(Express.logger({
    format: ':method :url'
  }));

  app.use(GAPixel.expressClient());

  createGALink = function(req, res) {
    return res.end('<a href="' + GAPixel.googleAnalyticsGetImageUrl() + '">Link to GIF</a>');
  };

  app.get('/', createGALink);

  app.listen(9010);

}).call(this);
