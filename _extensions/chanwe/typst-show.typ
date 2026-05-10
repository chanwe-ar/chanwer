// =============================================================
// typst-show.typ — Quarto metadata → chanwe() template call
// =============================================================
// This is the bridge: Quarto fills $title$, $subtitle$, etc. from
// the YAML front-matter of the .qmd file. Custom keys live under
// `chanwe:` and are mapped here.
// =============================================================

#show: doc => chanwe(
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
$if(chanwe.chapter)$
  chapter: "$chanwe.chapter$",
$endif$
$if(chanwe.section)$
  section: "$chanwe.section$",
$endif$
$if(chanwe.topic)$
  topic: "$chanwe.topic$",
$endif$
$if(chanwe.rail-eyebrow)$
  rail-eyebrow: "$chanwe.rail-eyebrow$",
$endif$
$if(chanwe.cover-eyebrow)$
  cover-eyebrow: "$chanwe.cover-eyebrow$",
$endif$
$if(chanwe.hero-image)$
  hero-image: "$chanwe.hero-image$",
$endif$
$if(chanwe.wordmark)$
  wordmark: "$chanwe.wordmark$",
$endif$
$if(chanwe.cover)$
  cover: $chanwe.cover$,
$endif$
$if(chanwe.toc)$
  toc: $chanwe.toc$,
$endif$
$if(chanwe.toc-eyebrow)$
  toc-eyebrow: "$chanwe.toc-eyebrow$",
$endif$
$if(chanwe.toc-title)$
  toc-title: "$chanwe.toc-title$",
$endif$
$if(chanwe.toc-lede)$
  toc-lede: [$chanwe.toc-lede$],
$endif$
$if(chanwe.abstract-eyebrow)$
  abstract-eyebrow: "$chanwe.abstract-eyebrow$",
$endif$
$if(chanwe.abstract-title)$
  abstract-title: [$chanwe.abstract-title$],
$endif$
$if(chanwe.abstract-text)$
  abstract-text: [$chanwe.abstract-text$],
$endif$
$if(chanwe.abstract-keywords)$
  abstract-keywords: ($for(chanwe.abstract-keywords)$"$it$"$sep$, $endfor$),
$endif$
$if(chanwe.abstract-status)$
  abstract-status: "$chanwe.abstract-status$",
$endif$
$if(chanwe.abstract-show)$
  abstract-show: ($for(chanwe.abstract-show)$"$it$"$sep$, $endfor$),
$endif$
$if(chanwe.abstract-takeaway)$
  abstract-takeaway: "$chanwe.abstract-takeaway$",
$endif$
$if(chanwe.stamp)$
  stamp: ($for(chanwe.stamp)$"$it$"$sep$, $endfor$),
$endif$
$if(chanwe.hero-date)$
  hero-date: "$chanwe.hero-date$",
$endif$
$if(chanwe.meta-rows)$
  meta-rows: (
$for(chanwe.meta-rows)$
    ("$it.label$", "$it.value$", $if(it.sub)$"$it.sub$"$else$none$endif$),
$endfor$
  ),
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
$if(chanwe.cover-edge)$
  cover-edge: "$chanwe.cover-edge$",
$endif$
$if(chanwe.cover-edge-color)$
  cover-edge-color: rgb("#$chanwe.cover-edge-color$"),
$endif$
$if(chanwe.page-bg)$
  page-bg: rgb("#$chanwe.page-bg$"),
$endif$
  doc,
)
