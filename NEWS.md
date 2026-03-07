# chanweThemes 0.1.0

- Added ChanWe-branded helpers for plotting, tables, and reporting workflows, including `chanwe_palette()`, `theme_chanwe()`, `scale_*_chanwe_*()`, `gt_theme_chanwe()`, `reactable_theme_chanwe()`, `hc_theme_chanwe()`, and Quarto reporting CSS utilities.
- `chanwe_title()` now resolves the marker from installed package assets (`system.file("assets/...")`) so title markers render consistently outside the package project directory.
- `theme_chanwe()` now uses a smaller default `base_text_size`, reducing text and heading sizes across ggplot outputs.
