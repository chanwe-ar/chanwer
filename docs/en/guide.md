# chanwer: guide

## A paper chart

One builder per form. Each applies the brand rule —orange is the one signal, the rest on the slate ramp, names and
values quiet in mono— and returns a ggplot, so `labs()` and `theme()` still apply. The title states the claim; the
subtitle what is measured, in what unit and over what period; the eyebrow the topic; the source goes in the foot.

```r
library(chanwer)
chanwe_load_fonts()
regions <- data.frame(region = c("Cuyo", "Pampeana", "NOA"), usd = c(412.1, 388.4, 251.9))
chanwe_bars(regions, "region", "usd", focus = "Cuyo") +
  ggplot2::labs(
    title = chanwe_title("Cuyo leads sales", eyebrow = "Ventas"),
    subtitle = "Sales by region, USD millions, 2025",
    caption = chanwe_caption("Fuente · ledger")
  )
```

| Need | Builder | Styles (`style =`) |
|---|---|---|
| Compare categories | `chanwe_bars()` | `labelled` (default), `ranking`, `lollipop` |
| Series over time | `chanwe_lines()` | `direct` (default), `spaghetti` |
| One series, its level | `chanwe_area()` | — |
| Signed deviations on a grid | `chanwe_heatmap()` | `labels = TRUE` |
| Distributions | `chanwe_density()`, `chanwe_histogram()`, `chanwe_spread()` | `gradient`/`outline`; `median`/`split`; `box`/`violin` |
| One value per category, or its range | `chanwe_dots()` | `values`, `range` |
| Before and after | `chanwe_dumbbell()`, `chanwe_slope()` | — |
| Two variables | `chanwe_scatter()` | `named`, `trend`, `bubble` |
| Bridge to a total | `chanwe_waterfall()` | `signed`, `totals` |
| Composition | `chanwe_stack()`, `chanwe_whole()` | `stacked`/`share`/`grouped`; `bar`/`donut`/`waffle`/`treemap` |
| Ranks over time | `chanwe_bump()` | — |
| Many series, a panel each | `chanwe_multiples()` | — |
| Against a target | `chanwe_bullet()` | — |
| Projection | `chanwe_forecast()` | `fan`, `zone` |
| Level and change | `chanwe_level_change()` | `change` (default), `panels`, `strip` |

## An interactive chart

The interactive builders mimic the paper ones (highcharter): the same focus, the same ramp, names at the end of
each line, numbers in Spanish. The header goes in the arguments.

```r
chanwe_hc_bars(regions, "region", "usd", focus = "Cuyo",
  title = "Cuyo leads sales", subtitle = "Sales by region, USD millions, 2025",
  eyebrow = "Ventas", caption = "Fuente · ledger")
```

There are six: `chanwe_hc_bars()`, `chanwe_hc_lines()`, `chanwe_hc_area()`, `chanwe_hc_scatter()`,
`chanwe_hc_heatmap()` and `chanwe_hc_stack()`. Any other highcharter chart takes the header and the frame from
`chanwe_highchart()`. In Python the same six live in the `radar` package (`radar.paper`).

## A table

- PDF (Typst): `chanwe_kbl()`, with `chanwe_col_signed()` for signed changes.
- Static HTML: `chanwe_gt()`; interactive: `chanwe_reactable()`. Both take `signed =` for signed columns.

## Changing and releasing it

1. A branch from `origin/main` (`feat/…`, `fix/…`). A visual change shows in `chanwer-catalogue.qmd` or the
   showcase: render it and look at the page.
2. `devtools::document()`, `devtools::test()`, `devtools::check()` with no errors.
3. A line in `NEWS.md` under `# chanwer (development version)`.
4. To release: on `main`, rename that heading to `# chanwer X.Y.Z`, set `Version: X.Y.Z` in `DESCRIPTION`, merge,
   and run `scripts/release.sh X.Y.Z`. Then raise the pin in chanwe-desktop-app (`components.lock.json`).
