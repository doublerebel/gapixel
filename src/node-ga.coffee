#  Copyright 2009 Google Inc. All Rights Reserved.
#  Coffeescript translation 2012 Charles Phillips

http = require('http')
Crypto = require('crypto')
Cookies = require('cookies')
UUID = require('node-uuid')
Utils = require('./node-ga-utils')


# Tracker version.
VERSION = "4.4sh"
COOKIE_NAME = "__utmmobile"

#address of GA UTM GIF
UTM_GIF_LOCATION = "www.google-analytics.com/__utm.gif"

# 1x1 transparent GIF
GIF_DATA = [
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61,
    0x01, 0x00, 0x01, 0x00, 0x80, 0xff,
    0x00, 0xff, 0xff, 0xff, 0x00, 0x00,
    0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x01, 0x00, 0x00, 0x02,
    0x02, 0x44, 0x01, 0x00, 0x3b
].map String.fromCharCode


class NodeGA

  constructor: (@req, @res, @options) ->
    @trackPageView()

  getIP: (remoteAddress) ->
    return unless remoteAddress
    # The last octect of the IP address is removed to anonymize the user.
    # Capture the first three octects of the IP address and replace the forth
    # with 0, e.g. 124.455.3.123 becomes 124.455.3.0
    anonip = /^([^.]+\.[^.]+\.[^.]+\.).*/.exec remoteAddress
    anonip[1] and anonip[1] + "0" or ""

  # Generate a visitor id for this hit.
  # If there is a visitor id in the cookie, use that, otherwise
  # use the guid if we have one, otherwise use a random number.
  getVisitorId: (guid, account, userAgent) ->
    message = if guid then guid + account else userAgent + UUID.v4()
    md5sum = Crypto.createHash 'md5'
    md5sum.update message
    md5String = md5sum.digest 'hex'
    "0x" + md5String.substr 0, 16

  # Writes the bytes of a 1x1 transparent gif into the @response.
  writeGifData: ->
    @res.header "content-type", "image/gif"
    @res.header "cache-control", "private, no-cache, no-cache=Set-Cookie, proxy-revalidate"
    @res.header "pragma", "no-cache"
    @res.header "expires", "Wed, 17 Sep 1975 21:32:10 GMT"
    @res.end GIF_DATA.join()

  # Make a tracking @request to Google Analytics from this server.
  # Copies the headers from the original request to the new one.
  # If request containg utmdebug parameter, exceptions encountered
  # communicating with Google Analytics are thrown.
  sendRequestToGoogleAnalytics: (utmUrl) ->
    options =
      host: utmUrl.split('/')[0]
      path: utmUrl.split('/')[1]
      method: "GET"
      headers:
        user_agent: @req.headers["user-agent"]
        accept_language: @req.headers["accept-language"]
    
    gareq = http.request options
    if @req.query["utmdebug"]
      gareq.on 'error', (e) ->
        console.log('problem with request: ' + e.message)

    gareq.end()
    
  # Track a page view, updates all the cookies and campaign tracker,
  # makes a server side @request to Google Analytics and writes the transparent
  # gif byte data to the @response.
  trackPageView: ->
    timeStamp = new Date().getTime()
    domainName = @req.headers["server-name"] or ""

    # Get the referrer from the utmr parameter, this is the referrer to the
    # page that contains the tracking pixel, not the referrer for tracking
    # pixel.
    documentReferer = @req.query["utmr"] or ""
    documentPath = @req.query["utmp"] or ""
    
    account = @req.query["utmac"]
    
    # Try and get visitor cookie from the @request.
    cookies = new Cookies(@req, @res)
    visitorId = cookies.get COOKIE_NAME

    if not visitorId
      guidHeader = @req.headers["x-dcmguid"] or
                   @req.headers["x-up-subno"] or
                   @req.headers["x-jphone-uid"] or
                   @req.headers["x-em-uid"]
      userAgent = @req.headers["user-agent"] or ""
      visitorId = @getVisitorId guidHeader, account, userAgent

    # Always try and add the cookie to the @response.
    cookies.set COOKIE_NAME, visitorId,
        expires: new Date(timeStamp + @options.cookiePersistence)
        path: @options.cookiePath

    # Construct the gif hit url.
    utmUrl = UTM_GIF_LOCATION + "?" +
        "utmwv=" + VERSION +
        "&utmn=" + Utils.getRandomNumber() +
        "&utmhn=" + domainName +
        "&utmr=" + documentReferer +
        "&utmp=" + documentPath +
        "&utmac=" + account +
        "&utmcc=__utma%3D999+999+999+999+999+1%3B" +
        "&utmvid=" + visitorId +
        "&utmip=" + @getIP @req.headers["remote-addr"]

    @sendRequestToGoogleAnalytics utmUrl

    # If the debug parameter is on, add a header to the response that contains
    # the url that was used to contact Google Analytics.
    if @req.query["utmdebug"] then @res.header "x-ga-mobile-url", utmUrl
    # Finally write the gif data to the response.
    @writeGifData()


NodeGA.expressServer = (options) ->
  options = Utils.extend {
    cookiePath: '/' # The path to which the cookie will be available.
    cookiePersistence: 63072000 # Two years in seconds.
    }, options

  (req, res, next) ->
    req.app.use Cookies.express()
    new NodeGA(req, res, options)
    # next()

NodeGA.expressClient = ->
  (@req, res, next) =>
    next()
    
NodeGA.googleAnalyticsGetImageUrl = (GA_ACCOUNT = "ACCOUNT ID GOES HERE", GA_PIXEL = "ga.js") ->
  url = GA_PIXEL + "?" +
        "utmac=" + GA_ACCOUNT +
        "&utmn=" + Utils.getRandomNumber()

  referer = @req.headers["referer"] or "-"
  query = @req.query
  path = @req.url

  url += "&utmr=" + encodeURIComponent referer
  if path then url += "&utmp=" + encodeURIComponent path
  url += "&guid=ON"


module.exports = NodeGA