// =============================================================
// chanwe-pages.typ — editorial pages 1:1 to HTML
// AGENDA · ABSTRACT · CHAPTER SEPARATOR · BACK COVER
// =============================================================

#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// ---------- AGENDA / TABLE OF CONTENTS -----------------------
#let chanwe-toc-row(num: "", label: "", page: "", sub: false) = block(spacing: 0pt)[
  #set par(spacing: 0pt, leading: 0pt)
  #if sub {
    grid(
      columns: (10mm, 14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, left + bottom, right + bottom),
      [],
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: 100, fill: _t.fg-subtle, num),
      text(font: _t.font-mono, size: 7.5pt, weight: 100, fill: _t.fg-subtle, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: 100, fill: _t.fg-subtle, page),
    )
  } else {
    grid(
      columns: (14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: 100, fill: _t.fg-subtle, num),
      text(font: _t.font-mono, size: 7.5pt, weight: 100, fill: _t.ink, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: 100, fill: _t.fg-muted, page),
    )
  }
]

#let chanwe-toc-group(numeral: "01", title: "", pages: "", rows: ()) = {
  block(above: 0mm, below: 8mm)[
    // group head: giant italic numeral · title · page range
    #grid(
      columns: (20mm, 1fr, 30mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(
        font: _t.font-serif, style: "italic", weight: 300,
        size: 28pt, tracking: -0.01em, fill: _t.primary,
        numeral,
      ),
      text(
        font: _t.font-display, size: 14pt, weight: 700,
        tracking: -0.005em, fill: _t.neutral-900, title,
      ),
      text(
        font: _t.font-mono, size: 8pt, tracking: 0.18em,
        fill: _t.fg-subtle, upper(pages),
      ),
    )
    #v(2mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
    // rows with explicit spacing and light gray separator after each
    #for (i, r) in rows.enumerate() {
      let is_sub = r.at("sub", default: false)
      v(if i == 0 { 0.1mm } else if is_sub { 0mm } else { 0.1mm })
      chanwe-toc-row(..r)
      v(0.1mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
    }
  ]
}

#let chanwe-agenda(
  eyebrow: "Document map",
  title: "Agenda",
  lede: none,
  groups: none,
  parts: none,
) = {
  v(10mm)
  // section eyebrow with rule
  chanwe-section-eyebrow(eyebrow)

  v(7.5mm)

  // big page-display title with orange italic period
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: 700,
      tracking: -0.025em, fill: _t.neutral-900, title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: _t.primary, stroke: none))
  ]

  if lede != none {
    v(15mm)
    block(width: 130mm)[
      #set par(leading: 0.55em)
      #set text(font: _t.font-sans, size: 10pt, weight: 400, fill: _t.fg-muted)
      #lede
    ]
  }

  v(14mm)

  if groups != none {
    // --- manual groups mode ---
    for g in groups { chanwe-toc-group(..g) }
  } else if parts != none {
    // --- simple parts list ---
    for part in parts {
      let (num, ptitle, desc, pg) = part
      grid(
        columns: (16mm, 1fr, 20mm),
        column-gutter: 5mm,
        align: (right + top, left + top, right + top),
        text(font: _t.font-serif, style: "italic", weight: 300, size: 24pt, fill: _t.primary, num),
        {
          text(font: _t.font-display, size: 13pt, weight: 700, tracking: -0.005em, fill: _t.neutral-900, ptitle)
          linebreak()
          v(1.5mm)
          text(font: _t.font-sans, size: 9.5pt, fill: _t.fg-muted, desc)
        },
        text(font: _t.font-mono, size: 8pt, tracking: 0.12em, fill: _t.fg-subtle, upper(pg)),
      )
      v(3mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
      v(4mm)
    }
  } else {
    // --- AUTO mode: driven by outline() with independent counters ---
    // Part labels (from chanwe-chapter-divider) are injected between groups
    // without changing the H1 group-header hierarchy.
    let _h1 = counter("_chanwe-toc-h1")
    let _h2 = counter("_chanwe-toc-h2")
    let _h3 = counter("_chanwe-toc-h3")

    show outline.entry: it => {
      if it.level == 1 {
        _h1.step()
        _h2.update(0)
        _h3.update(0)
        context {
          let n   = _h1.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          let next_h1s = query(heading.where(level: 1).after(it.element.location(), inclusive: false))
          let end_pg = if next_h1s.len() > 0 {
            let np = counter(page).at(next_h1s.first().location()).first()
            if np > pg { np - 1 } else { pg }
          } else {
            counter(page).final().first()
          }
          let pages_str = if end_pg > pg {
            _pad2(pg) + " — " + _pad2(end_pg)
          } else { _pad2(pg) }
          let prev_h1s = query(heading.where(level: 1).before(it.element.location(), inclusive: false))
          let is-first = prev_h1s.len() == 0

          // Inject part label when a new chapter-divider section starts.
          // Filter by page number — avoids any selector.before() ambiguity.
          let h-loc   = it.element.location()
          let h-page  = counter(page).at(h-loc).first()
          let all-parts = query(<chanwe-part>)
          let cur-part = {
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= h-page)
            if before.len() > 0 { before.last().value } else { none }
          }

          let prev-part = if is-first { none } else {
            let ph = counter(page).at(prev_h1s.last().location()).first()
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= ph)
            if before.len() > 0 { before.last().value } else { none }
          }

          let cur-num  = if cur-part  != none { cur-part.number  } else { none }
          let prev-num = if prev-part != none { prev-part.number } else { none }

          if cur-part != none and cur-num != prev-num {
            v(if is-first { 0mm } else { 14mm })
            move(dx: -18mm,
              block(
                width: 210mm,
                fill: _t.neutral-100,
                inset: (x: 18mm, top: 10mm, bottom: 8mm),
              )[
                #grid(
                  columns: (auto, auto),
                  column-gutter: 6mm,
                  align: (left + bottom, left + bottom),
                  text(font: _t.font-serif, style: "italic", weight: 200,
                       size: 32pt, fill: _t.primary, cur-part.number),
                  {
                    text(font: _t.font-serif, style: "italic", weight: 200,
                         size: 26pt, tracking: -0.02em, fill: luma(90),
                         cur-part.title)
                    text(font: _t.font-serif, style: "italic", weight: 200,
                         size: 26pt, fill: _t.primary, ".")
                  },
                )
              ]
            )
            v(8mm)
          }

          block(above: if cur-part != none and cur-num != prev-num { 0mm } else if is-first { 0mm } else { 12mm }, below: 0pt)[
            #v(4mm)
            #grid(
              columns: (18mm, 1fr, 34mm),
              column-gutter: 0mm,
              align: (left + bottom, left + bottom, right + bottom),
              text(font: _t.font-serif, style: "italic", weight: 300,
                   size: 24pt, fill: _t.primary, _pad2(n)),
              text(font: _t.font-display, size: 16pt, weight: 600,
                   fill: _t.neutral-900, it.body()),
              text(font: _t.font-mono, size: 7pt, tracking: 0.18em,
                   fill: _t.fg-subtle, upper(pages_str)),
            )
            #v(4mm)
            #line(length: 100%, stroke: 0.5pt + _t.neutral-900)
            #v(2mm)
          ]
        }
      } else if it.level == 2 {
        _h2.step()
        _h3.update(0)
        context {
          let n  = _h2.get().first()
          let pg = counter(page).at(it.element.location()).first()
          v(1.5mm)
          chanwe-toc-row(num: _pad2(n), label: it.element.body, page: _pad2(pg))
          v(-1.5mm)
          line(length: 100%, stroke: 0.5pt + _t.border)
        }
      } else if it.level == 3 {
        _h3.step()
        context {
          let h2n = _h2.get().first()
          let h3n = _h3.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          v(1.5mm)
          chanwe-toc-row(num: str(h2n) + "." + str(h3n), label: it.element.body, page: _pad2(pg), sub: true)
          v(-1.5mm)
          line(length: 100%, stroke: 0.5pt + _t.border)
        }
      }
    }
    outline(title: none, depth: 3)
  }
}

// =============================================================
// ABSTRACT WITH DROP-CAP
// =============================================================
// HTML structure:
//   .abstract-wrap  (60mm side rail | 1fr body)
//     .abstract-side  (label-row × N, hairline border-right)
//     .abstract-body
//       h2 (Archivo 28pt 700)
//       p.lead   (Fraunces 12pt body, ::first-letter 56pt drop-cap)
//       p · p · ... (Fraunces 12pt body)
// =============================================================
#let chanwe-side-row(label: "", value: "", dark: false) = {
  let lc = if dark { white.transparentize(45%) } else { _t.fg-subtle }
  let vc = if dark { white                     } else { _t.fg        }
  stack(
    dir: ttb, spacing: 8pt,
    text(font: _t.font-mono, size: 7.5pt, weight: 500,
         tracking: 0.18em, fill: lc, upper(label)),
    text(font: _t.font-sans, size: 10pt, weight: 500, fill: vc, value),
  )
}

#let chanwe-abstract(
  // new compact call style: eyebrow / title / meta
  eyebrow: none,
  title: none,
  meta: none,            // array of (label, value, sub) 3-tuples
  takeaway: none,
  dark: false,           // true → inverted text colors for dark backgrounds
  // original verbose style kept for backward compat
  page-eyebrow: "01 · Abstract",
  page-title: "A reference, not a document.",
  side-rows: (),
  abstract-heading: "Abstract",
  lead: none,
  paragraphs: (),
  // captures optional trailing content block [...]
  ..args,
) = {
  let body = if args.pos().len() > 0 { args.pos().at(0) } else { none }
  // resolve aliases
  let resolved-eyebrow = if eyebrow != none { eyebrow } else { page-eyebrow }
  let resolved-title   = if title   != none { title   } else { page-title   }
  let resolved-rows    = if meta    != none {
    meta.map(((lbl, val, ..rest)) => (
      label: lbl,
      value: if rest.len() > 0 { val + "\n" + rest.at(0) } else { val },
    ))
  } else { side-rows }

  // color scheme shortcuts
  let title-color  = if dark { white                     } else { _t.neutral-900 }
  let rail-stroke  = if dark { white.transparentize(70%) } else { _t.neutral-900 }
  let body-color   = if dark { white.transparentize(15%) } else { _t.fg-muted    }
  let takwy-color  = if dark { white                     } else { _t.ink         }

  v(10mm)
  chanwe-section-eyebrow(resolved-eyebrow)
  v(7.5mm)
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: 700,
      tracking: -0.025em, fill: title-color, resolved-title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: _t.primary, stroke: none))
  ]
  v(24mm)

  // --- simple body layout when called with eyebrow/title/meta/body ---
  if body != none {
    grid(
      columns: (60mm, 1fr),
      column-gutter: 14mm,
      align: (left + top, left + top),
      // side rail: meta rows
      block(
        stroke: (right: 0.5pt + rail-stroke),
        inset: (right: 10mm),
        width: 100%,
      )[
        #stack(
          dir: ttb, spacing: 9mm,
          ..resolved-rows.map(r => chanwe-side-row(..r, dark: dark))
        )
      ],
      // body block
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: 400, fill: body-color)
        #if takeaway != none {
          let s = str(takeaway)
          let parts = s.split(" ")
          let first-word = parts.at(0)
          let rest = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 6mm)[
            #text(font: _t.font-serif, size: 32pt, weight: 300, style: "italic", fill: _t.primary, first-word)#text(weight: 700, fill: takwy-color, rest)
          ]
        }
        #body
      ],
    )
    return
  }

  // --- original verbose layout ---
  grid(
    columns: (60mm, 1fr),
    column-gutter: 14mm,
    align: (left + top, left + top),
    // ---- side rail ----
    block(
      stroke: (right: 0.5pt + _t.border),
      inset: (right: 10mm),
      width: 100%,
    )[
      #stack(
        dir: ttb, spacing: 6mm,
        ..side-rows.map(r => chanwe-side-row(..r))
      )
    ],
    // ---- body with real drop-cap ----
    block[
      // h2 abstract heading
      #block(below: 4mm)[
        #text(font: _t.font-display, size: 28pt, weight: 700,
              tracking: -0.02em, fill: _t.neutral-900, abstract-heading)
      ]

      // Lead paragraph with manual drop-cap
      #if lead != none {
        let first = lead.at(0)
        let rest  = lead.slice(1)
        block(below: 4mm)[
          #place(top + left, dx: 0pt, dy: 8pt)[
            #text(
              font: _t.font-serif, size: 56pt, weight: 300,
              fill: _t.neutral-900, first,
            )
          ]
          #pad(left: 24mm)[
            #set par(leading: 0.62em, justify: true, first-line-indent: 0pt)
            #set text(font: _t.font-serif, size: 12pt, weight: 300, fill: _t.fg)
            #text(weight: 300, fill: _t.neutral-900,
                  rest.slice(0, calc.min(rest.len(), 60)))
            #rest.slice(calc.min(rest.len(), 60))
          ]
        ]
      }

      // remaining paragraphs (no drop cap)
      #set par(leading: 0.62em, justify: true)
      #set text(font: _t.font-serif, size: 12pt, weight: 300, fill: _t.fg)
      #for p in paragraphs {
        block(below: 4mm, p)
      }
    ],
  )
}

// =============================================================
// EXECUTIVE SUMMARY PAGE — same layout as the abstract page,
// callable inline from ::: {.chanwe-executive-summary ...} divs.
// Pulls meta-rows from doc state automatically.
// =============================================================
#let chanwe-exec-summary-page(
  eyebrow: "Executive Summary",
  title: none,
  takeaway: none,
  color: none,
  meta: none,
  body,
) = {
  let bg = if color == "beige"  { _t.beige       }
      else if color == "gray"   { _t.neutral-100   }
      else if color == "dark"   { _t.ink          }
      else if color == "white"  { white           }
      else                      { none            }
  pagebreak(weak: true)
  if bg != none {
    set page(fill: bg)
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: color == "dark",
        body,
      )
    }
  } else {
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: color == "dark",
        body,
      )
    }
  }
  pagebreak(weak: true)
}

// =============================================================
// DOUBLE EXECUTIVE SUMMARY — two summary halves filling one page
// =============================================================
// Each half = 129.5mm (= (297 - 22 top - 16 bottom) / 2).
// Internal helper returns a block (no move wrapper — caller stacks both).
#let _chanwe-exec-half(
  eyebrow:          "Executive Summary",
  title:            none,
  takeaway:         none,
  meta:             (),
  // Status section
  status-label:     none,   // small eyebrow above hero word (e.g. "Convicción")
  status-hero:      none,   // large italic serif word (e.g. "Alza")
  status-kind:      none,   // "good" | "regular" | "bad" — determines color
  status-value:     none,   // 1–5: fills that many scale segments
  status-meta-label: "",    // single meta label shown right of hero word
  status-meta-value: "",    // single meta value shown right of hero word
  drivers:          (),     // max 3 × (dir, title, desc, tag, tag-color) tuples
  drivers-label:    "Factores Clave",  // eyebrow above the driver list
  color:            none,
  content:          [],
  divider:          false,
) = {
  let bg = if color == "beige"  { _t.beige       }
      else if color == "gray"   { _t.neutral-100 }
      else if color == "dark"   { _t.ink         }
      else if color == "white"  { white          }
      else                      { _t.paper       }
  let dark        = color == "dark"
  let title-color = if dark { white                      } else { _t.neutral-900 }
  let rail-stroke = if dark { white.transparentize(60%)  } else { _t.neutral-300 }
  let body-color  = if dark { white.transparentize(15%)  } else { _t.fg-muted    }
  let takwy-color = if dark { white                      } else { _t.ink         }
  let div-stroke  = if divider { (bottom: 0.5pt + _t.neutral-900) } else { none }
  let lc          = if dark { white.transparentize(45%) } else { _t.fg-subtle }
  let vc          = if dark { white                     } else { _t.neutral-900 }
  let border-col  = if dark { white.transparentize(70%) } else { _t.neutral-300 }

  // Status color from kind
  let s-color = if status-kind == "good"    { rgb("#15803D") }
    else if status-kind == "regular"         { rgb("#D97706") }
    else if status-kind == "bad"             { rgb("#CC1914") }
    else                                     { _t.primary     }

  // 5-segment fill bar: first status-value segments colored, rest gray
  let filled = if status-value != none { status-value } else { 0 }
  let scale-bar = grid(
    columns: range(5).map(_ => 1fr),
    column-gutter: 1.5mm,
    ..range(5).map(i => {
      rect(width: 100%, height: 5pt, radius: 1.5pt,
           fill: if i < filled { s-color } else { luma(222) })
    })
  )

  // Meta cell shown to the right of the hero word
  let meta-right = if status-meta-label != "" {
    stack(
      dir: ttb, spacing: 3pt,
      align(right, text(font: _t.font-mono, size: 6pt, tracking: 0.18em, fill: lc,
                        upper(status-meta-label))),
      align(right, text(font: _t.font-display, size: 9pt, weight: 700, fill: vc,
                        status-meta-value)),
    )
  } else { [] }

  // Pre-compute left rail
  let left-rail = if status-hero != none or drivers.len() > 0 {
    [
      #if status-hero != none {
        if status-label != none {
          text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em, fill: lc,
               "// " + upper(str(status-label)))
          v(-1mm)
        }
        // Hero word + right meta in the same baseline row
        grid(
          columns: (1fr, auto),
          column-gutter: 3mm,
          align: (left + bottom, right + bottom),
          text(font: _t.font-serif, size: 24pt, weight: 200,
               style: "italic", fill: s-color, str(status-hero)),
          meta-right,
        )
        v(0mm)
        // Fill bar
        scale-bar
        if drivers.len() > 0 { v(5mm) }
      }
      #if drivers.len() > 0 {
        block(spacing: 0pt)[
          #text(font: _t.font-mono, size: 6.5pt, tracking: 0.18em, fill: lc, "// " + upper(str(drivers-label)))
        ]
        v(0.5mm)
        for (i, drv) in drivers.slice(0, calc.min(drivers.len(), 3)).enumerate() {
          let dir    = drv.at(0)
          let dtitle = drv.at(1)
          let ddesc  = drv.at(2)
          let dtag   = drv.at(3)
          let dtag-k = drv.at(4)
          let dir-col = if dir == "up"   { rgb("#15803D") }
            else if dir == "down"         { rgb("#CC1914") }
            else                          { _t.fg-muted    }
          let dir-sym = if dir == "up"   { "▲" }
            else if dir == "down"         { "▼" }
            else                          { "—" }
          let t-col = if dtag-k == "green"   { rgb("#15803D") }
            else if dtag-k == "red"           { rgb("#CC1914") }
            else if dtag-k == "orange"        { _t.primary     }
            else                              { dir-col        }
          grid(
            columns: (8pt, 1fr, auto),
            column-gutter: 3pt,
            align: (left + top, left + top, right + top),
            text(font: _t.font-sans, size: 7pt, weight: 700, fill: dir-col, dir-sym),
            {
              block(spacing: 0pt)[
                #text(font: _t.font-display, size: 7.5pt, weight: 700, fill: vc, dtitle)
              ]
              if ddesc != "" {
                v(1mm)
                block(spacing: 0pt)[
                  #set par(leading: 0.3em)
                  #text(font: _t.font-sans, size: 6.5pt, fill: lc, ddesc)
                ]
              }
            },
            text(font: _t.font-display, size: 7pt, weight: 700, fill: t-col, dtag),
          )
          if i < calc.min(drivers.len(), 3) - 1 { v(2mm) }
        }
      }
    ]
  } else {
    [
      #stack(
        dir: ttb, spacing: 7mm,
        ..meta.map(((lbl, val, ..rest)) => chanwe-side-row(
          label: lbl,
          value: if rest.len() > 0 { val + "\n" + rest.at(0) } else { val },
          dark: dark,
        ))
      )
    ]
  }

  block(
    width: 210mm,
    height: 133.5mm,
    fill: bg,
    stroke: div-stroke,
    inset: (x: 18mm, top: 10mm, bottom: 10mm),
    clip: true,
  )[
    #chanwe-section-eyebrow(eyebrow)
    #v(3mm)
    #if title != none {
      block(below: 0pt)[
        #set par(leading: 0.75em, justify: false)
        #text(
          font: _t.font-display, size: 36pt, weight: 700,
          tracking: -0.025em, fill: title-color, title,
        )#box(width: 8pt, height: 8pt, baseline: -1pt,
          circle(fill: _t.primary, stroke: none))
      ]
      v(10mm)
    }
    #grid(
      columns: (56mm, 1fr),
      column-gutter: 14mm,
      align: (left + top, left + top),
      // left rail — status + drivers or meta rows
      block(
        stroke: (right: 0.5pt + rail-stroke),
        inset: (right: 10mm),
        width: 100%,
      )[#left-rail],
      // right body
      block[
        #set par(leading: 0.65em, justify: true)
        #if takeaway != none {
          let s     = str(takeaway)
          let parts = s.split(" ")
          let fw    = parts.at(0)
          let rest  = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 5mm)[
            #text(font: _t.font-serif, size: 20pt, weight: 300,
                  style: "italic", fill: _t.primary, fw
            )#text(weight: 700, size: 10pt, fill: takwy-color, rest)
          ]
        }
        #set text(font: _t.font-sans, size: 9.5pt, weight: 400, fill: body-color)
        #content
      ],
    )
  ]
}

// Public function — call with [top body][bottom body]
#let chanwe-double-exec-summary(
  // top half
  top-eyebrow:           "Executive Summary",
  top-title:             none,
  top-takeaway:          none,
  top-meta:              (),
  top-status-label:      none,
  top-status-hero:       none,
  top-status-kind:       none,
  top-status-value:      none,
  top-status-meta-label: "",
  top-status-meta-value: "",
  top-drivers:           (),
  top-drivers-label:     "Factores Clave",
  top-color:             none,
  // bottom half
  bot-eyebrow:           "Executive Summary",
  bot-title:             none,
  bot-takeaway:          none,
  bot-meta:              (),
  bot-status-label:      none,
  bot-status-hero:       none,
  bot-status-kind:       none,
  bot-status-value:      none,
  bot-status-meta-label: "",
  bot-status-meta-value: "",
  bot-drivers:           (),
  bot-drivers-label:     "Factores Clave",
  bot-color:             none,
  // two positional content blocks [top][bottom]
  ..bodies,
) = {
  let top-content = bodies.pos().at(0, default: [])
  let bot-content = bodies.pos().at(1, default: [])

  pagebreak(weak: true)

  // Narrow top margin to the header rule position (14mm) so blocks fill rule-to-rule.
  set page(margin: (top: 14mm, bottom: 16mm, x: 18mm), header-ascent: 0pt, footer-descent: 0pt)

  move(dx: -18mm,
    stack(
      dir: ttb,
      spacing: 0pt,
      _chanwe-exec-half(
        eyebrow: top-eyebrow, title: top-title,
        takeaway: top-takeaway, meta: top-meta,
        status-label: top-status-label, status-hero: top-status-hero,
        status-kind: top-status-kind, status-value: top-status-value,
        status-meta-label: top-status-meta-label,
        status-meta-value: top-status-meta-value,
        drivers: top-drivers, drivers-label: top-drivers-label,
        color: top-color, content: top-content,
        divider: true,
      ),
      _chanwe-exec-half(
        eyebrow: bot-eyebrow, title: bot-title,
        takeaway: bot-takeaway, meta: bot-meta,
        status-label: bot-status-label, status-hero: bot-status-hero,
        status-kind: bot-status-kind, status-value: bot-status-value,
        status-meta-label: bot-status-meta-label,
        status-meta-value: bot-status-meta-value,
        drivers: bot-drivers, drivers-label: bot-drivers-label,
        color: bot-color, content: bot-content,
        divider: false,
      ),
    )
  )

  pagebreak(weak: true)
}

// =============================================================
// CHAPTER SEPARATOR (full-page divider)
// =============================================================
// HTML .chapter-cover layout:
//   - black background
//   - subtle gray radial halo (top-left, low opacity)
//   - .cc-top   : mark left, doc id right (mono micro-type, white/60)
//   - .cc-mid   : eyebrow + cc-num-row (giant 02 + title block)
//   - .cc-bottom: meta items + page number
// =============================================================
#let chanwe-chapter-divider(
  number: "02",
  eyebrow: "Part 02 · Worked Example",
  title: [Mendoza Wine — \ a sample report.],
  blurb: "A short consultancy brief assembled from every component on the previous pages. Real shape; illustrative numbers.",
  top-left-mark: none,
  top-right-mark: none,
  meta: none,
  page-counter: none,
) = {
  _chanwe-cur-part.update(_ => (number: number, title: title, eyebrow: eyebrow))

  set page(
    paper: "a4", margin: 0pt, fill: _t.neutral-100,
    header: none, footer: none,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 110mm,
        fill: gradient.radial(
          _t.primary.transparentize(93%),
          _t.neutral-100.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.neutral-900)

  context {
    let doc = _chanwe-doc.get()
    let _left  = if top-left-mark != none { top-left-mark } else { doc.doc-id }
    let _right = if top-right-mark != none { top-right-mark } else { doc.edition }
    let _meta  = if meta != none { meta } else {
      doc.meta-rows.slice(0, calc.min(3, doc.meta-rows.len())).map(((l, v, ..)) => (l, v))
    }
    let _pages = if page-counter != none { page-counter } else {
      str(counter(page).get().first()) + " / " + str(counter(page).final().first())
    }

  block(
    width: 100%, height: 100%,
    inset: (x: 18mm, top: 18mm, bottom: 18mm),
  )[
    #v(1fr)

    // ---- MIDDLE: numeral + (eyebrow · title · blurb) ----
    #grid(
      columns: (1fr,),
      box[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 14mm,
          align: (left + bottom, left + bottom),
          // GIANT italic numeral
          text(
            font: _t.font-serif, style: "italic", weight: 100,
            size: 220pt, tracking: -0.04em,
            fill: _t.primary,
            number,
          ),
          // eyebrow · title · rule · blurb stacked in the right column
          stack(
            dir: ttb, spacing: 7mm,
            chanwe-eyebrow(eyebrow, color: _t.primary, with-rule: true),
            text(
              font: _t.font-serif, style: "italic", weight: 300,
              size: 36pt, tracking: -0.02em, fill: _t.neutral-900,
              title,
            ),
            box(width: 18mm, height: 1.5pt, fill: none),
            text(
              font: _t.font-sans, size: 14pt, weight: 300,
              fill: _t.fg-muted,
              blurb,
            ),
          ),
        )
      ],
    )

    #v(10mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-900)

    #v(4fr)

    // ---- BOTTOM: doc-id · edition ----
    #line(length: 100%, stroke: 0.5pt + _t.border)
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      {
        set text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
                 fill: _t.fg-subtle)
        upper(doc.doc-id)
        if doc.edition != "" {
          h(14mm)
          upper(doc.edition)
        }
      },
      text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
           fill: _t.fg-subtle, upper(_pages)),
    )
  ]
  }
}

// =============================================================
// BACK COVER
// =============================================================
// HTML .back-cover layout:
//   - black bg + gray radial halo (centered)
//   - top: bc-mark (white wordmark)
//   - middle: italic 36pt tagline ("Less template, more report.")
//   - bc-rule (orange short bar)
//   - bc-grid (3 items: Studio · Web · Document)
//   - bc-arrow (small arrow logo)
//   - bc-bottom (legal · page num)
// =============================================================
#let chanwe-back-cover(
  wordmark-white: none,
  arrow-icon: none,
  tagline-line1: "Less template,",
  tagline-line2: "more report.",
  grid-items: (
    ("Studio",   "Chanwe — Estrategia Activa", "Mendoza · Argentina"),
    ("Web",      "chanwe.com.ar",              "contacto@chanwe.com.ar"),
    ("Document", "CHW-RPT-2026-04",            "Rev. A · 17·04·2026"),
  ),
  legal: "Información confidencial · Prohibida su distribución sin autorización",
  page-counter: "17 / 19",
) = {
  set page(
    paper: "a4", margin: 0pt, fill: _t.ink,
    header: none, footer: none,
    background: place(center + horizon,
      circle(radius: 105mm,
        fill: gradient.radial(
          white.transparentize(90%),
          black.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: white)

  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 22mm, bottom: 22mm),
  )[
    // ---- TOP: white wordmark ----
    #if wordmark-white != none {
      image(wordmark-white, height: 14mm)
    } else {
      text(font: _t.font-display, size: 28pt, weight: 800, tracking: -0.03em,
           fill: white, "chanwe")
    }

    #v(1fr)

    // ---- TAGLINE: italic 36pt, orange on second line ----
    #block[
      #set par(leading: 0.45em)
      #text(
        font: _t.font-serif, style: "italic", weight: 300,
        size: 36pt, tracking: -0.01em, fill: white,
        tagline-line1,
      )
      \
      #text(
        font: _t.font-serif, style: "italic", weight: 300,
        size: 36pt, tracking: -0.01em, fill: _t.primary,
        tagline-line2,
      )
    ]

    #v(8mm)
    #line(length: 30mm, stroke: 1.5pt + _t.primary)
    #v(10mm)

    // ---- INFO GRID: 3 columns ----
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8mm,
      ..grid-items.map(((label, val, sub)) => {
        stack(
          dir: ttb, spacing: 3mm,
          text(font: _t.font-mono, size: 7.5pt, weight: 500,
               tracking: 0.20em, fill: white.transparentize(45%),
               upper(label)),
          stack(
            dir: ttb, spacing: 2pt,
            text(font: _t.font-display, size: 12pt, weight: 600,
                 fill: white, val),
            text(font: _t.font-sans, size: 9pt, weight: 400,
                 fill: white.transparentize(35%), sub),
          ),
        )
      })
    )

    #v(1fr)

    // ---- ARROW ICON (small, left-aligned, above bottom) ----
    #if arrow-icon != none {
      image(arrow-icon, width: 14mm)
      v(4mm)
    }

    // ---- BOTTOM: legal + page num + hairline rule ----
    #line(length: 100%, stroke: 0.5pt + white.transparentize(80%))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(font: _t.font-mono, size: 7.5pt, weight: 500,
           tracking: 0.18em, fill: white.transparentize(45%),
           upper(legal)),
      text(font: _t.font-mono, size: 7.5pt, weight: 500,
           tracking: 0.18em, fill: white.transparentize(45%),
           upper(page-counter)),
    )
  ]
}
