el =
  viewport: null
  map: null
  land: null
  player: null
dim =
  tile:
    w: 16
    h: 16
    factor: 1
  viewport:
    w: 160
    h: 128
    tileW: 10
    tileH: 8
location = null # { x: 0, y: 0 }
viewportLocation = null # { x: 0, y: 0 }
intent = {}
collision = []
lastUpdate = 0
interval = 100
userId = null

addEventListener "load", ->
  el.viewport = document.querySelector "#viewport"
  el.map = document.querySelector "#map"
  el.land = document.querySelector "#land"
  el.collision = document.querySelector "#collision"

  # loadCollision()

  el.viewport.style.width = window.innerWidth / 2 + "px"
  el.viewport.style.height = window.innerWidth / 2 / dim.viewport.width / dim.viewport.height + "px"
  el.viewport.style.margin = "#{ parseInt(el.viewport.style.height, 10) / -2 }px #{ parseInt(el.viewport.style.width, 10) / -2 }px"

  dim.tile.factor = parseInt(el.viewport.style.width, 10) / dim.viewport.w

  el.map.setAttribute "width", parseInt(el.map.offsetWidth, 10) * dim.tile.factor
  el.map.setAttribute "height", parseInt(el.map.offsetHeight, 10) * dim.tile.factor

  el.land.setAttribute "width", el.map.getAttribute "width"
  el.land.setAttribute "height", el.map.getAttribute "height"

  # el.collision.setAttribute "width", el.land.getAttribute "width"
  # el.collision.setAttribute "height", el.land.getAttribute "height"

  # if window.localStorage and window.localStorage.userId
  #   userId = window.localStorage.userId

  sendUpdate()

loadCollision = ->
  collisionCanvas = document.createElement "canvas"
  collisionCanvas.setAttribute "width", parseInt el.collision.getAttribute "width", 10
  collisionCanvas.setAttribute "height", parseInt el.collision.getAttribute "height", 10
  collisionContext = collisionCanvas.getContext "2d"
  collisionContext.drawImage el.collision, 0, 0

  el.collision.parentNode.removeChild el.collision

  collisionData = collisionContext.getImageData(0, 0, parseInt(collisionCanvas.getAttribute("width"), 10), parseInt(collisionCanvas.getAttribute("height"), 10)).data

  collision = []
  collWidth = parseInt el.collision.getAttribute "width", 10

  i = 0; while i < collisionData.length
    pixel = Math.floor(i / 4)
    y = Math.floor(pixel / collWidth)
    x = pixel - (y * collWidth)
    collision[y] = [] if x == 0
    collision[y][x] = [collisionData[i], collisionData[i + 1], collisionData[i + 2]]
    i += 4

setViewport = (viewport) ->
  el.map.style.left = -1 * viewport.x * dim.tile.w * dim.tile.factor + "px"
  el.map.style.top = -1 * viewport.y * dim.tile.h * dim.tile.factor + "px"

sendUpdate = ->
  lastUpdate = (new Date()).valueOf()
  xhr = new XMLHttpRequest()
  xhr.open 'POST', '/', true
  xhr.responseType = 'text'
  xhr.onload = (e) ->
    # if @status == 200
    receiveUpdate lastUpdate, JSON.parse @response

  data = new FormData()
  data.append "id", userId if userId
  data.append("intent[x]", intent.x) if intent.hasOwnProperty "x"
  data.append("intent[y]", intent.y) if intent.hasOwnProperty "y"

  xhr.send data

receiveUpdate = (lastUpdate, response) ->
  if userId != response.id
    userId = response.id
    if window.localStorage
      window.localStorage.userId = userId

  setEntities response.entities
  setViewport response.viewport

  remainder = interval - ((new Date()).valueOf() - lastUpdate)
  if remainder <= 0
    sendUpdate()
  else
    setTimeout sendUpdate, remainder

getPlayerEl = (id) ->
  playerEl = document.querySelector "#player-#{ id }"

  unless playerEl
    # <img id="player" src="bomb-mario.png" width="16" height="16">
    playerEl = document.createElement "img"
    playerEl.setAttribute "id", "player-#{ id }"
    playerEl.setAttribute "width", dim.tile.w * dim.tile.factor
    playerEl.setAttribute "height", dim.tile.h * dim.tile.factor
    playerEl.setAttribute "src", "bomb-mario.png"
    playerEl.setAttribute "class", "player"
    playerEl.setAttribute "style", "-webkit-filter: hue-rotate(" + (parseInt(id, 16) % 360) + "deg)"      
    el.map.appendChild playerEl

  playerEl

setEntities = (entities) ->
  _.each entities, (entity) ->
    playerEl = getPlayerEl entity.id
    playerEl.style.left = entity.x * dim.tile.w * dim.tile.factor + "px"
    playerEl.style.top = entity.y * dim.tile.w * dim.tile.factor + "px"

addEventListener "keydown", (e) ->
  switch e.which
    when 37 # left
      intent.x = -1
      delete intent.y
    when 38 # up
      intent.y = -1
      delete intent.x
    when 39 # right
      intent.x = 1
      delete intent.y
    when 40 # down
      intent.y = 1
      delete intent.x

addEventListener "keyup", (e) ->
  switch e.which
    when 37 # left
      delete intent.x
    when 38 # up
      delete intent.y
    when 39 # right
      delete intent.x
    when 40 # down
      delete intent.y
