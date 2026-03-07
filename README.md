# chanweThemes

`chanweThemes` provides ChanWe brand themes for plotting, tables, and
reporting components used in Quarto workflows.

## Installation

```r
# install.packages("pak")
pak::pak("chanwe/chanweThemes")
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

## Quick Start

```r
library(chanweThemes)

chanwe_palette("chart")

library(ggplot2)
ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  theme_chanwe()
```

## Quarto usage (HTML, Typst PDF, PPTX)

Use ChanWe reporting CSS and theme functions in your document.

```yaml
---
title: "ChanWe Report"
format:
  html:
    css:
      - !expr chanweThemes::chanwe_reporting_css()
  typst: default
  pptx: default
execute:
  echo: false
---
```

```{r}
library(chanweThemes)
library(ggplot2)

ggplot(mtcars, aes(wt, mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  scale_color_chanwe_d() +
  theme_chanwe()
```

The stylesheet enforces:

- code blocks with `#F7F7F7` background, orange left rule, no shadow,
- semantic callout headers/borders,
- smaller muted captions,
- orange ToC and section-number accents with an `Estrategia_Color1` marker.

## Tables

```r
library(gt)

gt(head(mtcars)) |>
  tab_header(title = "Fleet summary") |>
  gt_theme_chanwe()
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
