#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  body-fontsize: 9pt,
  title-size: 1.35em,
  subtitle-size: 1.05em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
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
  let chanwe-logo = "_extensions/chanwe-brand/assets/Logo_Negro1.png"
  let chanwe-logo-beige = "_extensions/chanwe-brand/assets/Logo_Beige1.png"
  let chanwe-logo-color = "_extensions/chanwe-brand/assets/Logo_Color1.png"
  let chanwe-icons-color = "_extensions/chanwe-brand/assets/Iconos_Color.png"
  let chanwe-icons-beige = "_extensions/chanwe-brand/assets/Iconos_Beige.png"
  let chanwe-estrategia-color = "_extensions/chanwe-brand/assets/Estrategia_Color1.png"
  let chanwe-decoration = "_extensions/chanwe-brand/assets/decoration.svg"
  let light-gray = rgb("#EEEEEE")
  let muted-gray = rgb("#6B6B6B")
  let body-color = rgb("#484848")
  let brand-orange = rgb("#E94B2B")
  let page-white = rgb("#FFFFFF")
  let content-page-margin = (x: 1in, y: 1in)
  let output-radius = 14pt

  let page-header = context block(inset: (bottom: 0.1in))[
    #grid(
      columns: (1fr, 1fr),
      align(left)[#image(chanwe-icons-color, width: 1.6cm)],
      align(right)[#image(chanwe-logo-color, width: 2.8cm)]
    )
    #v(0.08in)
    #rect(width: 100%, height: 0.8pt, fill: black, stroke: none)
  ]

  let page-footer = context block(inset: (top: 0.02in))[
    #rect(width: 100%, height: 0.5pt, fill: rgb("#D9D9D9"), stroke: none)
    #v(0.09in)
    #align(center)[
      #text(size: 0.95em, weight: "semibold", fill: brand-orange)[
        #counter(page).display(pagenumbering)
      ]
    ]
  ]

  set par(justify: true)
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
      (..nums) => text(weight: "bold", fill: brand-orange)[
        #numbering(sectionnumbering, ..nums)
      ]
    }
  )
  show heading: set text(
    font: heading-family,
    weight: "bold",
    style: heading-style,
    fill: black
  )
  show heading.where(level: 1): it => {
    [
      #pagebreak(weak: true)
      #block(above: 1.2em, below: 0.9em)[
        #it
        #v(0.08em)
        #rect(width: 100%, height: 0.45pt, fill: rgb("#D9D9D9"), stroke: none)
      ]
    ]
  }
  show heading.where(level: 2): it => block(above: 3.2em, below: 2.4em)[#it]
  show heading.where(level: 3): it => block(above: 3.2em, below: 2.4em)[#it]
  show heading.where(level: 4): it => block(above: 3.2em, below: 2.4em)[#it]
  show heading.where(level: 5): it => block(above: 3.2em, below: 2.4em)[#it]
  show heading.where(level: 6): it => block(above: 3.2em, below: 2.4em)[#it]

  // Round outer corners of rendered plot and table figures.
  show figure.where(kind: image): it => block(
    fill: page-white,
    radius: output-radius,
    clip: true
  )[
    #it
  ]
  show figure.where(kind: table): it => block(
    fill: page-white,
    radius: output-radius,
    clip: true
  )[
    #it
  ]

  // Cover page
  set page(margin: 0pt, numbering: none, columns: 1, background: none, fill: page-white)
  place(top + left)[
    #block(inset: (left: 0.9in, top: 0.55in))[
      #image(chanwe-icons-color, width: 1.6cm)
    ]
  ]
  place(top + right)[
    #block(inset: (right: -1.0in, top: -0.7in))[
      #image(chanwe-decoration, width: 32cm)
    ]
  ]
  place(top + left)[
    #block(inset: (left: 0.9in, top: 1.34in))[
      #text(weight: "bold", fill: brand-orange)[Mendoza - Argentina]
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0in))[
      #image(chanwe-logo-color, width: 100%)
    ]
  ]
  align(left + horizon)[#block(width: 76%, inset: (x: 0.9in, y: 0.6em), below: 0.4em)[
    #set par(justify: false)
    #if title != none {
      set par(leading: 0.62em)
      set text(
        font: heading-family,
        style: heading-style,
        fill: black
      )
      text(weight: 900, size: 36pt)[#title]
    }
    #if subtitle != none {
      v(0.45em)
      set par(leading: 0.82em)
      text(weight: "bold", size: 16pt, fill: muted-gray)[#subtitle]
    }
    #if subtitle != none and authors != none {
      v(0.55em)
      rect(width: 100%, height: 0.5pt, fill: rgb("#D9D9D9"), stroke: none)
      v(0.55em)
    }
    #if authors != none {
      set par(leading: 1em)
      v(1.1em)
      let count = authors.len()
      let ncols = calc.min(count, 3)
      grid(
        columns: (1fr,) * ncols,
        row-gutter: 0.7em,
        ..authors.map(author =>
          align(left)[
            #text(fill: brand-orange)[#author.name] \
            #author.affiliation \
            #author.email
          ]
        )
      )
    }
    #if date != none {
      v(0.25em)
      text(size: 0.88em, fill: muted-gray)[#date]
    }
  ]]

  pagebreak()

  // Second page: beige icon on top and beige logo at the bottom.
  set page(margin: content-page-margin, numbering: none, columns: 1, background: none, fill: page-white)
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
  set page(
    margin: content-page-margin,
    numbering: none,
    columns: 1,
    background: none,
    fill: page-white,
    header: page-header,
    footer: page-footer
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
            column-gutter: 0.14em,
            image(chanwe-estrategia-color, width: 0.18cm),
            text(weight: "bold", fill: brand-orange)[#prefix]
          )
        } else {
          text(weight: "bold", fill: brand-orange)[#prefix]
        }
      }
      block(above: 0.9em, below: 0.9em)[
        #link(
          it.element.location(),
          [
            #set text(fill: black, weight: "regular")
            #grid(
              columns: (1fr, auto),
              column-gutter: 0.6em,
              it.indented(styled-prefix, it.body()),
              align(right)[#it.page()]
            )
          ]
        )
        #v(0.28em)
        #rect(width: 100%, height: 0.55pt, fill: rgb("#D9D9D9"), stroke: none)
      ]
    }
    let toc_text = if toc_title == none {
      [Table of contents]
    } else {
      toc_title
    }
    block(above: 0.2em, below: 0.25em)[#text(size: 1.22em, weight: "bold", fill: brand-orange)[#toc_text]]
    rect(width: 100%, height: 0.8pt, fill: black, stroke: none)
    v(0.55em)
    outline(
      title: none,
      depth: toc_depth,
      indent: toc_indent
    )
  }

  pagebreak()

  if cols != 1 {
    set page(margin: content-page-margin, columns: cols)
  }

  if cols == 1 {
    doc
  } else {
    doc
  }

  // Back cover
  pagebreak()
  set page(margin: 0pt, numbering: none, columns: 1, background: none, fill: page-white, header: none, footer: none)
  place(top + center)[
    #block(inset: (top: 1.1in))[
      #image(chanwe-icons-color, width: 8cm)
    ]
  ]
  place(center + horizon)[
    #block(width: 78%, inset: (x: 1.35in, y: 0.62in))[
      #align(center)[
        #stack(
          dir: ttb,
          spacing: 0.95em,
          text(size: 1.05em, weight: "bold", fill: brand-orange)[Mendoza - Argentina],
          v(1.2em),
          text(size: 0.95em, fill: muted-gray)[chanwe.ar],
          text(size: 0.95em, fill: muted-gray)[2026],
          v(1.4em),
          text(size: 0.78em, fill: muted-gray)[Informacion confidencial prohibida su distribucion sin autorizacion],
          v(4.2em),
          rect(width: 62%, height: 0.5pt, fill: rgb("#C9C9C9"), stroke: none)
        )
      ]
    ]
  ]
  place(bottom + center)[
    #block(inset: (bottom: 0.45in))[
      #image(chanwe-logo, width: 94%)
    ]
  ]
}

#set table(
  inset: 6pt,
  stroke: none
)
