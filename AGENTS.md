# chanwer Agent Guide

This repository is an R package that provides ChanWe visual themes for
`ggplot2`, a native Typst table generator, and Quarto reporting helpers.

Use this file as the fast path when deciding what to call and where to
look.

## Start Here

- Read `README.md` first for the public usage patterns.
- Read `DESCRIPTION` for package metadata and dependencies.
- Read `_pkgdown.yml` for the intended public reference structure.

## Canonical Entry Points

- Use `theme_chanwe()` for `ggplot2` themes.
- Use `chanwe_title()` when a title needs the orange mono-caps eyebrow.
- Use `chanwe_subtitle()` when a subtitle needs a note line or a KPI
  scoreboard (`chanwe_kpi()`); plain subtitles need no helper.
- Use `chanwe_caption()` for the `//`-prefixed source line.
- Use `scale_color_chanwe_d()` and `scale_fill_chanwe_d()` for discrete
  ChanWe palettes; `_c` variants for continuous orange gradients.
- Use `chanwe_kbl()` for tables in Quarto Typst PDF reports.
- Use `chanwe_load_fonts()` once per session to register brand fonts
  (called automatically by `theme_chanwe()`).
- Use `chanwe_reporting_css()` for Quarto HTML report styling.

## Decision Rules

- If the user is styling a `ggplot2` chart, start in `R/ggplot2-theme.R`.
- If the header layout (title/subtitle/KPI/caption grobs) is involved,
  start in `R/ggplot2-elements.R` — the layout maps live in its comments.
- If the user is styling a table, start in `R/kbl-theme.R`.
- If the user needs colors or reporting tokens, start in `R/palette.R`.
- If the user is rendering a Quarto or Typst example, inspect
  `chanwer-showcase-pdf.qmd` (static, chanwe-report-typst) or
  `chanwer-showcase-html.qmd` (static + interactive HTML) and
  `_extensions/chanwe-report/`.

## ggplot2 Notes

- `theme_chanwe()` takes `bg_color` (not `background`): `"metallic"`
  (default), `"white"`, `"white-ivory"`, `"gray"`, `"beige"`,
  `"transparent"`, or any hex string.
- The eyebrow only appears when the title uses
  `chanwe_title(text, eyebrow = ...)`.
- The header separator rule is drawn by the custom subtitle/title grobs;
  control it with `header_line` and `has_subtitle`.
- Labels are encoded with ASCII unit separators (`\x1F`, `\x1E`) and
  decoded by the custom elements — never construct those strings by hand.
- Fonts resolve through `systemfonts`; render with `ragg` devices
  (`dev = "ragg_png"`).

## Typst Table Notes

- `chanwe_kbl()` emits a raw `{=typst}` block via `knitr::asis_output()`.
  It requires the document to be rendered with the `chanwe-report-typst`
  format (the `_t` token dictionary comes from the template).
- `density = "spacious"` for presentation output; `"compact"` for dense
  report output.
- Cell text is escaped for Typst markup; `col_colors` values are raw
  Typst expressions and are NOT escaped.

## Quarto And Typst Notes

- For Typst/PDF output, prefer PNG-backed plot rendering:
  - `dev: ragg_png`
  - `fig-format: png`
- The main reference examples are `chanwer-showcase-pdf.qmd` (every static
  pattern: ggplot2 + `chanwe_kbl()`) and `chanwer-showcase-html.qmd` (the
  same plus `chanwe_gt()`, `chanwe_plotly()`, `chanwe_reactable()`).
- The Quarto extension lives under `_extensions/chanwe-report/`
  (template, filters, fonts, assets).

## Development Workflow

- Re-document after changing roxygen comments:
  `Rscript -e "devtools::document()"`
- Run tests:
  `Rscript -e "devtools::test()"`
- Full check (must stay at 0 errors / 0 warnings / 0 notes):
  `Rscript -e "devtools::check()"`
- Build + install locally:
  `R CMD build . && R CMD INSTALL chanwer_<version>.tar.gz`

## Documentation Expectations

- Keep README examples canonical and copy-pasteable.
- Keep roxygen examples aligned with the recommended public usage.
  Examples must not print plots (custom fonts are unavailable on check
  devices) — assign them to variables instead.
- If you add a public helper, add it to `_pkgdown.yml`.
- If you change ggplot title behavior, verify both plain R plots and
  Typst/Quarto rendering paths.
- Keep R code strings ASCII-only (use `\uXXXX` escapes); non-ASCII is
  fine in comments.
