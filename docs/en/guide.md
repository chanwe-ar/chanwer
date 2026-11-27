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
| Dated series on a period axis (days, months, quarters, half-years, years); lines, bars and areas together; a second axis | `chanwe_timeseries()` | `mark`, `side`, `stacked`, `forecast`, `labels` |

### Series over time on a period axis

`chanwe_timeseries()` (3.6.0) takes a long data frame (a date, a value, a series) and the period: `"D"`, `"M"`,
`"Q"`, `"S"` or `"A"`. The focus series is orange and the rest slate; its last value sits in the ink pill. Per series,
`mark` picks a line, bars or an area and `side` the axis; a right axis is aligned on zero (the right series are drawn
scaled by one factor, the plot's `"chanwe_secondary"` attribute). `stacked = TRUE` stacks the bars from the first
series up; `forecast = "<logical column>"` draws those rows as a dotted companion of the same colour; `events`,
`references` and `breaks` take data frames and draw `annotate_chanwe_event()`, `annotate_chanwe_hline()` and
`annotate_chanwe_break()`. Numbers go through `label_chanwe_number()`, which prints exactly what the web kit's
`Intl.NumberFormat("es-AR")` prints, so a figure and the app agree to the digit.

```r
d <- data.frame(t = chanwe_period_date(c("2025-S1", "2025-S2", "2026-S1")), v = c(38.1, 31.6, 32.3), s = "Pobreza")
fig <- chanwe_figure(chanwe_timeseries(d, "t", "v", "s", frequency = "S", number = label_chanwe_number(suffix = " %")),
                     title = "La pobreza volvió a subir", subtitle = "Personas, %, por semestre", source = "INDEC")
chanwe_save(fig, "pobreza.pdf")   # through Typst, the brand fonts embedded; .svg carries them inside
```

The period axis alone: `scale_x_chanwe_period("Q")`; its ticks `breaks_chanwe_period()` (a daily axis by the kit's
rule: months up to a year, quarters up to three, years beyond) and labels `label_chanwe_period()` (`jun-25`, `T2-25`,
`S1-25`, `2025`; `lang = "en"` for `Q2-25`, `H1-25`).

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
   and run `scripts/release.sh X.Y.Z`. The release also carries `chanwer-catalogue-vX.Y.Z.zip` (the catalogue for
   the brand library, from `scripts/export-catalogue.R`). Then raise the pin in chanwe-desktop-app (`components.lock.json`).
