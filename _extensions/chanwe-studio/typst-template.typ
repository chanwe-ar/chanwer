// =============================================================
// chanwe-studio/chanwe — typst-template.typ
// Page setup, design tokens, and global show rules.
// =============================================================

// ---------- Design tokens ------------------------------------
#let chanwe-tokens = (
  paper:       white,
  ink:         rgb("#0F0F0F"),
  fg:          rgb("#211F1C"),
  fg-muted:    rgb("#71706C"),
  fg-subtle:   rgb("#928D86"),
  primary:     rgb("#FB3D0E"),
  primary-soft: rgb("#FB3D0E1A"),
  neutral-100: rgb("#F5F5F5"),
  neutral-200: rgb("#E8E8E8"),
  neutral-300: rgb("#D4D4D4"),
  neutral-700: rgb("#525252"),
  neutral-900: rgb("#1F1F1F"),
  border:      rgb("#1F1F1F1A"),
  font-display: ("Archivo", "Helvetica Neue", "Arial"),
  font-serif:   ("Fraunces 9pt", "Georgia", "Times New Roman"),
  font-sans:    ("Satoshi", "Inter", "Helvetica Neue", "Arial"),
  font-mono:    ("JetBrains Mono", "Menlo", "Courier New"),
)

// expose tokens as a global so partials and user code can use them
#let _t = chanwe-tokens

// assets path — override with chanwe-assets: in document YAML if the
// extension installed to a different path (e.g. _extensions/chanwe/)
#let _chanwe-assets = "$chanwe-assets$".replace("\\_", "_")

// ---------- Small primitives ---------------------------------
#let chanwe-glyph(size: 7pt, color: _t.primary) = box(
  width: size, height: size, baseline: 1pt,
)[
  #place(center + horizon, rotate(45deg, square(size: size * 0.72, fill: color)))
]

#let chanwe-eyebrow(body, color: _t.primary, with-rule: false) = {
  if with-rule {
    box(width: 22pt, height: 0.75pt, fill: color, baseline: -3pt)
    h(8pt)
  }
  text(
    font: _t.font-mono,
    size: 8.5pt,
    weight: 300,
    tracking: 0.18em,
    fill: color,
    upper(body),
  )
}

#let chanwe-section-eyebrow(body) = chanwe-eyebrow(body, with-rule: true)

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

// ---------- Running header / footer --------------------------
#let chanwe-header(section, topic) = context {
  // header occupies 14mm; remaining margin space becomes gap before content
  block(height: 14mm, width: 100%)[
    #grid(
      rows: (1fr, auto),
      align(horizon, grid(
        columns: (1fr, auto),
        align: (left + horizon, right + horizon),
        {
          set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
          text(weight: 700, fill: _t.primary, "//")
          h(5pt)
          text(fill: _t.fg-subtle, upper[#section])
          if topic != "" {
            text(fill: _t.fg-subtle, upper[ · #topic])
          }
        },
        image(_chanwe-assets + "Logo_Negro.png", height: 3.5mm, fit: "contain"),
      )),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
    )
  ]
}

#let chanwe-footer(doc-id, edition) = context {
  // line pins to top; text row grows to fill space → text centers
  block(height: 100%, width: 100%)[
    #grid(
      rows: (auto, 1fr),
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border)),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: _t.fg-subtle)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [#box(baseline: 30%, image(_chanwe-assets + "Estrategia_Color.png", height: 2.08mm, fit: "contain")) #h(6pt) #upper[#doc-id #h(8pt) #text(fill: _t.neutral-300, edition)]],
          {
            box(width: 3pt, height: 3pt, fill: _t.primary, baseline: -0.5pt)
            h(8pt)
            text(fill: _t.ink, weight: 600, upper(str(counter(page).get().first())))
            text(fill: _t.fg-subtle, upper(" / " + str(counter(page).final().first())))
          },
        )
      }),
    )
  ]
}

// Global state — set by chanwe() and read by components
#let _chanwe-doc = state("chanwe-doc", (
  doc-id:    "CHW · DOC",
  edition:   "",
  meta-rows: (),
))

// Tracks the active chapter-divider section (set in chanwe-chapter-divider)
#let _chanwe-cur-part = state("chanwe-cur-part", none)

// =============================================================
// PARTIAL INCLUDES (cover, elements, pages)
// Each file uses _t which is defined above.
// =============================================================
$chanwe-cover.typ()$
$chanwe-elements.typ()$
$chanwe-pages.typ()$
$chanwe-charts.typ()$

// =============================================================
// MAIN TEMPLATE FUNCTION (called by typst-show.typ)
// =============================================================
#let chanwe(
  // metadata
  title: "Untitled",
  subtitle: none,
  author: "Chanwe Studio",
  date: "",
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "Confidential",
  chapter: "Chapter",
  section: "",
  topic: "",
  rail-eyebrow: "Quarto · Style Guide",
  // assets
  hero-image: none,
  wordmark: none,
  stamp: ("VOL", "I", "2026"),
  hero-date: "",
  meta-rows: (
    ("Author", "Chanwe Studio", "Estrategia Activa"),
  ),
  // toggles
  cover: true,
  // toc
  toc-eyebrow: "Document map",
  toc-title: "Agenda",
  toc-lede: none,
  toc: true,
  // abstract
  abstract-eyebrow: "Abstract",
  abstract-title: none,
  abstract-text: none,
  abstract-keywords: (),
  abstract-status: none,
  abstract-show: (),
  abstract-takeaway: none,   // string — first letter gets drop-cap treatment
  // back cover
  back-cover: true,
  back-cover-tagline-1: "Less template,",
  back-cover-tagline-2: "more report.",
  back-cover-cols: (),
  // body
  body,
) = {
  // ---- store metadata in global state -----------------------
  _chanwe-doc.update((doc-id: doc-id, edition: edition, meta-rows: meta-rows))

  // ---- global text + page defaults ---------------------------
  set text(font: _t.font-sans, size: 11pt, fill: _t.fg, lang: "en")
  set par(leading: 0.85em, justify: false, spacing: 1.0em)
  set heading(numbering: "1.1.1.")

  // ---- inline rules (apply to entire document) ---------------
  show emph: it => text(fill: _t.primary, it.body)
  show strong: it => text(weight: 700, fill: _t.ink, it.body)
  show math.equation.where(block: true): it => block(
    width: 100%,
    fill: _t.neutral-100,
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    inset: (x: 10mm, y: 8mm),
  )[
    #set text(fill: _t.fg-muted, weight: 200)
    #align(center, it)
  ]
  show link: it => underline(stroke: 0.6pt + _t.primary, offset: 2pt, text(fill: _t.primary, it))
  show raw.where(block: false): it => box(
    fill: _t.neutral-100,
    stroke: 0.5pt + _t.neutral-300,
    inset: (x: 3pt, y: 2pt),
    radius: 2pt,
    text(font: _t.font-mono, size: 0.85em, fill: _t.neutral-700, it),
  )
  show raw.where(block: true): it => block(
    fill: _t.neutral-100,
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

  // ---- headings ----------------------------------------------
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
    v(10mm)
    block(below: 20mm)[
      #box(width: 50pt, height: 1.5pt, fill: _t.primary)
      #v(12mm)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 8mm,
        align: (left + bottom, left + bottom),
        text(font: _t.font-serif, style: "italic", weight: 100,
             size: 48pt, fill: _t.primary,
             counter(heading).display("1")),
        block()[
          #set par(leading: 0.18em)
          #text(font: _t.font-display, size: 30pt, weight: 700,
               tracking: -0.025em, fill: _t.neutral-900, it.body)
        ],
      )
      #v(4mm)
      #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
    ]
  }
  show heading.where(level: 2): it => block(above: 32mm, below: 12mm)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 6mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-serif, style: "italic", weight: 100,
           size: 24pt, fill: _t.primary,
           counter(heading).display("1.1")),
      text(font: _t.font-display, size: 27pt, weight: 700,
           tracking: -0.01em, it.body),
    )
    #v(3mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
  ]
  show heading.where(level: 3): it => block(above: 22mm, below: 5.5mm)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-serif, style: "italic", weight: 100,
           size: 18pt, fill: _t.primary,
           counter(heading).display("1.1.1")),
      text(font: _t.font-display, size: 17pt, weight: 700,
           tracking: -0.01em, it.body),
    )
  ]
  show heading.where(level: 4): it => block(above: 18mm, below: 4mm)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom),
      text(font: _t.font-serif, style: "italic", weight: 100,
           size: 14pt, fill: _t.primary,
           counter(heading).display("1.1.1.1")),
      text(font: _t.font-display, size: 14pt, weight: 700,
           tracking: -0.01em, it.body),
    )
  ]
  show heading.where(level: 5): it => block(above: 8mm, below: 4mm)[
    #stack(dir: ttb,
      {
        box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt)
        h(6pt)
        text(font: _t.font-mono, size: 8pt, weight: 500,
             tracking: 0.18em, fill: _t.fg-subtle, upper(it.body))
      },
      3mm,
      line(length: 100%, stroke: 0.5pt + _t.neutral-300),
    )
  ]
  show heading.where(level: 6): it => block(above: 6mm, below: 5mm)[
    #box(width: 5pt, height: 5pt, radius: 2.5pt, fill: _t.primary, baseline: 0.5pt)
    #h(6pt)
    #text(font: _t.font-mono, size: 8pt, weight: 500,
          tracking: 0.18em, fill: _t.fg-subtle, upper(it.body))
  ]

  // ---- lists -------------------------------------------------
  set list(marker: ([•], [◦], [–]))

  // ---- quote (Pandoc/Quarto blockquotes) ---------------------
  show quote: it => block(
    above: 6mm, below: 6mm,
    inset: (left: 6mm),
    stroke: (left: 2pt + _t.primary),
  )[
    #text(font: _t.font-serif, size: 16pt, weight: 300, style: "italic", fill: _t.fg-muted, it.body)
    #if it.attribution != none {
      v(3mm)
      text(font: _t.font-serif, size: 10pt, weight: 300, style: "italic", fill: _t.fg-subtle, [— #it.attribution])
    }
  ]

  // ---- tables -----------------------------------------------
  set table(
    fill: none,
    stroke: (col, row) => (
      top:    if row == 0 { 0.5pt + _t.neutral-900 } else { none },
      bottom: if row == 0 { 0.5pt + _t.neutral-900 } else { 0.4pt + _t.border },
    ),
    inset: (x: 4mm, y: 3.5mm),
  )
  show table.cell: set text(
    size: 8pt, weight: 200, fill: _t.fg,
  )
  show table.cell.where(y: 0): set text(
    font: _t.font-display, size: 8pt, weight: 200,
    tracking: 0pt, fill: _t.ink,
  )
  show figure.where(kind: table): it => {
    v(15mm, weak: true)
    it.caption
    v(6mm)
    it.body
    v(-0.25pt)
    line(length: 100%, stroke: 0.5pt + _t.ink)
    v(15mm, weak: true)
  }
  show figure: set block(above: 15mm, below: 15mm)
  show figure.caption: it => align(left, text(
    font: _t.font-mono, size: 8pt, tracking: 0.14em,
    fill: _t.fg-subtle, upper(it.supplement) + " " + it.counter.display() + "  ·  " + upper(it.body),
  ))

  // ---- COVER (optional) -------------------------------------
  if cover {
    chanwe-cover-page(
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      volume: volume,
      rail-eyebrow: rail-eyebrow,
      hero-image: hero-image,
      wordmark: wordmark,
      stamp: stamp,
      hero-date: hero-date,
      meta-rows: meta-rows,
      date: date,
    )
  }

  // ---- body pages -------------------------------------------
  set page(
    paper: "a4",
    margin: (top: 22mm, bottom: 16mm, x: 18mm),
    header: chanwe-header(section, topic),
    footer: chanwe-footer(doc-id, edition),
  )

  // ---- auto TOC (optional) ----------------------------------
  if toc {
    chanwe-agenda(
      eyebrow: toc-eyebrow,
      title: toc-title,
      lede: toc-lede,
    )
    pagebreak()
  }

  // ---- auto abstract (optional) ----------------------------
  if abstract-text != none {
    let all-meta = (
      "document": ("Document", doc-id, none),
      "edition":  ("Edition",  edition, none),
      "author":   ("Author",   author,  none),
      "status":   ("Status",   if abstract-status != none { abstract-status } else { "" }, none),
      "keywords": ("Keywords", abstract-keywords.join(" · "), none),
    )
    let fields = if abstract-show.len() > 0 { abstract-show } else { all-meta.keys() }
    let meta-items = fields
      .filter(k => all-meta.at(k, default: none) != none)
      .map(k => all-meta.at(k))
      .filter(((_, v, ..)) => v != "")
    chanwe-abstract(
      eyebrow: abstract-eyebrow,
      title: abstract-title,
      meta: meta-items,
      takeaway: abstract-takeaway,
      abstract-text,
    )
    pagebreak()
  }

  body

  // ---- back cover (optional) --------------------------------
  if back-cover {
    chanwe-back-cover-page(
      tagline-1: back-cover-tagline-1,
      tagline-2: back-cover-tagline-2,
      back-cols: back-cover-cols,
    )
  }
}
