// =================================================================
// typst-template-propuesta.typ
// Chanwe one-page commercial proposal
// =================================================================

#let _p-assets = "$chanwe-assets$".replace("\\_", "_")

#let chanwe-propuesta(
  doc-id:        "CHW · DOC",
  date:          "",
  eyebrow:       "Propuesta Comercial",
  title:         "Propuesta",
  title-em:      "Comercial.",
  edge:          none,
  to:            "",
  proyecto:      "",
  proyecto-desc: "",
  lede:          none,
  scope:         (),
  fees:          (),
  terms:         (),
  sigs:          (),
  footer-client: "",
  footer-doc:    "",
  page-bg:       rgb("#ffffff"),
  wordmark:      none,
  ..rest,
) = {

  let panel-lede = lede

  let primary    = rgb("#FD3810")
  let ink        = rgb("#141414")
  let fg-muted   = rgb("#5a5a5a")
  let fg-subtle  = rgb("#8e8e8e")
  let hair       = rgb("#14141419")
  let border     = rgb("#1F1F1F1A")
  let beige-pill = rgb("#E8DDC4")
  let wm         = if wordmark != none { wordmark } else { _p-assets + "Logo_Negro.svg" }

  let fd = ("Archivo", "Helvetica Neue", "Arial")
  let fs = ("Cormorant Garamond", "Georgia", "Times New Roman")
  let fm = ("JetBrains Mono", "Menlo", "Courier New")

  // ─── Page ─────────────────────────────────────────────────────
  set page(
    paper:  "a4",
    margin: (x: 18mm, top: 14mm, bottom: 14mm),
    fill:   page-bg,
    header: block(height: 100%, width: 100%)[
      #grid(
        rows: (1fr, auto),
        align(horizon, grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          {
            set text(font: fm, size: 6pt, tracking: 0.14em)
            text(weight: 700, fill: primary, "//")
            h(5pt)
            text(fill: fg-subtle, upper(doc-id))
          },
          image(wm, height: 3.5mm, fit: "contain"),
        )),
        pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + border)),
      )
    ],
    footer: block(height: 100%, width: 100%)[
      #grid(
        rows: (auto, 1fr),
        pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + border)),
        align(horizon, {
          set text(font: fm, size: 6pt, tracking: 0.14em, fill: fg-subtle)
          grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            stack(dir: ltr, spacing: 3mm,
              align(horizon, image(_p-assets + "Estrategia_Color.png", height: 3.5mm, fit: "contain")),
              align(horizon, text(fill: fg-subtle, upper(footer-doc))),
            ),
            text(fill: fg-subtle, upper("Pág. 01 / 01")),
          )
        }),
      )
    ],
  )
  set text(font: ("Inter", "Helvetica Neue", "Arial"), size: 10.5pt, fill: rgb("#1a1a1a"), lang: "es")
  set par(leading: 0.5em, spacing: 0pt)

  place(center + bottom, dy: -7mm,
    image(_p-assets + "Logo_Beige.svg", width: 100%, fit: "contain")
  )

  // ─── Edge label ───────────────────────────────────────────────
  if edge != none {
    place(right + top, dx: 13mm, dy: 36mm,
      rotate(-90deg, origin: right + horizon,
        text(font: fm, size: 7.5pt, weight: 500, tracking: 0.4em, fill: fg-subtle, upper(edge))
      )
    )
  }

  v(8mm)

  // ─── HERO ─────────────────────────────────────────────────────
  // Eyebrow with orange rule prefix
  grid(
    columns: (8mm, auto),
    column-gutter: 4mm,
    align: (center + horizon, left + horizon),
    rect(width: 100%, height: 0.75pt, fill: primary, stroke: none),
    text(font: fm, size: 8.5pt, weight: 500, tracking: 0.28em, fill: primary, upper(eyebrow)),
  )
  v(5.5mm)

  // H1 — display + italic serif
  {
    set par(leading: 0.72em, spacing: 0pt)
    [#text(font: fd, size: 51.2pt, weight: 600, tracking: -0.032em, fill: ink, title)#linebreak()#text(font: fd, size: 51.2pt, weight: 600, tracking: -0.032em, fill: ink, title-em.slice(0, -1))#box(width: 12pt, height: 12pt, baseline: 2pt, circle(fill: primary, stroke: none))]
  }
  v(11mm)

  // Subject grid + optional lede — wrapped in compact callout
  line(length: 100%, stroke: 0.5pt + ink)
  v(5mm)
  block(
    width: 100%,
    fill: luma(245),
    inset: (x: 5mm, y: 5mm),
  )[
    #grid(
      columns: (20mm, 1fr),
      row-gutter: 3.5mm,
      column-gutter: 7mm,
      align: (left + top, left + top),
      pad(top: 5pt,
        text(font: fm, size: 7.4pt, weight: 500, tracking: 0.26em, fill: fg-subtle, upper("Para"))
      ),
      text(font: fd, size: 16.8pt, weight: 400, tracking: -0.014em, fill: ink, to),
      pad(top: 3pt,
        text(font: fm, size: 7.4pt, weight: 500, tracking: 0.26em, fill: fg-subtle, upper("Proyecto"))
      ),
      {
        set par(leading: 0.5em, spacing: 0pt)
        text(font: fs, size: 18.6pt, weight: 300, style: "italic", tracking: -0.01em, fill: primary, proyecto)
        v(2.8mm)
        text(font: ("Inter", "Helvetica Neue"), size: 8.7pt, weight: 400, fill: fg-muted, proyecto-desc)
        v(2mm)
      },
    )
    #if panel-lede != [] and panel-lede != none {
      v(4mm)
      line(length: 100%, stroke: 0.5pt + hair)
      v(3mm)
      set text(font: ("Inter", "Helvetica Neue"), size: 9pt, weight: 400, fill: fg-muted)
      set par(leading: 0.34em, spacing: 0.6em)
      panel-lede
    }
    #if terms.len() > 0 {
      v(4mm)
      line(length: 100%, stroke: 0.5pt + hair)
      v(3mm)
      set text(font: fm, size: 6.2pt, weight: 200, tracking: 0.1em)
      stack(dir: ltr, spacing: 8mm,
        ..terms.map(t =>
          [#text(fill: ink, upper(t.label))#h(3pt)·#h(3pt)#text(fill: fg-subtle, t.value)]
        )
      )
    }
  ]

  v(8mm)

  // ─── SCOPE ────────────────────────────────────────────────────
  if scope.len() > 0 {
    grid(
      columns: (22mm, 1fr),
      align: (left + top, left + top),
      pad(top: 15pt,
        text(font: fm, size: 6.8pt, weight: 500, tracking: 0.28em, fill: fg-subtle, upper("Alcance"))
      ),
      {
        line(length: 100%, stroke: 0.5pt + hair)
        for item in scope {
          let is-optional = item.at("optional", default: false)
          let number-fill = if is-optional { fg-subtle } else { primary }
          grid(
            columns: (10mm, 1fr),
            column-gutter: 6mm,
            align: (right + horizon, left + top),
            pad(top: 8pt, bottom: 8pt,
              stack(dir: ttb, spacing: 0.8mm,
                text(font: fs, size: 15pt, weight: 300, style: "italic", fill: number-fill, item.n),
                ..if is-optional { (
                  text(font: fs, size: 5.4pt, weight: 300, style: "italic", fill: number-fill, "(next)"),
                ) } else { () },
              )
            ),
            pad(top: 15pt, bottom: 15pt,
              {
                set par(spacing: 1.5mm, leading: 0.5em)
                text(font: ("Inter", "Helvetica Neue"), size: 8.8pt, weight: 500, tracking: -0.005em, fill: ink, item.title)
                linebreak()
                text(font: ("Inter", "Helvetica Neue"), size: 7.6pt, weight: 400, fill: fg-muted, item.desc)
              }
            ),
          )
          line(length: 100%, stroke: 0.5pt + hair)
        }
      }
    )
  }

  v(8mm)

  // ─── FEES ─────────────────────────────────────────────────────
  if fees.len() > 0 {
    grid(
      columns: fees.map(_ => 1fr),
      column-gutter: 12mm,
      ..fees.map(fee => {
        let hl  = fee.at("highlight", default: false)
        let per = fee.at("per", default: none)
        let cur = fee.at("currency", default: "USD")
        let desc = fee.at("desc", default: none)
        block(above: 0pt, width: 100%, fill: none, stroke: if hl { 0.5pt + ink } else { 0.5pt + luma(210) }, inset: (x: 5mm, y: 2.1mm))[
          #grid(
            columns: (auto, 1fr),
            column-gutter: 3mm,
            align: (left + horizon, left + bottom),
            box(inset: (x: 2.5mm, y: 1.3mm),
              fill: if hl { primary } else { luma(180) },
              text(font: fm, size: 5.2pt, weight: 500, tracking: 0.18em,
                fill: if hl { white } else { ink },
                upper(fee.kind))
            ),
            stack(dir: ttb, spacing: 3.25pt,
              text(font: fm, size: 5.2pt, weight: 500, tracking: 0.28em, fill: fg-subtle, upper(fee.label)),
              line(length: 100%, stroke: 0.5pt + if hl { ink } else { luma(210) }),
            ),
          )
          #v(1.7mm)
          #grid(
            columns: (auto, auto) + if per != none { (auto,) } else { () },
            column-gutter: 2.5mm,
            align: (top, top) + if per != none { (top,) } else { () },
            text(font: fm, size: 4.9pt, weight: 500, tracking: 0.18em, fill: fg-subtle, cur),
            pad(top: 0.9mm, text(font: fd, size: 20.8pt, weight: 300, tracking: -0.03em, fill: ink, fee.amount)),
            ..if per != none { (
              pad(top: 0.9mm, text(font: fs, size: 6.8pt, weight: 300, style: "italic", fill: fg-muted, per)),
            ) } else { () },
          )
          #if desc != none and desc != "" [
            #v(1.5mm)
            #text(font: ("Inter", "Helvetica Neue"), size: 7pt, weight: 400, fill: fg-muted, desc)
          ]
        ]
      })
    )
  }


  v(1fr)

  // ─── SIGNATURES ───────────────────────────────────────────────
  if sigs.len() > 0 {
    block(width: 100%)[
      #grid(
        columns: sigs.map(_ => 1fr),
        column-gutter: 12mm,
        ..sigs.map(sig => block(above: 0pt)[
          #line(length: 100%, stroke: 0.5pt + ink)
          #v(3.5mm)
          #text(font: ("Inter", "Helvetica Neue"), size: 12pt, weight: 500, fill: ink, sig.name)
          #linebreak()
          #v(2mm)
          #text(font: fs, size: 11.5pt, weight: 300, style: "italic", fill: primary, sig.company)
          #v(2.5mm)
          #text(font: fm, size: 6pt, weight: 300, tracking: 0.18em, fill: fg-subtle, upper(sig.role))
        ])
      )
    ]
  }

  v(8mm)

}
