canvas =  document.getElementById("canvas");
var ctx = canvas.getContext('2d')
ctx.canvas.width  = window.innerWidth;
ctx.canvas.height = window.innerHeight;

factor = 1.5 // how much to scale between zoom levels
zoom = 1.0

// tileWidth = 1 // how much of the complex plane spanned by one tile
// tiles = [[0, 0, "12"], [0, 1.0, "7"], [1.0, 0, "13"], [0, -1.0, "17"], [-1.0, 0, "11"], [0, 2.0, "14"], [1.0, 1.0, "8"], [2.0, 0], [1.0, -1.0], [0, -2.0], [-1.0, -1.0, "16"], [-1.0, 1.0, "6"], [-2.0, 0, "10"]]
tiles = [
    [0.0,0.0, '12'],
    [0.0,1.0,'7'], [1.0,0.0,'13'], [0.0,-1.0,'17'], [-1.0,0.0,'11'],
    [0.0,2.0,'14'], [1.0,1.0,'8'], [2.0,0.0], [1.0,-1.0], [0.0,-2.0], [-1.0,-1.0,'16'], [-2.0,0.0,'10'], [-1.0,1.0,'6'],
    [0.0,3.0], [1.0,2.0], [2.0,1.0], [3.0,0.0], [2.0,-1.0], [1.0,-2.0], [0.0,-3.0], [-1.0,-2.0], [-2.0,-1.0], [-3.0,0.0], [-2.0,1.0], [-1.0,2.0]
]
layer_2 = [[0.25, 0.25, "layer_2", 2]]
layer_3 = [[-0.625, 0.625, "3_0", 3], [-0.375, 0.625, "3_1", 3]]
// Camera Offset
// todo this should change when the user pans left/right/up/down
offsetX = canvas.width / 2
offsetY = canvas.height / 2


panY = 0
panX = 0

// Something about scale
baseScale = 200.0

baseTileSize = 200


function layerAtZoom(z) {
    // log (base-2) of zoom
    return Math.floor(Math.log(z) / Math.log(2)) + 1;
}
function currentLayer() {
    return layerAtZoom(zoom);
}

function tileSizeAtLayer(layer) {
    return baseTileSize * Math.pow(0.5, layer - 1)
}

function coordAtMouse(mouseX, mouseY) {
    scale = baseScale * zoom
    // console.log("Complex Pixel: (" + (mouseX - offsetX) + ", " + (mouseY - offsetY) + ")");
    x = (mouseX - offsetX - zoom * panX) / scale
    y = (mouseY - offsetY - zoom * panY) * -1 / scale
    return [x, y]
}


function draw() {
    clearCanvas()

    width = window.innerWidth;
    height = window.innerHeight;

    //    call drawTile() on each elem of tiles
    for (i=0;i<tiles.length;i++) {
        if (tiles[i][2])
            paintTile(tiles[i]);
        drawTile(tiles[i]);
    }
    for (i=0;i<layer_2.length;i++) {
        if (layer_2[i][2])
            paintTile(layer_2[i]);
        drawTile(layer_2[i]);
    }
    for (i=0;i<layer_3.length;i++) {
        if (layer_3[i][2])
            paintTile(layer_3[i]);
        drawTile(layer_3[i]);
    }
}

function drawTile(tile) {
    src = tile[2];
    xPos = tile[0];
    yPos = tile[1];
    layer = tile[3] ? tile[3] : 1
    tileSize = tileSizeAtLayer(layer)

    ctx.strokeStyle = "#444"
    ctx.beginPath();
    ctx.lineWidth = 0.25;
    x = (width / 2 - tileSize / 2) + xPos * baseScale
    y = (height / 2 - tileSize / 2) - yPos * baseScale
    ctx.rect(x, y, tileSize, tileSize);
    ctx.stroke();
}
function paintTile(tile) {
    src = tile[2];
    xPos = tile[0];
    yPos = tile[1];
    layer = tile[3] ? tile[3] : 1
    tileSize = tileSizeAtLayer(layer)

    x = (width / 2 - tileSize / 2) + xPos * baseScale
    y = (height / 2 - tileSize / 2) - yPos * baseScale

    var img = document.getElementById(tile[2]);
    ctx.drawImage(img, x, y, tileSize, tileSize)
}

function printZoom() {
    document.getElementById('zoomFactor').textContent = zoom.toFixed(3);
    document.getElementById('currentLayer').textContent = currentLayer();
}

function zoomIn() {
    max = 64.0
    // prevent zooming in too much
    if (zoom >= max)
        return false;
    zoom *= factor;

    printZoom();
    printPan();

    offset = [offsetX - panX, offsetY - panY]
    console.log("Using offset: " + offset);

    x = offset[0]
    y = offset[1]
    ctx.translate(x, y);
    ctx.scale(factor, factor);
    // reverse translate to zoom point
    ctx.translate(-x, -y);
    draw();
}
function zoomOut() {
    min = 0.25
    // prevent zooming out too much
    if (zoom <= min)
        return false;
    zoom /= factor;
    // panX /= factor;
    // panY /= factor;
    printZoom();
    printPan();

    offset = [offsetX - panX, offsetY - panY]
    console.log("Using offset: " + offset);

    x = offset[0]
    y = offset[1]
    ctx.translate(x, y);
    ctx.scale(1 / factor, 1 / factor);
    ctx.translate(-x, -y);
    draw();
}
function zoomReset() {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    panX = 0
    panY = 0
    printPan();
    zoom = 1.0
    printZoom();
    draw();
}

// Zoom In on Mouse Position
function zoomInMouse() {
    max = 64.0
    // prevent zooming in too much
    if (zoom >= max)
        return false;
    zoom *= factor;

    printZoom();


    mouseX = parseInt(document.getElementById("mouseX").innerText)
    mouseY = parseInt(document.getElementById("mouseY").innerText)

    currentPan = [panX, panY]

    // distance from center of canvas to mouse
    deltaX = offsetX - mouseX
    deltaY = offsetY - mouseY
    deltaPanX = deltaX / zoom
    deltaPanY = deltaY / zoom

    // calculate as if panning to mouse position
    mousePanX = panX - deltaPanX
    mousePanY = panY - deltaPanY

    // instead pan 1/3 towards mouse pan position (half the inverse of the zoom factor (1.5))
    // wtf this is wrong

    newPanX = (1.0 * panX + mousePanX) / 2.0
    newPanY = (1.0 * panY + mousePanY) / 2.0

    xChange = panX - newPanX
    yChange = panY - newPanY
    ctx.translate(xChange, yChange)

    panX += xChange
    panY += yChange

    zoomIn()
    // console.log(mouseX + "," + mouseY)
    // offset = [mouseX - panX, mouseY - panY]
    // // offset = [mouseX, mouseY]
    // console.log("Using offset: " + offset);
    //
    // x = offset[0]
    // y = offset[1]
    // ctx.translate(x, y);
    // ctx.scale(factor, factor);
    // ctx.translate(-x, -y);


    // debugger;
    // panX = panX + deltaPanX
    // panY = panY + deltaPanY
    // printPan();
    //
    // draw();
}

function resetCanvas() {
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    draw();
}

function clearCanvas() {
    // Store the current transformation matrix
    ctx.save();
    // Use the identity matrix while clearing the canvas
    ctx.setTransform(1, 0, 0, 1, 0, 0);
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    // Restore the transform
    ctx.restore();
}

// Display Mouse (x,y) position and Complex (ax+bi) Coordinates
canvas.addEventListener('mousemove', e => {
    var e = window.event;

    var posX = e.clientX;
    var posY = e.clientY;

    document.getElementById('mouseX').innerText = posX;
    document.getElementById('mouseY').innerText = posY;

    precision = 4
    coord = coordAtMouse(posX, posY);
    document.getElementById('coordX').innerText = coord[0].toFixed(precision);
    document.getElementById('coordY').innerText = coord[1].toFixed(precision);

})
// Trigger zoom with scroll wheel
canvas.addEventListener('wheel', e => {
    var e = window.event;

    if (event.deltaY < 0)
        zoomIn();
    // zoomInMouse();
    else
        zoomOut();
})

function panInterval() {
    return 100.0 / zoom;
}

function pan(deltaX, deltaY) {
    panX += deltaX;
    panY += deltaY;
    ctx.translate(deltaX, deltaY);
    printPan();
    draw();
}
function panUp() {
    pan(0, panInterval());
}
function panRight() {
    pan(-panInterval(), 0);
}
function panDown() {
    pan(0, -panInterval());
}
function panLeft() {
    pan(panInterval(), 0);
}

function printPan() {
    document.getElementById('panX').innerText = panX.toFixed(0);
    document.getElementById('panY').innerText = -panY.toFixed(0);
}
// Pan with keyboard
window.addEventListener('keydown', e => {
    var e = window.event;
    switch (e.code) {
        case "KeyW":
        case "ArrowUp":
            panUp();
            break;
        case "KeyA":
        case "ArrowLeft":
            panLeft();
            break;
        case "KeyS":
        case "ArrowDown":
            panDown();
            break;
        case "KeyD":
        case "ArrowRight":
            panRight();
            break;
    }
})

draw();
window.setTimeout(function(){
    draw();
}, 25);
