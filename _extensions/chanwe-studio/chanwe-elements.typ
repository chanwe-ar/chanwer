// =============================================================
// chanwe-elements.typ — callouts, pull quotes, great quote pages
// Available to authors as #callout, #pullquote, #great-quote
// =============================================================

// Stubs for Quarto's font-awesome callout icon calls
#let fa-info() = []
#let fa-lightbulb() = []
#let fa-exclamation() = []
#let fa-exclamation-triangle() = []
#let fa-fire() = []

// Accepts both our API (#callout(kind: "note")[body]) and
// Quarto's generated API (#callout(body: [...], icon: fa-info(), ...))
#let callout(
  kind: "note",
  eyebrow: none,
  title: none,
  body: none,
  background_color: none,
  icon_color: none,
  icon: none,
  body_background_color: none,
  ..args,
) = {
  let content = if body != none { body } else if args.pos().len() > 0 { args.pos().first() } else { [] }

  // Derive dot color + type label from icon_color (Quarto native) or kind (our API)
  let (dot-color, auto-label) = if icon_color != none {
    let lbl = if icon_color == rgb("#0758E5")      { "NOTE" }
         else if icon_color == rgb("#00A047")       { "TIP" }
         else if icon_color == rgb("#EB9113")       { "WARNING" }
         else if icon_color == rgb("#CC1914")       { "IMPORTANT" }
         else if icon_color == rgb("#FC5300")       { "CAUTION" }
         else                                       { "NOTE" }
    (icon_color, lbl)
  } else if kind == "warn" or kind == "warning" {
    (rgb("#EB9113"), "WARNING")
  } else if kind == "do" {
    (rgb("#15803D"), "DO")
  } else if kind == "dont" {
    (rgb("#CC1914"), "DON'T")
  } else {
    (_t.primary, upper(kind))
  }

  let type-label = if eyebrow != none { upper(eyebrow) } else { auto-label }
  let display-title = if title != none { title } else { type-label }

  block(
    fill: luma(250),
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    width: 100%,
    inset: 0pt,
    breakable: false,
    clip: true,
  )[
    #block(inset: (x: 4.5mm, top: 4mm, bottom: 4mm), width: 100%, spacing: 0pt)[
      #grid(
        columns: (auto, auto, auto, 1fr),
        column-gutter: 5pt,
        align: left + horizon,
        circle(radius: 3pt, fill: dot-color),
        text(font: _t.font-mono, size: 7pt, fill: _t.fg-subtle, "//"),
        text(font: _t.font-mono, size: 7pt, tracking: 0.14em, fill: _t.fg-subtle, type-label),
        text(font: _t.font-display, size: 8pt, weight: 700, fill: _t.ink, display-title),
      )
    ]
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
    #block(inset: (x: 4.5mm, y: 6mm), width: 100%, fill: white, spacing: 0pt)[
      #set text(fill: _t.fg-muted, size: 9.5pt)
      #content
    ]
  ]
}

#let pullquote(body, attribution: none) = block(
  above: 6mm, below: 6mm,
  inset: (left: 6mm),
  stroke: (left: 2pt + _t.primary),
)[
  #text(font: _t.font-serif, size: 16pt, weight: 300, style: "italic", fill: _t.neutral-900, body)
  #if attribution != none {
    v(3mm)
    text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: _t.fg-subtle, upper[— #attribution])
  }
]

#let _gq-scheme(color) = if color == "light" {
  (
    bg:     luma(244),
    eyebrow: _t.primary,
    quote:  _t.neutral-900,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-subtle,
    line:   _t.primary,
  )
} else if color == "primary" {
  (
    bg:     _t.primary,
    eyebrow: white,
    quote:  white,
    emph:   white,
    attr:   white,
    source: white.transparentize(30%),
    line:   white,
  )
} else {
  (
    bg:     _t.ink,
    eyebrow: _t.primary,
    quote:  white,
    emph:   _t.primary,
    attr:   white,
    source: white.transparentize(40%),
    line:   _t.primary,
  )
}

#let page-great-quote(attribution: none, source: none, color: "dark", body) = {
  let s = _gq-scheme(color)
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: s.bg)
  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 40mm, bottom: 30mm),
    fill: s.bg,
  )[
    #show emph: it => text(fill: s.emph, style: "italic", it.body)
    #chanwe-eyebrow("Verbatim", color: s.eyebrow, with-rule: true)
    #v(20mm)
    #set par(leading: 0.85em)
    #text(
      font: _t.font-serif, size: 40pt, style: "italic", weight: 100,
      tracking: -0.01em, fill: s.quote,
    )[\u{201C}#body\u{201D}]
    #v(1fr)
    #if attribution != none {
      line(length: 30%, stroke: 1pt + s.line)
      v(5mm)
      text(font: _t.font-display, size: 12pt, weight: 600, fill: s.attr, attribution)
      if source != none {
        linebreak()
        text(font: _t.font-mono, size: 8pt, tracking: 0.18em, fill: s.source, upper(source))
      }
    }
  ]
}

#let inset-great-quote(attribution: none, source: none, color: "dark", body) = {
  let s = _gq-scheme(color)
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 12mm, bottom: 14mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #set par(leading: 0.85em)
      #chanwe-eyebrow("Verbatim", color: s.eyebrow, with-rule: true)
      #v(6mm)
      #text(
        font: _t.font-serif, size: 22pt, style: "italic", weight: 100,
        tracking: -0.01em, fill: s.quote,
      )[\u{201C}#body\u{201D}]
      #if attribution != none {
        v(8mm)
        line(length: 20%, stroke: 1pt + s.line)
        v(4mm)
        text(font: _t.font-display, size: 10pt, weight: 600, fill: s.attr, attribution)
        if source != none {
          linebreak()
          v(1mm)
          text(font: _t.font-mono, size: 7.5pt, tracking: 0.18em, fill: s.source, upper(source))
        }
      }
    ]
  )
}

#let inset-great-figure(
  eyebrow: none,
  title: "",
  source: none,
  layout: "center",
  position: "right",
  color: "dark",
  caption: [],
  body,
) = {
  let s = _gq-scheme(color)
  let col-widths = if layout == "left" {
    (3fr, 7fr)
  } else if layout == "right" {
    (7fr, 3fr)
  } else {
    (1fr, 1fr)
  }

  let text-col = block(width: 100%)[
    #if eyebrow != none {
      block(below: 3mm)[
        #chanwe-eyebrow(eyebrow, color: s.eyebrow, with-rule: true)
      ]
    }
    #if title != "" {
      block(below: 5mm, above: if eyebrow != none { 4mm } else { 0mm })[
        #text(font: _t.font-display, size: 14pt, weight: 700,
              tracking: -0.01em, fill: s.quote, title)
      ]
    }
    #set text(font: _t.font-sans, size: 10pt, fill: s.source)
    #caption
  ]

  let plot-col = block(width: 100%)[
    #body
    #if source != none {
      v(3mm)
      text(font: _t.font-mono, size: 7pt, tracking: 0.16em,
           fill: s.source, upper(source))
    }
  ]

  let (first-col, second-col) = if position == "left" {
    (plot-col, text-col)
  } else {
    (text-col, plot-col)
  }

  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 14mm, bottom: 14mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #grid(
        columns: col-widths,
        column-gutter: 14mm,
        align: (left + top, left + top),
        first-col,
        second-col,
      )
    ]
  )
}

#let inset-great-summary(
  eyebrow: "Executive Summary",
  title: "",
  color: "white",
  body,
) = {
  let bg      = if color == "gray" or color == "light" { _t.neutral-100 } else { white }
  let borders = color != "gray" and color != "light"
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: bg,
      inset: (x: 22mm, top: 0pt, bottom: 0pt),
    )[
      #if borders { line(length: 100%, stroke: 0.5pt + _t.neutral-900) }
      #block(width: 100%, inset: (top: 12mm, bottom: 14mm))[
        #grid(
          columns: (4fr, 6fr),
          column-gutter: 14mm,
          align: (left + top, left + top),
          text(
            font: _t.font-mono, size: 8.5pt, weight: 500,
            tracking: 0.18em, fill: _t.primary,
            "// " + upper(eyebrow),
          ),
          block(width: 100%)[
            #if title != "" {
              block(below: 7mm)[
                #set par(leading: 0.72em)
                #text(font: _t.font-display, size: 14pt, weight: 700, fill: _t.ink, title)
              ]
              line(length: 18mm, stroke: 1.5pt + _t.primary)
              v(4mm)
            }
            #set text(size: 10pt, fill: _t.fg)
            #set par(leading: 0.75em)
            #body
          ],
        )
      ]
      #if borders { line(length: 100%, stroke: 0.5pt + _t.neutral-900) }
    ]
  )
}

#let _great-findings-row(number: "01", title: "", body) = {
  grid(
    columns: (auto, 1fr),
    column-gutter: 6mm,
    align: (left + top, left + top),
    text(
      font: _t.font-serif, size: 38pt, weight: 100, style: "italic",
      fill: _t.primary, number,
    ),
    block(width: 100%)[
      #block(below: 4mm)[
        #text(font: _t.font-display, size: 11.5pt, weight: 700, fill: _t.ink, title)
      ]
      #set text(size: 9pt, fill: _t.fg-muted)
      #set par(leading: 0.72em)
      #body
    ],
  )
}

#let great-findings(number: "01", title: "", color: "white", body) = {
  let bg = if color == "light" or color == "gray" { _t.neutral-100 } else { none }
  block(width: 100%, fill: bg, radius: 4pt, inset: (top: 7mm, bottom: 7mm))[
    #_great-findings-row(number: number, title: title, body)
  ]
}

// item used inside a great-findings-grid (no individual bg)
#let great-findings-item(number: "01", title: "", body) = {
  block(width: 100%, inset: (top: 6mm, bottom: 6mm))[
    #_great-findings-row(number: number, title: title, body)
  ]
}

// wrapper that applies a unified background with dividers between items
#let great-findings-grid(color: "white", body) = {
  let bg = if color == "light" { _t.neutral-100 } else if color == "gray" { _t.neutral-200 } else { none }
  block(width: 100%, fill: bg, radius: 4pt, inset: (x: 6mm, y: 0mm))[
    #body
  ]
}

// =============================================================
// KPI cards
// =============================================================

#let _kpi-color(name) = {
  if name == "primary" { _t.primary }
  else if name == "green" { rgb("#15803D") }
  else if name == "red" { rgb("#CC1914") }
  else if name == "ink" { _t.ink }
  else { _t.fg-muted }
}

#let kpi-card(
  title: "",
  main: "",
  prefix: "",
  unit: "",
  main-color: "ink",
  secondary: "",
  secondary-color: "primary",
  direction: "none",
) = {
  let mc = if main-color == "ink" { _t.ink } else { _kpi-color(main-color) }
  let (dir-symbol, dir-color) = {
    if direction == "up" { ("▲ ", "green") }
    else if direction == "down" { ("▼ ", "red") }
    else if direction == "neutral" { ("— ", "ink") }
    else { ("", secondary-color) }
  }
  let sc = _kpi-color(if direction == "none" { secondary-color } else { dir-color })
  let secondary-text = if direction != "none" { dir-symbol + secondary } else { secondary }

  block(
    fill: luma(248),
    stroke: 0.5pt + _t.neutral-300,
    radius: 5pt,
    width: 100%,
    height: 42mm,
    inset: (x: 5mm, top: 5mm, bottom: 5mm),
  )[
    #block(height: 8mm, width: 100%, clip: false)[
      #set par(leading: 0.7em)
      #text(font: _t.font-mono, size: 7.5pt, weight: 500, fill: _t.fg-subtle, "// " + upper(title))
    ]
    #v(1mm)
    #block(below: 0.5mm)[
      #if prefix != "" {
        text(font: _t.font-display, size: 14pt, weight: 700, fill: _t.fg-muted, prefix)
        h(0.5mm)
      }
      #text(font: _t.font-display, size: 20pt, weight: 800, fill: mc, main)
      #if unit != "" {
        h(1mm)
        text(font: _t.font-display, size: 10pt, weight: 600, fill: _t.fg-muted, unit)
      }
    ]
    #if secondary-text != "" {
      place(bottom + left,
        block(inset: (bottom: 5mm))[
          #set text(font: _t.font-sans, size: 8pt, fill: sc)
          #set par(leading: 0.7em)
          #secondary-text
        ]
      )
    }
  ]
}

#let kpi-grid(cols: 4, rows: auto, items) = {
  grid(
    columns: range(cols).map(_ => 1fr),
    rows: if rows == auto { auto } else { range(rows).map(_ => auto) },
    column-gutter: 4mm,
    row-gutter: 4mm,
    ..items,
  )
}
