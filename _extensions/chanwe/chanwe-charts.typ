// =============================================================
// chanwe-charts.typ — reusable data-viz primitives
// All components consume _t tokens — no hardcoded colors.
// =============================================================

// ---- BAR CHART ----------------------------------------------
// data: array of (label, value) tuples, value ∈ [0, 1]
// threshold: bars at or above this value get full opacity
// label-color: auto resolves to _t.fg-subtle
#let chanwe-bar-chart(
  data,
  height:      50mm,
  bar-width:   18mm,
  gap:         5mm,
  label-size:  7.5pt,
  label-color: auto,
  threshold:   0.7,
) = {
  let lc = if label-color == auto { _t.fg-subtle } else { label-color }
  align(center,
    stack(dir: ltr, spacing: gap,
      ..data.map(((lbl, val)) =>
        stack(dir: ttb, spacing: 2mm,
          rect(width: bar-width, height: height * (1 - val), fill: none, stroke: none),
          rect(
            width: bar-width,
            height: height * val,
            fill: _t.primary.transparentize(if val >= threshold { 10% } else { 45% }),
            stroke: none,
            radius: 1.5pt,
          ),
          align(center, text(size: label-size, fill: lc, lbl)),
        )
      ),
    )
  )
}

// ---- LINE CHART ---------------------------------------------
// series: array of (label, values-array) — all series same length
// x-labels: array of strings for x-axis ticks
#let chanwe-line-chart(
  series,
  x-labels:    (),
  width:       120mm,
  height:      60mm,
  label-size:  7pt,
  y-min:       0,
  y-max:       1,
  colors:      auto,
) = {
  let palette = if colors == auto {
    (_t.primary, _t.fg-muted, _t.neutral-700, _t.fg-subtle)
  } else { colors }
  let n = if series.len() > 0 { series.first().at(1).len() } else { 0 }
  if n == 0 { return [] }
  let x-step = if n > 1 { width / (n - 1) } else { width }
  let y-range = y-max - y-min

  block(width: width, height: height + 10mm)[
    #place(top + left,
      rect(width: width, height: height,
        fill: none, stroke: 0.5pt + _t.border)
    )
    #for (si, (name, vals)) in series.enumerate() {
      let col = palette.at(calc.rem(si, palette.len()))
      for i in range(vals.len() - 1) {
        let x1 = x-step * i
        let y1 = height * (1 - (vals.at(i) - y-min) / y-range)
        let x2 = x-step * (i + 1)
        let y2 = height * (1 - (vals.at(i + 1) - y-min) / y-range)
        place(top + left, dx: x1, dy: y1,
          line(end: (x2 - x1, y2 - y1), stroke: 1.5pt + col))
      }
    }
    #if x-labels.len() > 0 {
      place(bottom + left, dy: 8mm,
        stack(dir: ltr,
          ..x-labels.enumerate().map(((i, lbl)) =>
            move(dx: x-step * i,
              align(center, text(size: label-size, fill: _t.fg-subtle, lbl)))
          )
        )
      )
    }
  ]
}
