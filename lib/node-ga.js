(function() {
  var COOKIE_NAME, Cookies, Crypto, GIF_DATA, NodeGA, UTM_GIF_LOCATION, UUID, Utils, VERSION, http;

  http = require('http');

  Crypto = require('crypto');

  Cookies = require('cookies');

  UUID = require('node-uuid');

  Utils = require('./node-ga-utils');

  VERSION = "4.4sh";

  COOKIE_NAME = "__utmmobile";

  UTM_GIF_LOCATION = "www.google-analytics.com/__utm.gif";

  GIF_DATA = ['\x47', '\x49', '\x46', '\x38', '\x39', '\x61', '\x01', '\x00', '\x01', '\x00', '\x80', '\xff', '\x00', '\xff', '\xff', '\xff', '\x00', '\x00', '\x00', '\x2c', '\x00', '\x00', '\x00', '\x00', '\x01', '\x00', '\x01', '\x00', '\x00', '\x02', '\x02', '\x44', '\x01', '\x00', '\x3b'];

  NodeGA = (function() {

    function NodeGA(req, res, options) {
      this.req = req;
      this.res = res;
      this.options = options;
      this.trackPageView();
    }

    NodeGA.prototype.getIP = function(remoteAddress) {
      var anonip;
      if (!remoteAddress) return;
      anonip = /^([^.]+\.[^.]+\.[^.]+\.).*/.exec(remoteAddress);
      return anonip[1] && anonip[1] + "0" || "";
    };

    NodeGA.prototype.getVisitorId = function(guid, account, userAgent) {
      var md5String, md5sum, message;
      message = guid ? guid + account : userAgent + UUID.v4();
      md5sum = Crypto.createHash('md5');
      md5sum.update(message);
      md5String = md5sum.digest('hex');
      return "0x" + md5String.substr(0, 16);
    };

    NodeGA.prototype.writeGifData = function() {
      this.res.header("content-type", "image/gif");
      this.res.header("cache-control", "private, no-cache, no-cache=Set-Cookie, proxy-revalidate");
      this.res.header("pragma", "no-cache");
      this.res.header("expires", "Wed, 17 Sep 1975 21:32:10 GMT");
      return this.res.end(GIF_DATA.join(''), 'binary');
    };

    NodeGA.prototype.sendRequestToGoogleAnalytics = function(utmUrl) {
      var gareq, options;
      options = {
        host: utmUrl.split('/')[0],
        path: utmUrl.split('/')[1],
        method: "GET",
        headers: {
          user_agent: this.req.headers["user-agent"],
          accept_language: this.req.headers["accept-language"]
        }
      };
      gareq = http.request(options);
      if (this.req.query["utmdebug"]) {
        gareq.on('error', function(e) {
          return console.log('problem with request: ' + e.message);
        });
      }
      return gareq.end();
    };

    NodeGA.prototype.trackPageView = function() {
      var account, cookies, documentPath, documentReferer, domainName, guidHeader, timeStamp, userAgent, utmUrl, visitorId;
      timeStamp = new Date().getTime();
      domainName = this.req.headers["server-name"] || "";
      documentReferer = this.req.query["utmr"] || "";
      documentPath = this.req.query["utmp"] || "";
      account = this.req.query["utmac"];
      cookies = new Cookies(this.req, this.res);
      visitorId = cookies.get(COOKIE_NAME);
      if (!visitorId) {
        guidHeader = this.req.headers["x-dcmguid"] || this.req.headers["x-up-subno"] || this.req.headers["x-jphone-uid"] || this.req.headers["x-em-uid"];
        userAgent = this.req.headers["user-agent"] || "";
        visitorId = this.getVisitorId(guidHeader, account, userAgent);
      }
      cookies.set(COOKIE_NAME, visitorId, {
        expires: new Date(timeStamp + this.options.cookiePersistence),
        path: this.options.cookiePath
      });
      utmUrl = UTM_GIF_LOCATION + "?" + "utmwv=" + VERSION + "&utmn=" + Utils.getRandomNumber() + "&utmhn=" + domainName + "&utmr=" + documentReferer + "&utmp=" + documentPath + "&utmac=" + account + "&utmcc=__utma%3D999+999+999+999+999+1%3B" + "&utmvid=" + visitorId + "&utmip=" + this.getIP(this.req.headers["remote-addr"]);
      this.sendRequestToGoogleAnalytics(utmUrl);
      if (this.req.query["utmdebug"]) this.res.header("x-ga-mobile-url", utmUrl);
      return this.writeGifData();
    };

    return NodeGA;

  })();

  NodeGA.expressServer = function(options) {
    options = Utils.extend({
      cookiePath: '/',
      cookiePersistence: 63072000
    }, options);
    return function(req, res, next) {
      req.app.use(Cookies.express());
      return new NodeGA(req, res, options);
    };
  };

  NodeGA.expressClient = function() {
    var _this = this;
    return function(req, res, next) {
      _this.req = req;
      return next();
    };
  };

  NodeGA.googleAnalyticsGetImageUrl = function(GA_ACCOUNT, GA_PIXEL) {
    var path, query, referer, url;
    if (GA_ACCOUNT == null) GA_ACCOUNT = "ACCOUNT ID GOES HERE";
    if (GA_PIXEL == null) GA_PIXEL = "ga.js";
    url = GA_PIXEL + "?" + "utmac=" + GA_ACCOUNT + "&utmn=" + Utils.getRandomNumber();
    referer = this.req.headers["referer"] || "-";
    query = this.req.query;
    path = this.req.url;
    url += "&utmr=" + encodeURIComponent(referer);
    if (path) url += "&utmp=" + encodeURIComponent(path);
    return url += "&guid=ON";
  };

  module.exports = NodeGA;

}).call(this);
