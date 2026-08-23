# chanwer

`chanwer` provides ChanWe brand themes for ggplot2 charts, native Typst
tables, and Quarto reporting workflows.

The package is built around a small set of entry points. If you know
which output you are producing, you should be able to choose the right
helper quickly.

## Installation

```r
# install.packages("pak")
pak::pak("chanwe-ar/chanwer")
```

For local development:

```r
devtools::install(".")
```

## What is included

- `chanwe_palette()` — exact named color tokens and grouped palettes
  (core brand, `p13`/`p14`/`p15` ramps, `mb` main-brand scale, semantic,
  and the editorial 8-color chart palette).
- `theme_chanwe()` — the editorial ggplot2 theme with custom title,
  subtitle, KPI-scoreboard, and caption elements.
- `chanwe_title()`, `chanwe_subtitle()`, `chanwe_kpi()`,
  `chanwe_caption()` — label helpers for the full header treatment.
- `scale_color_chanwe_d()` / `scale_fill_chanwe_d()` — discrete brand
  scales (any palette group, `reverse` supported);
  `scale_color_chanwe_c()` / `scale_fill_chanwe_c()` — named sequential
  gradients; `scale_color_chanwe_div()` / `scale_fill_chanwe_div()` —
  the diverging negative/neutral/positive scale.
- `chanwe_kbl()` — native Typst table generator for Quarto PDF reports,
  with `chanwe_col_signed()` for positive/negative value coloring.
- `chanwe_load_fonts()` — registers the brand fonts with `systemfonts`.
- `chanwe_reporting_css()` — bundled SCSS for Quarto HTML output.
- `chanwe_brand_tokens()` and `chanwe_preview_palette()` — utilities.

## Quick Start

```r
library(chanwer)
library(ggplot2)

chanwe_palette("chart")

ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  labs(
    title = chanwe_title("Fuel economy vs weight"),
    subtitle = "ChanWe scatter",
    caption = chanwe_caption("Source: mtcars")
  ) +
  theme_chanwe()
```

## ggplot2 Pattern

This is the canonical pattern for ChanWe charts.

```r
library(chanwer)
library(ggplot2)

ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3, alpha = 0.9) +
  scale_color_chanwe_d() +
  labs(
    title = chanwe_title("Fuel economy vs weight", eyebrow = "SECTION - FLEET"),
    subtitle = "Editorial scatter",
    x = "Weight",
    y = "MPG",
    color = "Cylinders",
    caption = chanwe_caption("Source: Motor Trend, 1974")
  ) +
  theme_chanwe(bg_color = "beige")
```

The main decisions:

- `bg_color` picks the surface: `"metallic"` (default, `#F7F7F7`),
  `"white"`, `"white-ivory"`, `"gray"`, `"beige"`, `"transparent"`, or
  any hex string. Grid line colors adapt automatically.
- `chanwe_title(text, eyebrow = "...")` adds the orange mono-caps
  eyebrow line above the title. Plain titles need no helper.
- `has_subtitle = FALSE` tightens the header when there is no subtitle.
- `compact_title` / `header_line` / `plot_borders` fine-tune the header
  spacing, separator rule, and decorative frame lines.

### KPI scoreboard

`chanwe_kpi()` builds a scoreboard panel that sits between the subtitle
and the chart — a hero value with unit and date on the left, up to three
period metrics (WoW / MoM / YoY with ▲/▼ direction) on the right. Always
wrap it in `chanwe_subtitle()`:

```r
labs(
  subtitle = chanwe_subtitle(
    "Evolución de reservas internacionales brutas.",
    kpi = chanwe_kpi(
      num = "45,91", label = "USD MM", period = "05·MAY·2026",
      mtc1_num = "0,19%",  mtc1_label = "WoW", mtc1_direction = "+",
      mtc2_num = "3,29%",  mtc2_label = "MoM", mtc2_direction = "+",
      mtc3_num = "17,78%", mtc3_label = "YoY", mtc3_direction = "-"
    )
  )
)
```

### Color scales

The brand manual assigns each color family a role (coral = house lead,
green = positive, vermillion = alert, ink = neutral anchor…), and the
scales are built on those roles:

```r
# Categorical — 8 brand hues in a fixed, CVD-validated slot order
scale_color_chanwe_d()

# Ordinal series (S/M/L, funnel stages): a one-hue ramp group
scale_fill_chanwe_d(palette = "p15_blue", reverse = TRUE)

# Sequential magnitude — named one-hue gradients, light → dark
scale_fill_chanwe_c(palette = "teal")
# available: orange (default), coral, blue, teal, green, vermillion,
# magenta, violet, mustard, ink

# Diverging polarity — vermillion (negative) → neutral → green (positive)
m <- max(abs(df$delta))
scale_fill_chanwe_div(limits = c(-m, m))
```

Notes from the palette validation (worth knowing when charting):

- The categorical slot order (coral, blue, teal, green, violet, magenta,
  mustard, ink) is CVD-validated — worst adjacent pair ΔE 17.5 under
  protan/deutan simulation. Mustard and ink sit last deliberately;
  charts with ≤ 6 series never reach them.
- For scatter, bubble, and map charts keep to **≤ 3 series** (the first
  three slots pass the stricter all-pairs check); fold the rest into
  "Other" or facet.
- Teal, green, and mustard sit below 3:1 mark contrast on the light
  surfaces — pair them with direct labels or a table view.
- Yellow and cyan are deliberately not offered as sequential ramps:
  their entire family is too light to encode magnitude on light
  surfaces. They remain available as raw tokens for accents.

### Signed colors — one pair everywhere

`chanwe_palette("signed")` carries the canonical positive / negative /
neutral: hue-true darkenings of the brand's designated families
(green = positive, vermillion = alert, ink = neutral), stepped until
they pass WCAG 4.5:1 small-text contrast on **all five brand surfaces**
(the raw ramp poles don't — bright green tops out at 2.7:1). The same
three hexes drive:

- the KPI scoreboard ▲/▼ arrows (`chanwe_kpi()`),
- table delta coloring (`chanwe_col_signed()` for `chanwe_kbl()`),
- the poles of `scale_*_chanwe_div()`,
- `chanwe_palette("semantic")` as `positive` / `negative` / `neutral`.

```r
chanwe_palette("signed")
#>  positive  negative   neutral
#> "#147705" "#CC1914" "#666666"
```

### Fonts

`theme_chanwe()` calls `chanwe_load_fonts()` automatically. The fonts
are bundled with the `chanwe-report` Quarto extension
(`_extensions/chanwe-report/fonts`); pass `path =` to point somewhere
else. Registered families include Satoshi, Archivo (plus Medium /
SemiBold / ExtraBold / Light), Fraunces 9pt (all weights), Cormorant
Garamond, and JetBrains Mono (plus Thin).

For crisp output use a systemfonts-aware device:

```r
knitr::opts_chunk$set(dev = "ragg_png")
```

## Typst Tables

`chanwe_kbl()` renders a data frame as a native Typst table — Archivo
title, Satoshi subtitle, JetBrains Mono column headers and cells, thin
ink divider rules. It emits a raw `{=typst}` block, so it works in
Quarto documents rendered with the `chanwe-report-typst` format.

````markdown
```{r}
chanwe_kbl(
  head(mtcars[, 1:5]),
  title = "Fleet summary",
  subtitle = "First six vehicles",
  eyebrow = "SECTION - FLEET",
  caption = "Source: mtcars",
  density = "spacious",
  bg = "white-ivory"
)
```
````

Useful arguments:

- `density = "spacious"` (presentations) or `"compact"` (dense reports).
- `col_labels`, `col_aligns`, `col_widths`, `stub` for column control.
- `fmt` — named list of per-column formatting functions.
- `col_colors` — per-cell Typst color expressions. Color functions
  receive the **raw (pre-`fmt`) values**, so you can color by numeric
  sign while `fmt` renders the same column as text. For the standard
  treatment use `chanwe_col_signed()` (supports `threshold`, `flip`
  for smaller-is-better metrics, and NA → neutral):

  ```r
  chanwe_kbl(
    df,
    fmt = list(delta = function(x) sprintf("%+.1f%%", x)),
    col_colors = list(delta = chanwe_col_signed())
  )
  ```
- `n_total` / `total_fill` — trailing total rows with a heavier rule.
- `highlight_cols` / `vlines` — column emphasis and vertical rules.

## Quarto usage (HTML)

```yaml
---
title: "ChanWe Report"
format:
  html:
    css:
      - !expr chanwer::chanwe_reporting_css()
execute:
  echo: false
---
```

The stylesheet enforces code blocks with a light background and orange
left rule, semantic callout headers, smaller muted captions, and orange
ToC/section-number accents.

For Typst/PDF output, use PNG-backed plot rendering for consistent font
handling:

```yaml
execute:
  dev: ragg_png
  fig-format: png
```

## Brand Tokens

```r
tokens <- chanwe_brand_tokens()
str(tokens, max.level = 2)

chanwe_preview_palette("chart")   # swatch grid of any palette group
```

## Development

```r
devtools::document()   # regenerate man/ and NAMESPACE
devtools::test()       # run the test suite
devtools::check()      # full R CMD check
```

## License

MIT

## Chanwe dependencies

### Chanwe brand extension

**Current use:** This repository is the source package for Chanwe-styled R output; it does not consume the Chanwe Quarto extension bundle. Downstream Quarto projects can install that bundle from a sibling checkout:

```bash
quarto add ../chanwe-brand
```

Update a clean downstream installation with:

```bash
git -C ../chanwe-brand pull --ff-only
quarto add ../chanwe-brand
```

`quarto add` replaces files under `_extensions/chanwe-*`; preserve project-specific extension changes before updating.

### `chanwer` R package

**Current use:** This is the source repository for `chanwer`, which provides Chanwe plotting, table, and reporting helpers.

Install or update the published GitHub package from R:

```r
if (!requireNamespace("pak", quietly = TRUE)) install.packages("pak")
pak::pak("chanwe-ar/chanwer")
```

For local development in this repository, run `devtools::install(".")`.
