// =============================================================
// chanwe-charts.typ — reusable data-viz primitives
// All components consume _t tokens — no hardcoded colors.
// =============================================================

// ---- BAR CHART ----------------------------------------------
// data: array of (label, value) tuples, value ∈ [0, 1]
// threshold: bars at or above this value get full opacity
// label-color: auto resolves to _t.fg-muted
#let chanwe-bar-chart(
  data,
  height:      50mm,
  bar-width:   18mm,
  gap:         5mm,
  label-size:  7.5pt,
  label-color: auto,
  threshold:   0.7,
) = {
  let lc = if label-color == auto { _t.fg-muted } else { label-color }
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
            // v2 (Q3): bars with the plot's rounded ends.
            radius: chanwe-plot.at("bar-radius") * 0.75pt,
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
  width:       auto,
  height:      60mm,
  label-size:  7pt,
  y-min:       0,
  y-max:       1,
  colors:      auto,
) = {
  // By default the chart takes the width it is given, like a figure.
  if width == auto {
    return layout(s => chanwe-line-chart(series, x-labels: x-labels, width: s.width, height: height,
      label-size: label-size, y-min: y-min, y-max: y-max, colors: colors))
  }
  // The hub's categorical order (tokens.typ `chanwe-plot.categorical`, v2):
  // the accent first, `chart-red` last, away from `primary` (dE00 5.0). Pass
  // `colors:` for a focus chart (orange plus the slate ramp, Q3 C1).
  let palette = if colors == auto {
    chanwe-plot.at("categorical")
  } else { colors }
  let n = if series.len() > 0 { series.first().at(1).len() } else { 0 }
  if n == 0 { return [] }
  let x-step = if n > 1 { width / (n - 1) } else { width }
  let y-range = y-max - y-min

  // v2 chart grammar, the same as chanwer: horizontal slate gridlines only, no
  // frame, round line ends, mono axis labels, a dot legend over the plot.
  // Sin cortar: el gráfico se dibuja con `place` dentro de un bloque de alto
  // fijo, así que partirlo no reparte el contenido —lo deja colgando fuera de
  // la caja de texto—. Si no entra, pasa entero a la página siguiente.
  let named = series.filter(((name, _)) => name != none and name != "")
  block(width: width, breakable: false, below: 6mm)[
    #set block(spacing: 0pt)
    #if named.len() > 0 {
      for (si, (name, _)) in series.enumerate() {
        box(cw-dot(palette.at(calc.rem(si, palette.len()))))
        h(1.4mm)
        text(font: _t.font-mono, size: label-size - 1pt, tracking: 0.08em, fill: _t.fg-muted, upper(name))
        h(4mm)
      }
      v(3mm)
    }
    #block(width: width, height: height + 6mm)[
      #for g in range(5) {
        place(top + left, dy: height * g / 4,
          line(length: width, stroke: 0.5pt + _t.rule))
      }
      #for (si, (name, vals)) in series.enumerate() {
        let col = palette.at(calc.rem(si, palette.len()))
        for i in range(vals.len() - 1) {
          let x1 = x-step * i
          let y1 = height * (1 - (vals.at(i) - y-min) / y-range)
          let x2 = x-step * (i + 1)
          let y2 = height * (1 - (vals.at(i + 1) - y-min) / y-range)
          place(top + left, dx: x1, dy: y1,
            line(end: (x2 - x1, y2 - y1), stroke: (paint: col, thickness: 1.5pt, cap: "round")))
        }
      }
      #for (i, lbl) in x-labels.enumerate() {
        let edge = if i == 0 { left } else if i == x-labels.len() - 1 { right } else { center }
        let slot = 24mm
        let dx = if i == 0 { 0mm } else if i == x-labels.len() - 1 { width - slot } else { x-step * i - slot / 2 }
        place(top + left, dx: dx, dy: height + 2.2mm,
          box(width: slot, align(edge,
            text(font: _t.font-mono, size: label-size - 1pt, tracking: 0.04em, fill: _t.fg-muted, lbl))))
      }
    ]
  ]
}
