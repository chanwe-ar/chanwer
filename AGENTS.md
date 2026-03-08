# chanwer Agent Guide

This repository is an R package that provides ChanWe visual themes and
reporting helpers for `ggplot2`, `gt`, `reactable`, `highcharter`, and
Quarto workflows.

Use this file as the fast path when deciding what to call and where to
look.

## Start Here

- Read `README.md` first for the public usage patterns.
- Read `DESCRIPTION` for package metadata and dependencies.
- Read `_pkgdown.yml` for the intended public reference structure.

## Canonical Entry Points

- Use `theme_chanwe()` for `ggplot2` themes.
- Use `chanwe_title()` for a ggplot title with the bundled
  `Estrategia_Color1.png` marker.
- Use `chanwe_subtitle()` for the ChanWe subtitle separator rule.
- Use `scale_color_chanwe_d()` and `scale_fill_chanwe_d()` for discrete
  ChanWe palettes.
- Use `gt_theme_chanwe()` for `gt` tables when you need explicit control
  over density and background.
- Use `gt_theme_chanwe_spacious()` for presentation-style tables.
- Use `gt_theme_chanwe_compact()` for denser report tables.
- Use `reactable_theme_chanwe()` for `reactable`.
- Use `hc_theme_chanwe()` for `highcharter`.
- Use `chanwe_reporting_css()` for Quarto report styling.

## Decision Rules

- If the user is styling a `ggplot2` chart, start in `R/ggplot2-theme.R`.
- If the user is styling a `gt` table, start in `R/gt-theme.R`.
- If the user needs colors or reporting tokens, start in `R/palette.R`.
- If the user is rendering a Quarto or Typst example, inspect
  `chanwe-typst-gt-ggplot-showcase.qmd`.

## ggplot2 Notes

- `theme_chanwe()` supports `background = "beige"` and
  `background = "white"`.
- The title marker only appears when the plot title uses
  `chanwe_title(...)`.
- The subtitle rule only appears when the subtitle uses
  `chanwe_subtitle(...)`.
- The title marker path resolves through the bundled asset
  `inst/assets/Estrategia_Color1.png`.
- `chanwe_title()` depends on `ggtext` support in the theme. If `ggtext`
  is unavailable, expect plain-text fallback behavior.

## gt Notes

- `gt_theme_chanwe()` is the main function.
- Prefer `variant = "spacious"` for presentation output.
- Prefer `variant = "compact"` for dense report output.
- `background` should usually match the surrounding report surface.
- Current table font is `DM Sans 9pt` for Typst compatibility.

## Quarto And Typst Notes

- For Typst/PDF output, prefer PNG-backed plot rendering:
  - `dev: ragg_png`
  - `fig-format: png`
- The main reference example is `chanwe-typst-gt-ggplot-showcase.qmd`.
- Brand configuration lives under `_extensions/chanwe-brand/`.

## Development Workflow

- Re-document after changing roxygen comments:
  `Rscript -e "devtools::document()"`
- Run tests:
  `Rscript -e "devtools::test()"`
- Run targeted tests:
  `Rscript -e "devtools::test(filter = '^(utilities|theme-objects)$')"`

## Documentation Expectations

- Keep README examples canonical and copy-pasteable.
- Keep roxygen examples aligned with the recommended public usage.
- If you add a public helper, add it to `_pkgdown.yml`.
- If you change ggplot title behavior, verify both plain R plots and
  Typst/Quarto rendering paths.
