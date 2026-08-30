// =============================================================
// chanwe-brand - typst-template.typ
// Branded PDF output for books and manuals (chanwe-brand-typst).
// Text system, TOC, and back cover recycled 1:1 from
// chanwe-publications; the cover is this format's own design —
// a technical plate, distinct from the publication's dark slab.
// =============================================================

// ---------- Design tokens (as chanwe-publications) -------------
#let chanwe-tokens = (
  paper:        rgb("#FBFBFB"),
  paper-alt:    rgb("#F7F7F7"),
  ink:          rgb("#0F0F0F"),
  fg:           rgb("#211F1C"),
  fg-muted:     rgb("#71706C"),
  fg-subtle:    rgb("#928D86"),
  primary:      rgb("#FD3810"),
  primary-soft: rgb("#FD38101A"),
  beige:        rgb("#F5F1EB"),
  neutral-200:  rgb("#E8E8E8"),
  neutral-300:  rgb("#D4D4D4"),
  neutral-700:  rgb("#525252"),
  neutral-900:  rgb("#1F1F1F"),
  border:       rgb("#1F1F1F1A"),
  code-bg:      rgb("#EDF0F1"),
  band-bg:      rgb("#EDF0F1"),
  font-display: ("Archivo", "Helvetica Neue", "Arial"),
  font-serif:   ("Cormorant Garamond", "Georgia", "Times New Roman"),
  font-sans:    ("Satoshi", "Inter", "Helvetica Neue", "Arial"),
  font-mono:    ("JetBrains Mono", "Menlo", "Courier New"),
)
#let _t = chanwe-tokens

// assets path — override with chanwe-assets: in YAML when the compiled
// document does not sit next to _extensions/.
#let _chanwe-assets = "$chanwe-assets$".replace("\\_", "_")

// Pandoc escapes underscores in YAML values (a\_b) — undo for file paths.
#let _chanwe-clean-path(p) = if p == none { none } else {
  p.replace("\\_", "_").replace("\\-", "-")
}
#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// ---------- Primitives (as chanwe-publications) ----------------
#let chanwe-eyebrow(body, color: _t.primary, with-rule: false, size: 8.5pt) = {
  if with-rule {
    box(width: 22pt, height: 0.75pt, fill: color, baseline: -3pt)
    h(8pt)
  }
  text(font: _t.font-mono, size: size, weight: 500, tracking: 0.18em,
       fill: color, upper(body))
}

#let chanwe-meta-row(label, value, sub: none) = {
  grid(
    columns: (18mm, 1fr),
    column-gutter: 4mm,
    align: (left + top, left + top),
    text(font: _t.font-mono, size: 7pt, tracking: 0.20em, fill: _t.fg-subtle, upper(label)),
    block(spacing: 0pt)[
      #set par(spacing: 0pt, leading: 0.9em)
      #text(font: _t.font-display, size: 10pt, weight: 600, fill: _t.fg, value)
      #if sub != none {
        linebreak()
        text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, sub)
      }
    ],
  )
}

// Devices used by filters/typst-brand.lua ------------------------
#let chanwe-great-quote(body) = block(
  width: 100%, fill: _t.ink, inset: (x: 12mm, y: 10mm),
  above: 10mm, below: 10mm,
)[
  #box(width: 22pt, height: 1pt, fill: _t.primary)
  #v(4mm)
  #set par(leading: 0.5em, justify: false)
  #text(font: _t.font-display, size: 16pt, weight: 600,
        tracking: -0.01em, fill: white, body)
]

#let chanwe-mark(body) = highlight(fill: _t.primary-soft,
  extent: 1pt, text(fill: _t.ink, body))

// ---------- Running header / footer (as chanwe-publications) ---
#let chanwe-book-header(doc-id, edition) = context {
  block(height: 100%, width: 100%)[
    #grid(
      rows: (1fr, auto),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [
            #text(weight: 700, fill: _t.primary, "//")
            #h(5pt)
            #text(fill: _t.fg-subtle, upper(doc-id))
            #if edition != "" [#text(fill: _t.fg-subtle, upper(" · " + edition))]
          ],
          image(_chanwe-assets + "Logo_Negro.svg", height: 3.5mm, fit: "contain"),
        )
      }),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
    )
  ]
}

#let chanwe-book-footer(doc-id, edition) = context {
  block(height: 100%, width: 100%)[
    #grid(
      rows: (auto, 1fr),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: _t.fg-subtle)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [#upper[#doc-id #h(8pt) #text(fill: _t.neutral-300, edition)]],
          [#text(size: 6.9pt, fill: _t.ink, weight: 600, upper(str(counter(page).get().first())))#text(size: 6.9pt, fill: _t.fg-subtle, upper(" / " + str(counter(page).final().first())))],
        )
      }),
    )
  ]
}

// =============================================================
// COVER — the technical plate (this format's own design)
// US Letter, framed: metadata bar / art panel / title block /
// meta columns / audience bar, series line outside the frame.
// =============================================================
#let chanwe-book-cover(
  title: "Untitled",
  subtitle: none,
  doc-id: "CHW · BOOK",
  edition: "",
  volume: "",
  rail-eyebrow: "Chanwe / Research",
  hero-image: none,
  hero-caption-1: none,
  hero-caption-2: none,
  meta-rows: (),
  cover-edge: none,
  publication-period: none,
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
) = {
  let hero = if hero-image == none { _chanwe-assets + "hero-img.svg" }
             else { _chanwe-clean-path(hero-image) }
  set page(
    paper: "us-letter", margin: 0pt, header: none, footer: none,
    fill: _t.paper, background: none,
    foreground: {
      place(top + left, dx: 40mm, dy: -60mm,
        circle(radius: 110mm,
          fill: gradient.radial(_t.primary.transparentize(82%), black.transparentize(100%)),
          stroke: none,
        )
      )
      if cover-edge != none {
        place(right + top, dx: -4.5mm, dy: 16mm,
          rotate(-90deg, origin: right + horizon,
            text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
                 fill: _t.primary, upper(cover-edge))
          )
        )
      }
    },
  )
  set block(spacing: 0pt)

  // the plate: hairline frame with red corner ticks
  place(top + left, dx: 12mm, dy: 12mm, {
    let fw = 215.9mm - 24mm   // frame width
    let fh = 279.4mm - 32mm   // frame height (extra room for series line)
    box(width: fw, height: fh, stroke: 0.5pt + _t.neutral-900, {
      // corner ticks
      for (ax, ay, ddx, ddy) in (
        (left, top, 0mm, 0mm), (right, top, 0mm, 0mm),
        (left, bottom, 0mm, 0mm), (right, bottom, 0mm, 0mm),
      ) {
        place(ax + ay, dx: ddx, dy: ddy,
          box(width: 3.2mm, height: 3.2mm, fill: none, stroke: none, {
            place(ax + ay, box(width: 3.2mm, height: 0.9pt, fill: _t.primary))
            place(ax + ay, box(width: 0.9pt, height: 3.2mm, fill: _t.primary))
          }))
      }

      grid(
        rows: (11mm, 88mm, 1fr, auto, 10mm),
        columns: (100%,),

        // ---- 1. metadata bar --------------------------------
        block(width: 100%, height: 11mm,
              stroke: (bottom: 0.5pt + _t.neutral-900),
              inset: (x: 8mm, y: 0mm))[
          #set align(horizon)
          #grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            {
              set text(font: _t.font-mono, size: 7pt, tracking: 0.16em, fill: _t.fg)
              text(weight: 700, fill: _t.primary, "//")
              h(6pt)
              upper[#text(weight: 600, doc-id)]
              h(16pt)
              upper[#text(fill: _t.fg-muted, volume)]
            },
            image(_chanwe-assets + "Logo_Negro.svg", height: 4.5mm, fit: "contain"),
          )
        ],

        // ---- 2. art panel ------------------------------------
        box(width: 100%, height: 88mm, clip: true,
            stroke: (bottom: 0.5pt + _t.neutral-900), {
          place(top + left,
            image(hero, width: 100%, height: 88mm, fit: "cover"))
          if hero-caption-1 != none or hero-caption-2 != none {
            place(bottom + right, dx: -6mm, dy: -6mm)[
              #box(
                inset: (x: 8pt, y: 4pt),
                fill: white.transparentize(45%),
                stroke: 0.5pt + black.transparentize(90%),
              )[
                #set align(right)
                #set par(leading: 0.4em)
                #text(
                  font: _t.font-mono, size: 6.5pt, weight: 500, tracking: 0.20em,
                  fill: black.transparentize(35%),
                  [
                    #if hero-caption-1 != none [#upper(hero-caption-1)]
                    #if hero-caption-2 != none [\ #upper(hero-caption-2)]
                  ],
                )
              ]
            ]
          }
        }),

        // ---- 3. title block ----------------------------------
        block(width: 100%, inset: (x: 8mm, top: 12mm, bottom: 10mm))[
          #chanwe-eyebrow(rail-eyebrow, with-rule: true)
          #v(9mm)
          #set par(leading: 0.8em, justify: false)
          #block[
            #text(
              font: _t.font-display, size: 38pt, weight: 600,
              tracking: -0.04em, fill: _t.neutral-900, title,
            )#h(3pt)#box(width: 8pt, height: 8pt, baseline: -2pt,
              circle(fill: _t.primary, stroke: none))
          ]
          #if subtitle != none {
            v(7mm)
            set par(leading: 0.55em)
            set text(font: _t.font-serif, size: 14pt, weight: 300,
                     style: "italic", fill: rgb("#484848"))
            subtitle
          }
        ],

        // ---- 4. meta columns ---------------------------------
        block(width: 100%,
              stroke: (top: 0.5pt + _t.neutral-900),
              inset: (x: 8mm, top: 6mm, bottom: 6mm))[
          #if meta-rows.len() > 0 {
            grid(
              columns: meta-rows.map(_ => 1fr),
              column-gutter: 8mm,
              ..meta-rows.map(((label, value, sub)) => chanwe-meta-row(label, value, sub: sub))
            )
          }
        ],

        // ---- 5. audience bar ---------------------------------
        block(width: 100%, height: 10mm,
              stroke: (top: 0.5pt + _t.neutral-900),
              inset: (x: 8mm, y: 0mm))[
          #set align(horizon)
          #set text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em, fill: _t.fg-subtle)
          #grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            upper[#edition#if publication-period != none [#h(14pt)#text(fill: _t.neutral-300, publication-period)]],
            upper(if volume != "" { volume } else { "PÚBLICO" }),
          )
        ],
      )
    })

    // series line, outside the frame
    v(2.5mm)
    box(width: fw)[
      #set text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em)
      #grid(
        columns: (1fr, auto),
        align: (left, right),
        [
          #text(weight: 700, fill: _t.primary, "//")
          #h(5pt)
          #text(fill: _t.fg, weight: 600, upper(publication-series))
        ],
        text(fill: _t.fg-subtle, upper(publication-location)),
      )
    ]
  })

  pagebreak()

  // ---- blank interstitial page ---------------------------------
  set page(paper: "us-letter", margin: 0pt, header: none, footer: none,
           fill: _t.paper-alt, foreground: none, background: none)
  set block(spacing: 0pt)
  place(center + horizon,
    image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
  block(width: 100%, height: 229.4mm)[]
  block(width: 100%, height: 50mm, fill: _t.paper-alt, inset: (x: 14mm))[
    #set align(center + horizon)
    #align(center + horizon,
      image(_chanwe-assets + "Logo_Beige.svg", height: 45mm, fit: "contain"))
  ]
}

// =============================================================
// BACK COVER — full-bleed ink page (as chanwe-publications)
// =============================================================
#let chanwe-book-back-cover(
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
) = {
  // blank interstitial before the back cover
  {
    set page(paper: "us-letter", margin: 0pt, header: none, footer: none,
             fill: _t.paper-alt, foreground: none, background: none)
    set block(spacing: 0pt)
    place(center + horizon,
      image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
    block(width: 100%, height: 279.4mm)[]
  }

  set page(
    paper: "us-letter", margin: 0pt, header: none, footer: none, fill: _t.ink,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 110mm,
        fill: gradient.radial(_t.primary.transparentize(93%), black.transparentize(100%)),
        stroke: none,
      )
    ),
    foreground: if cover-edge != none {
      place(right + top, dx: -3mm, dy: 14mm,
        rotate(-90deg, origin: right + horizon,
          text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
               fill: white.transparentize(25%), upper(cover-edge))
        )
      )
    } else { none },
  )
  set block(spacing: 0pt)

  block(
    width: 100%, height: 279.4mm, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,
      align(left + top,
        image(_chanwe-assets + "Logo_Blanco.svg", height: 20.2mm, fit: "contain")),
      [],
      block[
        #image(_chanwe-assets + "Estrategia_Color.png", height: 10mm, fit: "contain")
        #v(12mm)
        #set par(leading: 0.8em, justify: false)
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 300, fill: white, tagline-1)
        #linebreak()
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 300, fill: _t.primary, tagline-2)
        #v(8mm)
        #line(length: 100%, stroke: 0.5pt + white.transparentize(75%))
        #v(8mm)
        #if back-cols.len() > 0 {
          grid(
            columns: back-cols.map(_ => 1fr),
            column-gutter: 8mm,
            ..back-cols.map(((label, value, sub)) => block(spacing: 0pt)[
              #text(font: _t.font-mono, size: 6pt, tracking: 0.20em,
                    fill: white.transparentize(50%), upper(label))
              #v(2.5mm)
              #text(font: _t.font-display, size: 9.5pt, weight: 700, fill: white, value)
              #if sub != none and sub != "" {
                linebreak()
                v(0.5mm)
                text(font: _t.font-sans, size: 8pt, fill: white.transparentize(40%), sub)
              }
            ])
          )
        }
      ],
    )
  ]
}

// =============================================================
// CONTENTS — the chanwe-publications agenda, driven by outline():
// gray part bands (unnumbered H1s), chapter groups with the serif
// red numeral and page ranges, mono section rows.
// =============================================================
#let chanwe-toc-row(num: "", label: "", page: "") = block(spacing: 0pt)[
  #set par(spacing: 0pt, leading: 0pt)
  #grid(
    columns: (14mm, 1fr, 12mm),
    column-gutter: 4mm,
    align: (left + bottom, left + bottom, right + bottom),
    text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: 100, fill: _t.fg-subtle, num),
    text(font: _t.font-mono, size: 7.5pt, weight: 100, fill: _t.ink, label),
    text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: 100, fill: _t.fg-muted, page),
  )
]

#let chanwe-book-contents(
  eyebrow: "Document map",
  title: "Index",
  lede: none,
  depth: 2,
) = {
  v(6mm)
  chanwe-eyebrow(eyebrow, with-rule: true)
  v(7.5mm)
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: 700,
      tracking: -0.025em, fill: _t.neutral-900, title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: _t.primary, stroke: none))
  ]
  if lede != none {
    v(10mm)
    block(width: 130mm)[
      #set par(leading: 0.55em)
      #set text(font: _t.font-sans, size: 10pt, weight: 400, fill: _t.fg-muted)
      #lede
    ]
  }
  v(12mm)

  let _h1 = counter("_chanwe-toc-h1")
  let _h2 = counter("_chanwe-toc-h2")

  show outline.entry.where(level: 1): it => {
    if it.element.numbering == none {
      // part band — full-bleed gray, serif italic title with red period
      context {
        let loc = it.element.location()
        v(10mm, weak: true)
        move(dx: -18mm,
          block(
            width: 215.9mm,
            fill: _t.band-bg,
            inset: (x: 18mm, top: 8mm, bottom: 7mm),
          )[
            #link(loc)[
              #text(font: _t.font-serif, style: "italic", weight: 300,
                    size: 20pt, tracking: -0.02em, fill: _t.neutral-900,
                    it.element.body)#text(font: _t.font-serif, style: "italic",
                    weight: 300, size: 20pt, fill: _t.primary, ".")
            ]
          ]
        )
        v(8mm)
      }
    } else {
      _h1.step()
      _h2.update(0)
      context {
        let n   = _h1.get().first()
        let loc = it.element.location()
        let pg  = counter(page).at(loc).first()
        let next_h1s = query(heading.where(level: 1).after(loc, inclusive: false))
          .filter(h => h.numbering != none)
        let end_pg = if next_h1s.len() > 0 {
          let np = counter(page).at(next_h1s.first().location()).first()
          if np > pg { np - 1 } else { pg }
        } else {
          counter(page).final().first()
        }
        let pages_str = if end_pg > pg {
          _pad2(pg) + " — " + _pad2(end_pg)
        } else { _pad2(pg) }

        block(above: 10mm, below: 0pt)[
          #v(4mm)
          #link(loc)[
            #grid(
              columns: (18mm, 1fr, 34mm),
              column-gutter: 0mm,
              align: (left + bottom, left + bottom, right + bottom),
              text(font: _t.font-serif, style: "italic", weight: 300,
                   size: 24pt, fill: _t.primary, _pad2(n)),
              text(font: _t.font-display, size: 16pt, weight: 600,
                   fill: _t.neutral-900, it.element.body),
              text(font: _t.font-mono, size: 7pt, tracking: 0.18em,
                   fill: _t.fg-subtle, upper(pages_str)),
            )
          ]
          #v(4mm)
          #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
          #v(2mm)
        ]
      }
    }
  }
  show outline.entry.where(level: 2): it => {
    _h2.step()
    context {
      let n   = _h2.get().first()
      let loc = it.element.location()
      let pg  = counter(page).at(loc).first()
      v(1.5mm)
      link(loc, chanwe-toc-row(num: _pad2(n), label: it.element.body, page: _pad2(pg)))
      v(-1.5mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
    }
  }
  outline(title: none, depth: depth, indent: 0pt)
  pagebreak()
}

// =============================================================
// MAIN TEMPLATE FUNCTION (called by typst-show.typ)
// =============================================================
#let chanwe-brand-book(
  title: "Untitled",
  subtitle: none,
  author: none,
  date: none,
  doc-id: "CHW · BOOK",
  edition: "",
  volume: "",
  rail-eyebrow: "Chanwe / Research",
  hero-image: none,
  hero-caption-1: none,
  hero-caption-2: none,
  cover: true,
  cover-edge: none,
  meta-rows: (),
  publication-period: none,
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  toc: true,
  toc-depth: 2,
  toc-title: "Index",
  toc-eyebrow: "Document map",
  toc-lede: none,
  back-cover: false,
  back-cover-tagline-1: "Estrategia activa,",
  back-cover-tagline-2: "codo a codo.",
  back-cover-cols: (),
  section-numbering: "1.1",
  page-bg: none,
  second-page-bg: rgb("#F7F7F7"),
  body,
) = {
  let bg = if page-bg != none { page-bg } else { _t.paper }

  // ---- COVER ---------------------------------------------------
  if cover {
    chanwe-book-cover(
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      volume: volume,
      rail-eyebrow: rail-eyebrow,
      hero-image: hero-image,
      hero-caption-1: hero-caption-1,
      hero-caption-2: hero-caption-2,
      meta-rows: meta-rows,
      cover-edge: cover-edge,
      publication-period: publication-period,
      publication-series: publication-series,
      publication-location: publication-location,
    )
  }

  // ---- body page geometry (chanwe-publications: US Letter,
  // 18mm sides; background: none clears the corner logo Quarto's
  // brand.yml support stamps on every page) -----------------------
  set page(
    paper: "us-letter", fill: bg, background: none, foreground: none,
    margin: (top: 15mm, bottom: 15mm, x: 18mm),
    header: chanwe-book-header(doc-id, edition),
    footer: chanwe-book-footer(doc-id, edition),
  )
  set text(font: _t.font-sans, size: 11pt, fill: _t.fg, lang: "en")
  set par(leading: 0.85em, justify: false, spacing: 1.0em)
  set heading(numbering: section-numbering)

  // ---- CONTENTS (before the body show rules, so outline rows
  // are not caught by the red link underline) ---------------------
  counter(page).update(1)
  if toc {
    {
      set page(fill: second-page-bg)
      chanwe-book-contents(
        eyebrow: toc-eyebrow,
        title: toc-title,
        lede: toc-lede,
        depth: toc-depth,
      )
    }
  }

  // ---- inline rules (as chanwe-publications) --------------------
  show emph: it => text(font: _t.font-serif, style: "italic", weight: 300,
                        fill: rgb("#484848"), it.body)
  show strong: it => text(weight: 600, fill: rgb("#484848"), it.body)
  show math.equation.where(block: true): it => block(
    width: 100%,
    fill: _t.code-bg,
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    inset: (x: 10mm, y: 8mm),
  )[
    #set text(fill: _t.fg-muted, weight: 200)
    #align(center, it)
  ]
  show link: it => underline(stroke: 0.6pt + _t.primary, offset: 2pt,
    text(fill: _t.primary, it))
  show raw.where(block: false): it => box(
    fill: _t.code-bg,
    stroke: 0.5pt + _t.neutral-300,
    inset: (x: 3pt, y: 2pt),
    radius: 2pt,
    text(font: _t.font-mono, size: 0.85em, fill: _t.neutral-700, it),
  )
  show raw.where(block: true): it => block(
    fill: _t.code-bg,
    stroke: (left: 1pt + _t.primary),
    inset: (x: 4mm, y: 3mm),
    width: 100%,
  )[
    #set block(fill: none)
    #if it.lang != none {
      text(
        font: _t.font-mono, size: 7.5pt, fill: _t.fg-subtle,
        "# " + it.lang + " · " + str(it.lines.len()) + " lines",
      )
      v(2.5mm)
    }
    #text(font: _t.font-mono, size: 9pt, weight: 300, it)
  ]

  // ---- headings (as chanwe-publications, unnumbered-safe) -------
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    place(left + top, dx: -55mm, dy: -75mm,
      circle(radius: 90mm,
        fill: gradient.radial(
          _t.primary.transparentize(90%),
          white.transparentize(100%),
        ),
        stroke: none,
      )
    )
    v(6mm)
    block(below: 12mm)[
      #box(width: 50pt, height: 1.5pt, fill: _t.primary)
      #v(12mm)
      #if it.numbering != none {
        grid(
          columns: (auto, 1fr),
          column-gutter: 8mm,
          align: (left + bottom, left + bottom),
          text(font: _t.font-serif, style: "italic", weight: 300,
               size: 60pt, fill: _t.primary,
               context counter(heading).display("1")),
          block()[
            #set par(leading: 0.18em)
            #text(font: _t.font-display, size: 30pt, weight: 600,
                 tracking: -0.025em, fill: _t.neutral-900, it.body)
          ],
        )
      } else {
        block()[
          #set par(leading: 0.18em)
          #text(font: _t.font-display, size: 30pt, weight: 600,
               tracking: -0.025em, fill: _t.neutral-900, it.body)
        ]
      }
      #v(1.5mm)
      #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
    ]
  }
  show heading.where(level: 2): it => block(above: 12mm, below: 6mm)[
    #set par(leading: 0.2em)
    #let title = text(font: _t.font-display, size: 19pt, weight: 600,
                      tracking: -0.01em, fill: _t.neutral-900, it.body)
    #if it.numbering != none {
      grid(
        columns: (auto, 1fr),
        column-gutter: 6mm,
        align: (left + bottom, left + bottom),
        text(font: _t.font-mono, weight: 100, size: 15pt, fill: _t.primary,
             context counter(heading).display("1.1")),
        title,
      )
    } else { title }
    #v(0mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
  ]
  show heading.where(level: 3): it => block(above: 10mm, below: 5.5mm)[
    #let title = text(font: _t.font-display, size: 15pt, weight: 600,
                      tracking: -0.01em, fill: _t.neutral-900, it.body)
    #if it.numbering != none {
      grid(
        columns: (auto, 1fr),
        column-gutter: 4mm,
        align: (left + bottom, left + bottom),
        text(font: _t.font-mono, weight: 100, size: 12pt, fill: _t.primary,
             context counter(heading).display("1.1.1")),
        title,
      )
    } else { title }
  ]
  show heading.where(level: 4): it => block(above: 8mm, below: 4mm)[
    #let title = text(font: _t.font-display, size: 13pt, weight: 700,
                      tracking: -0.01em, fill: _t.neutral-900, it.body)
    #if it.numbering != none {
      grid(
        columns: (auto, 1fr),
        column-gutter: 4mm,
        align: (left + bottom, left + bottom),
        text(font: _t.font-serif, style: "italic", weight: 300,
             size: 10pt, fill: _t.primary,
             context counter(heading).display("1.1.1.1")),
        title,
      )
    } else {
      grid(
        columns: (auto, 1fr),
        column-gutter: 6pt,
        align: (left + top, left + top),
        box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt),
        title,
      )
    }
  ]
  show heading.where(level: 5): it => block(above: 8mm, below: 4mm)[
    #stack(dir: ttb,
      {
        box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt)
        h(6pt)
        text(font: _t.font-mono, size: 8pt, weight: 500,
             tracking: 0.18em, fill: _t.neutral-900, upper(it.body))
      },
      3mm,
      line(length: 100%, stroke: 0.5pt + _t.neutral-300),
    )
  ]

  // ---- lists / quotes (as chanwe-publications) ------------------
  set list(marker: ([•], [◦], [–]))
  show quote: it => block(
    above: 6mm, below: 6mm,
    inset: (left: 6mm),
    stroke: (left: 2pt + _t.primary),
  )[
    #set par(leading: 0.425em)
    #text(font: _t.font-serif, size: 11.2pt, weight: 300, style: "italic",
          fill: _t.fg-muted, it.body)
    #if it.attribution != none {
      v(1.5mm)
      text(font: _t.font-serif, size: 7pt, weight: 300, style: "italic",
           fill: _t.fg-subtle, [— #it.attribution])
    }
  ]

  // ---- tables (as chanwe-publications) --------------------------
  set table(
    fill: none,
    stroke: (col, row) => (
      top:    if row == 0 { 0.5pt + _t.neutral-900 } else { none },
      bottom: if row == 0 { 0.5pt + _t.neutral-900 } else { 0.4pt + _t.border },
    ),
    inset: (x: 4mm, y: 3mm),
  )
  show table.cell: set text(size: 8pt, weight: 200, fill: _t.fg)
  show table.cell.where(y: 0): set text(
    font: _t.font-display, size: 8pt, weight: 200, tracking: 0pt, fill: _t.ink,
  )

  // ---- figures (as chanwe-publications) -------------------------
  show figure.where(kind: table): it => {
    v(12mm, weak: true)
    it.body
    v(-0.25pt)
    line(length: 100%, stroke: 0.5pt + _t.ink)
    v(2mm)
    it.caption
    v(12mm, weak: true)
  }
  show figure.where(kind: image): it => {
    v(14mm, weak: true)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(4mm)
    it.body
    v(3mm)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(1.5mm)
    it.caption
    v(12mm, weak: true)
  }
  show figure: set block(above: 11mm, below: 12mm)
  show figure.caption: it => align(left, text(
    font: _t.font-mono, size: 5.5pt, weight: 100, tracking: 0.10em,
    fill: _t.ink,
    upper(it.supplement) + " " + it.counter.display() + "  ·  " + upper(it.body),
  ))

  // ---- user body (chanwe-publications body scope) ---------------
  {
    set text(size: 10pt, fill: _t.fg)
    set par(leading: 0.85em, justify: false, spacing: 2.6em)
    body
  }

  // ---- back cover -----------------------------------------------
  if back-cover {
    chanwe-book-back-cover(
      tagline-1: back-cover-tagline-1,
      tagline-2: back-cover-tagline-2,
      back-cols: back-cover-cols,
      cover-edge: cover-edge,
    )
  }
}

// Convenience alias
#let chanwe-brand = chanwe-brand-book
