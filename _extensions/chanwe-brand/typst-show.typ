// =============================================================
// chanwe-brand - typst-show.typ
// Quarto metadata -> chanwe-brand-book() template call.
// =============================================================

#show: doc => chanwe-brand-book(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(by-author)$
  author: "$for(by-author)$$it.name.literal$$sep$, $endfor$",
$endif$
$if(date)$
  date: "$date$",
$endif$
$if(chanwe.document)$
  doc-id: "$chanwe.document$",
$endif$
$if(chanwe.edition)$
  edition: "$chanwe.edition$",
$endif$
$if(chanwe.volume)$
  volume: "$chanwe.volume$",
$endif$
$if(chanwe.rail-eyebrow)$
  rail-eyebrow: "$chanwe.rail-eyebrow$",
$endif$
$if(chanwe.hero-image)$
  hero-image: "$chanwe.hero-image$",
$endif$
$if(chanwe.hero-caption-1)$
  hero-caption-1: "$chanwe.hero-caption-1$",
$endif$
$if(chanwe.hero-caption-2)$
  hero-caption-2: "$chanwe.hero-caption-2$",
$endif$
$if(chanwe.publication-period)$
  publication-period: "$chanwe.publication-period$",
$endif$
$if(chanwe.publication-series)$
  publication-series: "$chanwe.publication-series$",
$endif$
$if(chanwe.publication-location)$
  publication-location: "$chanwe.publication-location$",
$endif$
$if(chanwe.cover)$
  cover: $chanwe.cover$,
$endif$
$if(chanwe.cover-edge)$
  cover-edge: "$chanwe.cover-edge$",
$endif$
$if(chanwe.meta-rows)$
  meta-rows: (
$for(chanwe.meta-rows)$
    ("$it.label$", "$it.value$", $if(it.sub)$"$it.sub$"$else$none$endif$),
$endfor$
  ),
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-depth)$
  toc-depth: $toc-depth$,
$endif$
$if(toc-title)$
  toc-title: "$toc-title$",
$endif$
$if(chanwe.toc-eyebrow)$
  toc-eyebrow: "$chanwe.toc-eyebrow$",
$endif$
$if(chanwe.toc-lede)$
  toc-lede: [$chanwe.toc-lede$],
$endif$
$if(chanwe.back-cover)$
  back-cover: $chanwe.back-cover$,
$endif$
$if(chanwe.back-cover-tagline-1)$
  back-cover-tagline-1: "$chanwe.back-cover-tagline-1$",
$endif$
$if(chanwe.back-cover-tagline-2)$
  back-cover-tagline-2: "$chanwe.back-cover-tagline-2$",
$endif$
$if(chanwe.back-cover-cols)$
  back-cover-cols: (
$for(chanwe.back-cover-cols)$
    ("$it.label$", "$it.value$", $if(it.sub)$"$it.sub$"$else$none$endif$),
$endfor$
  ),
$endif$
$if(sectionnumbering)$
  section-numbering: "$sectionnumbering$",
$endif$
$if(chanwe.page-bg)$
  page-bg: rgb("#$chanwe.page-bg$"),
$endif$
  doc,
)
