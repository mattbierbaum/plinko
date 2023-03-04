import observers

# =================================================================
type
    JsImageRecorder* = ref object of ImageRecorder

method close*(self: JsImageRecorder): void =
    return

# =================================================================
type
    JsSVGLinePlot* = ref object of SVGLinePlot

method close*(self: JsSVGLinePlot): void =
    return
