addEventListener "load", ->
  canvas = document.querySelector "canvas"
  img = document.querySelector "img"
  textarea = document.querySelector "textarea"

  context = canvas.getContext "2d"
  context.drawImage img, 0, 0

  data = context.getImageData(0, 0, parseInt(canvas.getAttribute("width"), 10), parseInt(canvas.getAttribute("height"), 10)).data

  collision = []
  width = parseInt img.getAttribute "width", 10

  i = 0; while i < data.length
    pixel = Math.floor(i / 4)
    y = Math.floor(pixel / width)
    x = pixel - (y * width)
    collision[y] = [] if x == 0
    collision[y][x] = data[i] == 255 # [data[i], data[i + 1], data[i + 2]]
    i += 4

  collisionText = ""
  _.each collision, (row) ->
    _.each row, (cell) ->
      collisionText += if cell then 1 else 0
    collisionText += "\n"

  textarea.innerText = collisionText
