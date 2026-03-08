# chanwer

`chanwer` provides ChanWe brand themes for plotting, tables, and
reporting components used in Quarto workflows.

The package is built around a small set of entry points. If you know
which output you are producing, you should be able to choose the right
helper quickly.

## Installation

```r
# install.packages("pak")
pak::pak("chanwe/chanwer")
```

For local development:

```r
devtools::install(".")
```

## What is included

- `chanwe_palette()` for exact named color tokens and grouped palettes.
- `theme_chanwe()` plus ChanWe scales for ggplot2.
- `gt_theme_chanwe()` for `gt` table styling.
- `reactable_theme_chanwe()` for `reactable`.
- `hc_theme_chanwe()` for `highcharter`.
- `chanwe_reporting_css()` for Quarto reporting components.
- `chanwe_brand_tokens()` and `chanwe_preview_palette()` utilities.

## Recommended Entry Points

Use these helpers as the default choices.

- `theme_chanwe()` for `ggplot2` charts.
- `chanwe_title()` for a ggplot title with the bundled
  `Estrategia_Color1.png` marker.
- `chanwe_subtitle()` for the ChanWe subtitle rule.
- `scale_color_chanwe_d()` and `scale_fill_chanwe_d()` for discrete
  ChanWe palettes.
- `gt_theme_chanwe()` for `gt` tables when you want to control both
  density and background.
- `gt_theme_chanwe_spacious()` and `gt_theme_chanwe_compact()` for the
  two canonical `gt` table densities.
- `chanwe_reporting_css()` for Quarto document styling.

## Quick Start

```r
library(chanwer)

chanwe_palette("chart")

library(ggplot2)
ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  labs(
    title = chanwe_title("Fuel economy vs weight"),
    subtitle = chanwe_subtitle("ChanWe scatter")
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
    title = chanwe_title("Fuel economy vs weight"),
    subtitle = chanwe_subtitle("Editorial scatter"),
    x = "Weight",
    y = "MPG",
    color = "Cylinders"
  ) +
  theme_chanwe(background = "beige")
```

For `ggplot2`, the main decisions are:

- Use `background = "beige"` for the soft ChanWe surface.
- Use `background = "white"` for a cleaner paper-white surface.
- Use `chanwe_title()` when you want the bundled title marker.
- Use `chanwe_subtitle()` when you want the ChanWe separator rule.

The title marker depends on `ggtext`. If `ggtext` is not installed,
titles fall back to plain text behavior.

## gt Pattern

This is the canonical pattern for ChanWe `gt` tables.

```r
library(chanwer)
library(gt)

gt(head(mtcars)) |>
  tab_header(
    title = "Fleet summary",
    subtitle = "Spacious beige table"
  ) |>
  gt_theme_chanwe(variant = "spacious", background = "beige")
```

For `gt`, the main decisions are:

- Use `variant = "spacious"` for presentation output.
- Use `variant = "compact"` for denser reporting tables.
- Use `background = "beige"` or `background = "white"` to match the
  report surface.
- Use `gt_theme_chanwe_spacious()` or `gt_theme_chanwe_compact()` when
  you want the standard density without repeating the `variant`
  argument.

## Quarto usage (HTML, Typst PDF, PPTX)

Use ChanWe reporting CSS and theme functions in your document.

```yaml
---
title: "ChanWe Report"
format:
  html:
    css:
      - !expr chanwer::chanwe_reporting_css()
  typst: default
  pptx: default
execute:
  echo: false
---
```

```{r}
library(chanwer)
library(ggplot2)

ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  labs(
    title = chanwe_title("Fuel economy vs weight"),
    subtitle = chanwe_subtitle("ChanWe scatter")
  ) +
  theme_chanwe()
```

The stylesheet enforces:

- code blocks with `#F7F7F7` background, orange left rule, no shadow,
- semantic callout headers/borders,
- smaller muted captions,
- orange ToC and section-number accents with an `Estrategia_Color1` marker.

For Typst/PDF output, use PNG-backed plot rendering for consistent title
markers and font handling:

```yaml
execute:
  dev: ragg_png
  fig-format: png
```

## Tables

```r
library(gt)

gt(head(mtcars)) |>
  tab_header(title = "Fleet summary") |>
  gt_theme_chanwe()
```

```r
gt(head(mtcars)) |>
  tab_header(title = "Compact fleet summary") |>
  gt_theme_chanwe_compact(background = "white")
```

```r
library(reactable)
reactable(head(mtcars), theme = reactable_theme_chanwe())
```

## Charts

```r
library(highcharter)

hchart(mtcars, "scatter", hcaes(wt, mpg, group = cyl)) |>
  hc_add_theme(hc_theme_chanwe())
```

## Brand Tokens

```r
tokens <- chanwe_brand_tokens()
str(tokens, max.level = 2)
```

## License

MIT
