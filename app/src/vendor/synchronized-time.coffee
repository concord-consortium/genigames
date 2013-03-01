##
## Simple library for generating Date objects synchronized to a server's clock.
##
## Path can be anything, but should return the server's UTC in milliseconds.
##

class window.SyncTime
  drift: 0
  ready: false
  constructor: (path = '/time')->
    nowUTC = ->
      d = new Date()
      utc = new Date d.getUTCFullYear(),
                     d.getUTCMonth(),
                     d.getUTCDate(),
                     d.getUTCHours(),
                     d.getUTCMinutes(),
                     d.getUTCSeconds(),
                     d.getUTCMilliseconds()
      utc.getTime()

    reqStart = nowUTC()
    req = new XMLHttpRequest()
    req.onreadystatechange = (evt)=>
      if req.readyState == 4 && req.status == 200
        reqEnd = nowUTC()
        # naively assume one-way transport time is
        # half the round-trip time
        reqDrift = (reqEnd - reqStart)/2
        serverTime = req.responseText
        @drift = serverTime - reqEnd + reqDrift
        @ready = true
    req.open("GET", path, true)
    req.send(null)

  now: ->
    new Date((new Date()).getTime() + @drift)
