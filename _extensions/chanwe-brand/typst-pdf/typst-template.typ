#let article(
  title: none,
  subtitle: none,
  subject: none,
  topic: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  keywords: (),
  cols: 1,
  lang: "en",
  region: "US",
  font: "DM Sans 9pt",
  fontsize: 11pt,
  body-fontsize: 9pt,
  title-size: 1.35em,
  subtitle-size: 1.05em,
  heading-family: "DM Sans 12pt",
  heading-weight: "black",
  heading-weight-level1: 900,
  heading-weight-rest: none,
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.85em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  pagenumbering: "1",
  doc,
) = {
  let chanwe-logo = "/_extensions/chanwe-brand/assets/Logo_Negro1.png"
  let chanwe-logo-beige = "/_extensions/chanwe-brand/assets/Logo_Blanco.png"
  let chanwe-logo-color = "/_extensions/chanwe-brand/assets/Logo_Color1.png"
  let chanwe-icons-color = "/_extensions/chanwe-brand/assets/Iconos_Color.png"
  let chanwe-icons-beige = "/_extensions/chanwe-brand/assets/Iconos_Blanco.png"
  let chanwe-icons-beige-true = "/_extensions/chanwe-brand/assets/Iconos_Beige.png"
  let chanwe-estrategia-color = "/_extensions/chanwe-brand/assets/Estrategia_Color1.png"
  let chanwe-estrategia-beige = "/_extensions/chanwe-brand/assets/Estrategia_Beige1.png"
  let chanwe-decoration = "/_extensions/chanwe-brand/assets/decoration.svg"
  let chanwe-bg-mountains = "/_extensions/chanwe-brand/assets/bg_mountains.jpg"
  let chanwe-bg-transparent = "/_extensions/chanwe-brand/assets/bg_transparent.png"
  let chanwe-pattern = "/_extensions/chanwe-brand/assets/pattern.jpg"
  let light-gray = rgb("#EEEEEE")
  let muted-gray = rgb("#6B6B6B")
  let body-color = rgb("#666666")
  let brand-orange = rgb("#E94B2B")
  let page-white = rgb("#FFFFFF")
  let cover-bg = rgb("#F7F7F7")
  let content-page-margin = (x: 1in, y: 1in)
  let output-radius = 30pt
  let plot-radius = 12pt
  let cover-left-inset = 0.9in
  let cover-content-width = 92%
  let cover-pill-gap = 0.22in
  let level1-heading-weight = if heading-weight-level1 == none { heading-weight } else { heading-weight-level1 }
  let rest-heading-weight = if heading-weight-rest == none { heading-weight } else { heading-weight-rest }
  let cover-pill(label, fill-color, text-color) = rect(
    radius: 3pt,
    fill: fill-color,
    stroke: none,
    inset: (x: 0.8em, y: 0.42em)
  )[
    #text(size: 7.65pt, weight: 600, fill: text-color)[#label]
  ]

  let page-header = context none

  let page-footer = context block(inset: (top: 0.12in))[
    #grid(
      columns: (auto, 1fr, auto),
      column-gutter: 0.6em,
      align: (left + horizon, center + horizon, right + horizon),
      [
        #if topic != none {
          text(weight: "bold", fill: black)[#topic]
        }
        #if topic != none and subject != none {
          h(0.6em)
        }
        #if subject != none {
          text(weight: 400, fill: muted-gray)[#subject]
        }
      ],
      rect(width: 100%, height: 0.5pt, fill: rgb("#D9D9D9"), stroke: none),
      box(fill: brand-orange, inset: (x: 0.7em, y: 0.4em))[
        #text(size: 0.79em, weight: "black", fill: white)[
          #counter(page).display(pagenumbering)
        ]
      ]
    )
  ]

  set par(justify: true, leading: 1.05em, spacing: 2.5em)
  set text(
    lang: lang,
    region: region,
    font: font,
    size: body-fontsize,
    fill: body-color
  )
  set page(fill: page-white)
  set heading(
    numbering: if sectionnumbering == none {
      none
    } else {
      (..nums) => text(weight: "black", fill: brand-orange)[
        #numbering(sectionnumbering, ..nums)
      ]
    }
  )
  show heading.where(level: 1): set text(
    font: "DM Sans 9pt",
    weight: level1-heading-weight,
    style: "normal",
    fill: black,
    tracking: -0.8pt
  )
  show heading.where(level: 2): set text(
    font: "DM Sans 9pt",
    size: 1.54em,
    weight: rest-heading-weight,
    style: "normal",
    fill: black
  )
  show heading.where(level: 3): set text(
    font: "DM Sans 9pt",
    size: 1.54em,
    weight: rest-heading-weight,
    style: "normal",
    fill: black
  )
  show heading.where(level: 4): set text(
    font: heading-family,
    size: 1.54em,
    weight: rest-heading-weight,
    style: heading-style,
    fill: black
  )
  show heading.where(level: 5): set text(
    font: heading-family,
    size: 1.54em,
    weight: rest-heading-weight,
    style: heading-style,
    fill: black
  )
  show heading.where(level: 6): set text(
    font: heading-family,
    size: 1.54em,
    weight: rest-heading-weight,
    style: heading-style,
    fill: black
  )
  show heading.where(level: 1): it => {
    [
      #pagebreak(weak: true)
      #layout(avail => {
        let rect-h = 8cm
        block(above: 5.4em, below: 0em, width: 100%, height: rect-h)[
          #place(top + left, dx: -0.35in)[
            #pad(top: 10pt)[
              #block(
                width: avail.width + 0.65in,
                height: rect-h,
                stroke: none,
                radius: 8pt,
                clip: true,
                fill: none,
              )[
                #place(top + left, image(chanwe-pattern, width: avail.width + 0.65in, height: rect-h, fit: "cover"))
                #place(top + left, rect(
                  width: 100%,
                  height: rect-h,
                  fill: gradient.conic(
                    (luma(255).transparentize(40%), 0%),
                    (luma(240).transparentize(70%), 35%),
                    (luma(250).transparentize(78%), 55%),
                    (luma(244).transparentize(74%), 75%),
                    (luma(255).transparentize(40%), 100%),
                    center: (0%, 50%)
                  ),
                  stroke: none,
                ))
              ]
            ]
          ]
          #place(top + left)[
            #v(3em)
            #image(chanwe-estrategia-color, width: 2.25cm)
          ]
          #place(bottom + left)[
            #pad(bottom: 2.2em)[
              #text(size: 2.454em, tracking: -0.8pt)[#it]
            ]
          ]
        ]
      })
      #v(2.5cm)
    ]
  }
  show heading.where(level: 2): it => block(above: 2.781em, below: 1.377em)[
    #it
    #v(0.25em)
    #rect(width: 100%, height: 0.5pt, fill: rgb("#EFEFEF"), stroke: none)
  ]
  show heading.where(level: 3): it => block(above: 2.781em, below: 1.377em)[#it]
  show heading.where(level: 4): it => block(above: 2.781em, below: 1.377em)[#it]
  show heading.where(level: 5): it => block(above: 2.781em, below: 1.377em)[#it]
  show heading.where(level: 6): it => block(above: 2.781em, below: 1.377em)[#it]

  show math.equation: set text(size: 1.3em)

  // Round outer corners of rendered plot and table figures.
  show figure.where(kind: image): it => block(
    fill: page-white,
    radius: plot-radius,
    stroke: rgb("#F7F7F7"),
    clip: true
  )[
    #it
  ]
  show figure.where(kind: table): it => block(
    fill: page-white,
    radius: plot-radius,
    stroke: rgb("#F7F7F7"),
    clip: true
  )[
    #it
  ]

  // Cover page
  set page(margin: 0pt, numbering: none, columns: 1, background: none, fill: cover-bg)
  place(top + left)[
    #pad(left: 15pt, right: 15pt, top: 15pt)[
      #block(width: 100%, height: 33%, clip: true, stroke: none, fill: none, radius: 20pt)[
        #layout(avail => context {
          let img = image(chanwe-bg-mountains, width: avail.width)
          let img-h = measure(img).height
          place(top + center, dy: (img-h / 3))[#img]
        })
        #place(top + left)[
          #rect(width: 100%, height: 100%, fill: luma(220).transparentize(40%), stroke: none)
        ]
        #place(bottom + left, dy: -5pt)[
          #pad(left: 0.9in - 15pt, bottom: 10pt)[
            #stack(dir: ltr, spacing: 10pt,
              image(chanwe-icons-color, width: 2.5cm),
              align(horizon)[
                #rect(width: 15cm, height: 1pt, fill: muted-gray, stroke: none)
              ]
            )
          ]
        ]
      ]
    ]
  ]
  place(top + left)[
    #block(inset: (left: cover-left-inset, top: 0.55in))[
      #stack(dir: ttb, spacing: 0.8em,
        text(font: "DM Sans 9pt", weight: 900, size: 10pt, fill: brand-orange)[ESTRATEGIA ACTIVA],
        text(font: "DM Sans 9pt", weight: 900, size: 6pt, fill: brand-orange)[MENDOZA - ARGENTINA],
      )
    ]
  ]
  place(top + right)[
    #block(inset: (right: 0.5in, top: 0.4in))[
      #image(chanwe-estrategia-color, width: 4.131cm)
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0.3in))[
      #image(chanwe-logo, width: 88%)
    ]
  ]
  align(left + bottom)[#block(width: cover-content-width, inset: (left: cover-left-inset, right: 0.4in, top: 0.6em, bottom: 2.4in), below: 0.4em)[
    #set par(justify: false)
    #stack(
      dir: ttb,
      spacing: 2.2em,
      if subject != none or topic != none {
        stack(
          dir: ltr,
          spacing: cover-pill-gap,
          if subject != none { cover-pill(subject, brand-orange, page-white) },
          if topic != none { cover-pill(topic, muted-gray, page-white) }
        )
      },
      if title != none {
        block(above: 0pt, below: 0pt)[
          #set par(leading: 0.30em)
          #text(font: "DM Sans 9pt", style: "normal", weight: 900, size: 46pt, fill: black, tracking: -1.5pt)[#title]
        ]
      }
    )
    #if subtitle != none {
      v(0.7em)
      set par(leading: 0.40em)
      text(weight: 500, size: 13pt, fill: muted-gray)[#subtitle]
    }
    #if subtitle != none {
      v(5.55em)
      rect(width: 65%, height: 0.5pt, fill: rgb("#D9D9D9"), stroke: none)
      v(0.4em)
      if date != none {
        text(size: 0.88em, fill: muted-gray)[#date]
        v(0.2em)
      }
      if authors != none {
        set par(leading: 0em)
        let count = authors.len()
        let ncols = calc.min(count, 3)
        grid(
          columns: (1fr,) * ncols,
          row-gutter: 0.7em,
          ..authors.map(author =>
            align(left)[
              #text(fill: muted-gray)[#author.name]
              #if author.affiliation != none [\ #author.affiliation]
              #if author.email != none [\ #author.email]
            ]
          )
        )
      }
    }
  ]]

  pagebreak()

  // Second page: beige icon on top and beige logo at the bottom.
  set page(margin: content-page-margin, numbering: none, columns: 1, background: none, fill: cover-bg)
  place(top + center)[
    #block(inset: (top: 1.1in))[
      #image(chanwe-icons-beige, width: 8cm)
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0.45in))[
      #image(chanwe-logo-beige, width: 94%)
    ]
  ]

  pagebreak()

  // TOC page
  counter(page).update(1)
  let toc_text = if toc_title == none { [AGENDA] } else { toc_title }
  set page(
    margin: content-page-margin,
    numbering: none,
    columns: 1,
    background: if toc {
      align(left + top)[
        #block(width: 20%, height: 100%, fill: light-gray.transparentize(50%))[
          #place(right + horizon, dx: 2.6em)[
            #rotate(-90deg, reflow: false)[
              #text(size: 12em, weight: 900, font: "DM Sans 9pt", fill: white)[#toc_text]
            ]
          ]
        ]
      ]
    },
    fill: page-white,
    header: none,
    footer: none
  )
  if toc {
    show outline.entry: it => {
      let prefix = it.prefix()
      let is-level-1 = it.level == 1
      let styled-prefix = if prefix == none {
        none
      } else {
        if is-level-1 {
          grid(
            columns: (auto, auto),
            column-gutter: 0.22em,
            align(bottom, image(chanwe-estrategia-color, width: 0.25cm)),
            text(size: 1.4em, weight: "bold", fill: brand-orange)[#prefix]
          )
        } else {
          text(weight: "bold", fill: brand-orange)[#prefix]
        }
      }
      block(above: if is-level-1 { 3.6em } else { 1.4em }, below: 0.9em)[
        #if is-level-1 {
          rect(width: 100%, height: 0.55pt, fill: rgb("#EFEFEF"), stroke: none)
          v(0.28em)
        }
        #pad(left: if is-level-1 { 0em } else { (it.level - 1) * 1.8em })[
          #link(
            it.element.location(),
            [
              #set text(fill: black, weight: "bold", size: if is-level-1 { 1.2em } else { 1em })
              #grid(
                columns: (1fr, auto),
                align: (left + top, right + bottom),
                column-gutter: 0.6em,
                it.indented(styled-prefix, if is-level-1 { text(size: 1.2em, weight: 900, font: "DM Sans 9pt")[#it.body()] } else { text(weight: "regular")[#it.body()] }),
                align(right + bottom)[#it.page()]
              )
            ]
          )
        ]
      ]
    }
    layout(size => {
      let page-w = size.width + 2 * content-page-margin.x
      let sidebar-w = page-w * 0.20
      let content-offset = sidebar-w - content-page-margin.x
      pad(left: content-offset + 0.35in)[
        #outline(title: none, depth: toc_depth, indent: toc_indent)
      ]
    })
  }

  pagebreak()

  // Reset body pages to white after TOC pages.
  set page(
    fill: page-white,
    header: none,
    footer: page-footer,
    background: align(top + left)[
      #block(width: 100%, height: 0.4125in, fill: light-gray.transparentize(50%))[
        #align(right + horizon)[
          #pad(right: content-page-margin.x)[
            #image(chanwe-logo-color, width: 1.87cm)
          ]
        ]
      ]
    ]
  )

  if cols != 1 {
    set page(margin: content-page-margin, columns: cols)
  }

  // Abstract page — first page after TOC
  if abstract != none or topic != none or subject != none or keywords.len() > 0 {
    align(center + horizon)[
      #block(width: 68%)[
        #if abstract != none {
          block(width: 100%, inset: (top: 2.5em, bottom: 2.5em))[
            #text(size: 4em, weight: 900, fill: brand-orange, font: "DM Sans 9pt")[ABSTRACT]
            #linebreak()
            #linebreak()
            #image(chanwe-icons-beige-true, width: 3cm)
          ]
          rect(width: 100%, radius: 12pt, fill: light-gray.transparentize(70%), stroke: none, inset: (x: 3em, y: 2.2em))[
            #text(size: 0.95em, fill: body-color)[#abstract]
          ]
          v(1.3em)
        }
        #rect(width: 100%, height: 1.5pt, fill: brand-orange, stroke: none)
        #v(1.3em)
        #if keywords.len() > 0 {
          for kw in keywords {
            box(inset: (x: 7pt, y: 4pt), radius: 3pt, fill: light-gray)[
              #text(size: 0.8em, weight: "bold")[#kw]
            ]
            h(5pt)
          }
          v(1.2em)
        }
        #stack(dir: ltr, spacing: cover-pill-gap,
          if subject != none { cover-pill(subject, brand-orange, page-white) },
          if topic != none { cover-pill(topic, muted-gray, page-white) }
        )
      ]
    ]
    pagebreak()
  }

  if cols == 1 {
    doc
  } else {
    doc
  }

  // Pre-back cover: repeat second cover page
  pagebreak()
  set page(margin: content-page-margin, numbering: none, columns: 1, background: none, fill: cover-bg, header: none, footer: none)
  place(top + center)[
    #block(inset: (top: 1.1in))[
      #image(chanwe-icons-beige, width: 8cm)
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0.45in))[
      #image(chanwe-logo-beige, width: 94%)
    ]
  ]

  // Back cover
  pagebreak()
  set page(margin: 0pt, numbering: none, columns: 1, background: none, fill: black, header: none, footer: none)
  place(top + center)[
    #block(inset: (top: 1.1in))[
      #image(chanwe-icons-color, width: 3cm)
    ]
  ]
  place(center + horizon)[
    #block(width: 78%, inset: (x: 1.35in, y: 0.62in))[
      #align(center)[
        #stack(
          dir: ttb,
          spacing: 1.35em,
          text(size: 1.00em, weight: "thin", fill: cover-bg)[Mendoza - Argentina],
          v(3em),
          text(font: "DM Sans 9pt", size: 1.22em, weight: 900, fill: cover-bg)[chanwe.ar],
          text(font: "DM Sans 9pt", size: 0.95em, weight: 900, fill: cover-bg)[2026],
          v(3em),
          text(size: 0.78em, weight: "thin", fill: cover-bg)[Informacion confidencial prohibida su distribucion sin autorizacion],
          v(8em),
          image(chanwe-estrategia-color, width: 2cm)
        )
      ]
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0.45in))[
      #image(chanwe-logo-beige, width: 94%)
    ]
  ]
}

#set table(
  inset: 6pt,
  stroke: none
)
