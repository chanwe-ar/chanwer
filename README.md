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
  scales; `scale_color_chanwe_c()` / `scale_fill_chanwe_c()` —
  continuous orange gradients.
- `chanwe_kbl()` — native Typst table generator for Quarto PDF reports.
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
- `col_colors` — per-cell Typst color expressions (e.g. red negatives).
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
