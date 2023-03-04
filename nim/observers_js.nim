import observers
import plotting

import std/dom
import std/strformat

type
    ImageData* = ref ImageDataObj
    ImageDataObj {.importc.} = object
        width*: int
        height*: int
        data*: seq[uint8]

type
    Canvas* = ref CanvasObj
    CanvasObj {.importc.} = object of dom.Element

    CanvasContext2d* = ref CanvasContext2dObj
    CanvasContext2dObj {.importc.} = object
        font*: cstring

proc getContext2d*(c: Canvas): CanvasContext2d =
    {.emit: "`result` = `c`.getContext('2d');".}

proc width*(c: Canvas): int =
    {.emit: "`result` = `c`.width;".}

proc height*(c: Canvas): int =
    {.emit: "`result` = `c`.height;".}

proc set_width*(c: Canvas, w: int): void = 
    {.emit: "`c`.width = `w`".}

proc set_height*(c: Canvas, h: int): void = 
    {.emit: "`c`.height = `h`".}

proc fillStyle*(ctx: CanvasContext2d, value: string) =
    {.emit: "`ctx`.fillStyle = '`value`';".}

proc fillStyle*(ctx: CanvasContext2d, r, g, b: int) =
    {.emit: "`ctx`.fillStyle = 'rgb(`r`,`g`,`b`)';".}

proc fillStyle*(ctx: CanvasContext2d, r, g, b: float) =
    {.emit: "`ctx`.fillStyle = 'rgb(`r`,`g`,`b`)';".}

proc strokeStyle*(ctx: CanvasContext2d, value: string) =
    {.emit: "`ctx`.strokeStyle = '`value`';".}

proc strokeStyle*(ctx: CanvasContext2d, r, g, b: int) =
    {.emit: "`ctx`.strokeStyle = 'rgb(`r`,`g`,`b`)';".}

proc strokeStyle*(ctx: CanvasContext2d, r, g, b: float) =
    {.emit: "`ctx`.strokeStyle = 'rgb(`r`,`g`,`b`)';".}
  
proc requestAnimationFrame*(op: proc) =
    {.emit: "`ran` = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame; `ran`(`op`);".}

proc toDataURL*(c: Canvas; imageFormat:cstring="image/png"; encoderOptions:float=0.92): cstring {.inline.} =
    {.emit: [result, "=", c, ".toDataURL(", imageFormat, ",", encoderOptions, ");"].}

proc beginPath*(c: CanvasContext2d) {.importcpp.}
proc stroke*(c: CanvasContext2d) {.importcpp.}
proc strokeText*(c: CanvasContext2d, txt: cstring, x, y: float) {.importcpp.}
proc clearRect*(c: CanvasContext2d, x, y, w, h: float) {.importcpp.}
proc fillRect*(ctx: CanvasContext2d, x, y, w, h: float) {.importcpp.}
proc fillRect*(ctx: CanvasContext2d, x, y, w, h: int) {.importcpp.}
proc closePath*(ctx: CanvasContext2d) {.importcpp.}

proc createImageData*(ctx: CanvasContext2D; width, height: int;): ImageData {.importcpp.}
proc createImageData*(ctx: CanvasContext2D; imagedata: ImageData): ImageData {.importcpp.}
proc getImageData*(ctx: CanvasContext2D; sx, sy: float; sw, sh: float;): ImageData {.importcpp.}
proc putImageData*(ctx: CanvasContext2D; imagedata: ImageData; dx, dy: float;) {.importcpp.}
proc putImageData*(ctx: CanvasContext2D; imagedata: ImageData; dx, dy: float; dirtyX, dirtyY: float; dirtyWidth, dirtyHeight: float;) {.importcpp.}

# =================================================================
type
    JsImageRecorder* = ref object of ImageRecorder
        canvas*: Canvas
        h*, w*: int

method set_canvas*(self: Observer, canvas: Canvas): void {.base.} = return

method set_canvas*(self: JsImageRecorder, canvas: Canvas): void =
    self.canvas = canvas
    self.w = self.canvas.width
    self.h = self.canvas.height
    let b = self.plotter.box
    let dpi = min(self.w.float / (b.uu[0] - b.ll[0]), self.h.float / (b.uu[1] - b.ll[1]))
    echo fmt"dpi = {dpi}"
    self.plotter = DensityPlot().initDensityPlot(box=self.plotter.box, dpi=dpi, blendmode=self.plotter.blendmode)

method close*(self: JsImageRecorder): void =
    var ctx = self.canvas.getContext2d()
    var img = ctx.createImageData(self.w, self.h)
    var toned = self.tone().data

    for i, v in toned:
        img.data[4*i+0] = toned[i]
        img.data[4*i+1] = toned[i]
        img.data[4*i+2] = toned[i]
        img.data[4*i+3] = 255
    ctx.putImageData(img, 0.0,0.0)

# =================================================================
type
    JsSVGLinePlot* = ref object of SVGLinePlot

method close*(self: JsSVGLinePlot): void =
    return
