module.exports =
  extend: (object, properties) ->
    for key, val of properties
      object[key] = val
    object
  
  getRandomInt: (min, max) ->
    Math.floor(Math.random() * (max - min + 1)) + min

  # Get a random number string.
  getRandomNumber: ->
    @getRandomInt 0, 0x7fffffff