#let chapter-cover-counter = counter("chapter-cover")

#let chapter-cover(title: none, body: none, img: none) = {
  let brand-orange = rgb("#E94B2B")
  let bg-mountains = "/_extensions/chanwe-brand/assets/bg_mountains.jpg"
  chapter-cover-counter.step()
  page(
    fill: white,
    margin: 0pt,
    header: none,
    footer: none,
    numbering: none,
  )[
    #layout(size => {
      let img-h = size.height * 0.4
      let text-h = size.height - img-h

      place(top + left)[
        #block(width: 100%, height: img-h, clip: true)[
          #if img != none {
            image(img, width: 100%, height: 100%, fit: "cover")
          } else {
            image(bg-mountains, width: 100%, height: 100%, fit: "cover")
          }
          #place(top + left, rect(width: 100%, height: 100%, fill: black.transparentize(45%), stroke: none))
        ]
      ]

      place(top + left, dy: img-h)[
        #block(width: 65%, height: text-h)[
          #align(left + horizon)[
            #set align(left)
            #set par(justify: false, leading: 0.42em)
            #pad(left: 1.2in, right: 0.6in)[
              #text(size: 4.2em, weight: 900, font: "DM Sans 9pt", fill: black, stroke: 0.4pt + black, tracking: -1.2pt)[#title]
              #if body != none {
                v(1em)
                rect(width: 3cm, height: 3pt, fill: brand-orange, stroke: none)
                v(0.8em)
                text(size: 1.05em, fill: rgb("#444444"))[#body]
              }
            ]
          ]
        ]
      ]

      context {
        let num = chapter-cover-counter.get().first()
        let estrategia-color = "/_extensions/chanwe-brand/assets/Estrategia_Color1.png"
        let pill = box(
          inset: (x: 28pt, y: 18pt),
          radius: 14pt,
          fill: luma(248),
          stroke: none,
        )[#stack(dir: ltr, spacing: 14pt,
            align(horizon, image(estrategia-color, height: 3.5em)),
            align(horizon, text(size: 7.2em, weight: 900, font: "DM Sans 9pt", fill: rgb("#111111"))[#numbering("1", num)])
          )]
        let pill-h = measure(pill).height
        place(top + center, dy: img-h - pill-h / 2)[#pill]
      }
    })
  ]
}

#show: doc => article(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(subject)$
  subject: [$subject$],
$endif$
$if(topic)$
  topic: [$topic$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
$if(abstract)$
  abstract: [$abstract$],
  abstract-title: "$labels.abstract$",
$endif$
$if(keywords)$
  keywords: ($for(keywords)$[$keywords$],$endfor$),
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  font: $brand.typography.base.family$,
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$elseif(brand.typography.base.size)$
  fontsize: $brand.typography.base.size$,
$endif$
$if(title)$
$if(brand.typography.headings.family)$
  heading-family: $brand.typography.headings.family$,
$endif$
$if(brand.typography.headings.weight)$
  heading-weight: $brand.typography.headings.weight$,
$endif$
$if(brand.typography.headings.style)$
  heading-style: "$brand.typography.headings.style$",
$endif$
$if(brand.typography.headings.color)$
  heading-color: $brand.typography.headings.color$,
$endif$
$if(brand.typography.headings.line-height)$
  heading-line-height: $brand.typography.headings.line-height$,
$endif$
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-indent)$
  toc_indent: $toc-indent$,
$endif$
  toc_depth: $toc-depth$,
  cols: $if(columns)$$columns$$else$1$endif$,
  doc,
)
