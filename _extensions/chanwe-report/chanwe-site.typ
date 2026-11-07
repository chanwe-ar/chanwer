// =================================================================
// chanwe-site.typ — the blocks of chanwe.ar's home, for paper.
//
// A shared partial + filter pair (chanwe-site.lua), read by the report and the
// book; the HTML format draws the same Divs from chanwe-brand-rules.scss.
//
//   chanwe-chapter-label  a short rule, `/ 07` and the name in mono
//   chanwe-statement-rows giant numerals beside statements, hairlines between
//   chanwe-proof-card     the obsidian band: a huge figure, its label, a story
//   chanwe-photo-hero     a rounded photo band with white display type
//   chanwe-giant-word     the real wordmark, huge, with the photo inside it
//   chanwe-photo-cover-page  the book's cover, and `chanwe.cover-variant: photo`
//
// White type is for the photograph only; on plain obsidian text stays
// `rule-cool` (CLAUDE.md, "Text on obsidian"). No colour or weight is written.
// =================================================================

#let _site-art = _chanwe-assets + "bg_mountains.jpg"

#let chanwe-chapter-label(number: none, body) = block(above: 12mm, below: 3mm, sticky: true,
  grid(columns: (8mm, auto), column-gutter: 3mm, align: (left + horizon, left + horizon),
    rect(width: 100%, height: 0.75pt, fill: _t.primary, stroke: none),
    {
      set text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium, tracking: 0.14em, fill: _t.fg-muted)
      if number != none { text(fill: _t.fg, "/ " + number); h(3mm) }
      upper(body)
    }))

#let chanwe-statement-rows(items) = block(above: 8mm, below: 8mm, {
  for (i, it) in items.enumerate() {
    if i > 0 { line(length: 100%, stroke: cw-hairline + _t.rule) }
    block(width: 100%, inset: (y: 7mm), breakable: false,
      grid(columns: (42mm, 1fr), align: (left + top, left + top),
        text(font: _t.font-display, size: 58pt, weight: _t.weight-bold, tracking: -0.05em, fill: _t.fg,
          top-edge: "cap-height", bottom-edge: "baseline",
          if i < 9 { "0" + str(i + 1) } else { str(i + 1) }),
        {
          set par(justify: false, leading: 0.5em, spacing: 0.8em)
          set text(font: _t.font-sans, size: 14pt, weight: _t.weight-regular, fill: _t.fg, hyphenate: false)
          show strong: set text(fill: _t.fg)
          it
        }))
  }
  line(length: 100%, stroke: cw-hairline + _t.rule)
})

#let chanwe-proof-card(figure: none, label: none, kicker: none, title: none, body) = block(above: 8mm, below: 8mm, breakable: false,
  cw-band(inset: (x: 10mm, y: 10mm), grid(columns: (58mm, 1fr), column-gutter: 8mm, align: (left + horizon, left + top),
    stack(dir: ttb, spacing: 5mm,
      if figure != none {
        text(font: _t.font-display, size: 62pt, weight: _t.weight-bold, tracking: -0.05em, fill: _t.rule-cool,
          top-edge: "cap-height", bottom-edge: "baseline", figure)
      },
      if label != none { cw-label(label, fill: _t.fg-subtle) },
    ),
    {
      set par(justify: false, leading: 0.6em, spacing: 0.8em)
      set block(spacing: 0pt)
      if kicker != none { block(below: 3mm, cw-label(kicker, fill: _t.fg-subtle)) }
      if title != none {
        block(below: 3mm, text(font: _t.font-display, size: 16pt, weight: _t.weight-display, tracking: -0.04em, fill: _t.rule-cool, hyphenate: false, title))
      }
      set text(size: 9.5pt, weight: _t.weight-body, fill: _t.rule-cool)
      show strong: set text(fill: _t.rule-cool)
      body
    })))

// The photograph, covering its box, darkened with obsidian towards the foot.
#let _site-photo(art) = {
  layout(size => {
    let natural = measure(image(art))
    let ratio = natural.width / natural.height
    let w = calc.max(size.width / 1pt, size.height / 1pt * ratio) * 1pt
    let h = w / ratio
    place(top + left, dx: -(w - size.width) * 0.62, dy: -(h - size.height) * 0.4, image(art, width: w, height: h))
  })
  place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(angle: 90deg,
    (_t.ink.transparentize(14%), 0%), (_t.ink.transparentize(24%), 45%), (_t.ink.transparentize(3%), 100%))))
  // The dot field of every dark surface.
  place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: cw-dot-field()))
}

#let _site-dot-pill(body) = box(stroke: 0.75pt + _t.white.transparentize(55%), radius: _t.radius-pill, inset: (x: 3mm, y: 2mm),
  stack(dir: ltr, spacing: 2mm,
    circle(radius: 1.1pt, fill: _t.primary, stroke: none),
    text(font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.16em, fill: _t.white, upper(body))))

#let _site-title(size, body) = {
  set par(justify: false, leading: 0.2em)
  text(font: _t.font-display, size: size, weight: _t.weight-display, tracking: -0.05em, fill: _t.white, hyphenate: false, body)
  _chanwe-title-dot(size)
}

#let chanwe-photo-hero(kicker: none, title: none, lede: none, art: _site-art, height: 92mm) = block(above: 8mm, below: 8mm, breakable: false,
  block(width: 100%, height: height, radius: _t.radius-band, clip: true, fill: _t.ink, {
    _site-photo(art)
    place(top + left, block(width: 100%, height: 100%, inset: 9mm, {
      if kicker != none { _site-dot-pill(kicker) }
      set block(spacing: 0pt)
      set par(spacing: 0pt)
      v(1fr)
      if title != none { _site-title(34pt, title) }
      if lede != none {
        v(3mm)
        set par(justify: false, leading: 0.4em)
        text(font: _t.font-serif, size: 15pt, style: "italic", weight: _t.weight-regular, fill: _t.white, lede)
      }
    }))
  }))

// The real wordmark with the photograph inside it, never a font: a generated
// vector asset (scripts/build-giant-word.rb), shared with the HTML format.
#let chanwe-giant-word(caption: none) = block(above: 10mm, below: 8mm, breakable: false, width: 100%, {
  image(_chanwe-assets + "chanwe-giant-word.svg", width: 100%)
  if caption != none {
    v(6mm)
    align(center, cw-label(caption))
  }
})

// `chanwe.cover-variant: photo`: the whole page is the site's hero.
#let chanwe-photo-cover-page(title: none, subtitle: none, badge: none, doc-id: none, edition: none, date: none,
  meta-rows: (), art: none, wordmark: none) = page(paper: _chanwe-paper, margin: 7mm, header: none, footer: none,
  numbering: none, fill: _t.paper, background: none, foreground: none,
  block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.ink, {
    _site-photo(if art != none { art } else { _site-art })
    place(top + left, block(width: 100%, height: 100%, inset: 12mm, {
      set par(justify: false)
      grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
        image(if wordmark != none { wordmark } else { _chanwe-assets + "Logo_Papel.svg" }, height: 9mm, fit: "contain"),
        if badge != none and badge != "" { _site-dot-pill(_chanwe-clean-str(badge)) })
      v(1fr)
      if title != none { _site-title(54pt, title) }
      if subtitle != none {
        v(5mm)
        set par(leading: 0.42em)
        text(font: _t.font-serif, size: 19pt, style: "italic", weight: _t.weight-regular, fill: _t.white, subtitle)
      }
      v(10mm)
      line(length: 100%, stroke: 0.5pt + _t.white.transparentize(60%))
      v(4mm)
      if meta-rows.len() > 0 {
        grid(columns: (1fr,) * calc.min(meta-rows.len(), 3), column-gutter: 6mm,
          ..meta-rows.slice(0, calc.min(meta-rows.len(), 3)).map(((label, value, ..rest)) => {
            text(font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.16em, fill: _t.white.transparentize(25%), upper(_chanwe-clean-str(label)))
            v(1.6mm)
            text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.white, _chanwe-clean-str(value))
          }))
      }
    }))
  }))
