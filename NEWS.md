# chanwer 3.0.0

chanwer follows CHANWE v2 (chanwe-brandbook `brand/guidelines/brand-v2.md`;
the brand-v2 unification plan, phase 8, decisions Q3 with colour rule C1 and
Q5). Charts and tables change look, so this is a major release; no exported
function or argument was removed or renamed.

## Tokens (T8.1)

* Every colour, size and radius is read from `chanwe_tokens`
  (`R/brand-tokens.R`), which chanwe-brandbook generates from
  `brand/tokens/tokens.json` (kit 0.97.0) and syncs into chanwer. The hand
  mirror `.chanwe_brand_colors` table in `R/palette.R` is gone; the legacy
  groups (`p13`, `p14`, `p15`, `mb`, `typst-*`, `brand-*`) are built from
  token names, and `.chanwe_surfaces` reads the surface tokens.
* New drift test (`tests/testthat/test-token-drift.R`): it fails when any
  string literal hex in the package source is not a token, when the `brand`
  group differs from the generated colours, or when a colour the package
  hands out is not a token or a tint built from one.
* `chanwe_palette("brand")` is the generated colour list (adds `canvas` and
  `pane`). New groups: `"slate"` (`plot.slate`, dark to light) and
  `"focus"` (the focus orange plus the slate ramp). `chanwe_palette("all")`
  adds `plot-focus`, `plot-grid`, `plot-axis-text`, `plot-title`,
  `plot-background`, `tint` (ink at 7%) and `slate-1` to `slate-5`.
* **Changed default:** the categorical `"chart"` palette is `tokens.json`
  `plot.categorical`: primary, blue, teal, indigo, purple, green, orange, red
  (2.x: primary, blue, green, indigo, orange, teal, purple, red).
* `chanwe_brand_tokens()`: v2 radii (`radius_small` 8, `radius_base` 12,
  `radius_large` 16, new `radius_pill` 999; 2.x had 4 everywhere), plus
  `radii`, `space`, `control`, the type scale and a new `plot` block, all
  from the tokens. `typography$base_size` is `type.body` (14).

## ggplot2 (T8.2, T8.3)

* `theme_chanwe()` takes the Q3 look: horizontal gridlines only, 1px of
  `plot.grid` (ink-fg at 25%) on every surface; no axis lines and no ticks;
  axis text and titles, legend text and facet strips in JetBrains Mono at
  the compact size (`type.caption`, scaled with `base_text_size`, which is
  `type.body`) in `plot.axis-text`; title in `plot.title`; legend
  left-aligned with pill-shaped keys; facet strips mono regular (was mono
  Thin).
* New `theme_chanwe(grid = "y" | "x" | "none")`: `"x"` for horizontal bars.
* **Changed default:** the caption is a JetBrains Mono label at the compact
  size (v2 keeps orange for the focus series and never fills an area with
  it). `theme_chanwe(caption_style = "stamp")` brings back the 2.x orange
  stamp.
* New colour rule (C1): `scale_color_chanwe_focus()` /
  `scale_fill_chanwe_focus()` colour the focus series orange
  (`plot.focus`) and every other series on the slate ramp;
  `chanwe_focus_colors()` returns the same colours for any other engine. The
  categorical `scale_*_chanwe_d()` stays for charts with no focus series.
* New `geom_chanwe_col()` / `geom_chanwe_bar()`: bars with 3px
  (`plot.bar-radius`) rounded ends, square at the baseline; in a stack only
  the outer segment is rounded; horizontal and negative bars round the right
  way; non-linear coordinates fall back to square bars. Drawn with grid
  alone, so no new dependency (`ggchicklet` is not on CRAN and rounds the
  base too).
* New `draw_key_chanwe_pill()`: the pill legend key (default for the
  rounded bars; `key_glyph = draw_key_chanwe_pill` for any layer).

## Tables and HTML (T8.3, T8.4)

* `chanwe_kbl()` draws a v2 pane (brand-v2 Q1 B): a block with the 16px
  surface radius (scaled to the document like the type: 8pt at the default
  7pt body), a hairline border, column labels on the slate tint, hairline
  rows, totals on the tint, and the source line as a mono label. Colours,
  fonts and radii come from `chanwe_tokens`. New arguments `pane = TRUE`
  and `caption_style`; `top_border` now defaults to `NULL` (off in a pane)
  and `highlight_color` to `NULL` (the `surface-slate` token).
* `chanwe_gt()` is a pane (16px, hairline, overflow clipped) with the tint
  header, fg-muted mono column labels (were orange), 1px hairline rows, no
  vertical stub rule, a mono caption. New argument `caption_style`.
* `chanwe_reactable()`: header, table and caption form one pane (16px
  corners, hairline); tint header with fg-muted mono labels (were orange);
  tint row hover; pill page buttons (tint and orange text on hover, the
  current page an obsidian pill) and a pill search field; mono caption. New
  argument `caption_style`.
* `chanwe_highchart()`: `plot.grid` y grid at 1px, mono axis labels at the
  compact size in `plot.axis-text`, 3px rounded columns and bars, pill
  legend symbols, `plot.line-width` lines, a mono caption, and the
  categorical palette from the tokens. New arguments `focus` (the v2 colour
  rule by series name, focus drawn on top) and `caption_style`.
* `options(chanwer.caption_style = "stamp")` restores the orange stamp in
  every helper at once.

## Showcases and tests (T8.5)

* `chanwer-showcase-pdf.qmd` and `chanwer-showcase-html.qmd` open with a
  "CHANWE v2 in charts" section (focus palette, focus bars, focus lines),
  use the rounded bars and the focus rule throughout, and were re-rendered.
* vdiffr snapshot tests for the v2 look (`tests/testthat/test-snapshots.R`):
  focus bars, focus lines with pill keys, stacked horizontal bars, the
  stamp caption and the focus palette. `vdiffr` joins Suggests; `ggplot2`
  now needs 3.5.0 or later.

# chanwer 2.6.1

* `inst/assets/Logo_Color.png` and `Logo_Negro.png` are the wordmark alone
  (chanwe-brandbook `Marca_Color` and `Marca_Obsidiana`, 2400 × 493). They were
  the lockup with the tagline «estrategia para crecer», which the brand retired
  on 2026-10-08: the mark goes without it. Same names and colours, so
  `chanwe_logo_path("Logo_Color.png")` keeps working; the image is shorter
  (aspect 4.87:1, was 3.58:1), so a fixed height draws it wider.

# chanwer 2.6.0

chanwer now follows the CHANWE brand guidelines (chanwe-brandbook
`brand/tokens/tokens.json`, `brand/fonts` and the `sistema-de-marca` guide).
The defaults changed, so this is a minor release.

## Fonts

* The brand trio by role: **Satoshi** for text, **Schibsted Grotesk** for
  titles, **JetBrains Mono** for eyebrows, labels and metadata. Cormorant
  Garamond stays only for editorial italics and numerals (KPI hero value,
  subtitle notes). Inter is retired.
* `theme_chanwe()`: `base_family` defaults to `"Satoshi"` (was `"Inter"`),
  and the root `text` element now carries it (it was dropped by
  `%+replace%`, so unstyled text fell back to the device sans). Axis tick
  labels are JetBrains Mono, like the axis titles, legends and the highcharter
  axes.
* `chanwe_gt()`, `chanwe_reactable()`, `chanwe_highchart()`: Satoshi body
  text and subtitles (the font stacks follow `tokens.json`, without Inter).
* `chanwe_kbl()`: Satoshi subtitle and text cells (the guide sets tables in
  Satoshi); right-aligned figures stay in JetBrains Mono.
* `chanwe_preview_palette()`: swatch labels in JetBrains Mono, title in
  Schibsted Grotesk.
* `chanwe_brand_tokens()$typography$family` is `"Satoshi"`.
* The fonts ship with the package in `inst/fonts` (TTF for ggplot2 and
  Typst, WOFF2 in `inst/fonts/web` for HTML), copied from chanwe-brandbook.
  Nothing depends on the Quarto extension's font folder any more.
* `chanwe_load_fonts()` registers Satoshi (plus Light, Medium, SemiBold),
  Schibsted Grotesk (plus Medium, SemiBold), JetBrains Mono (plus Medium,
  Thin), Cormorant Garamond and Instrument Serif from those files. It now
  warns (class `chanwer_missing_font`) listing every missing file and the
  families affected, instead of skipping them silently, and leaves a family
  that is installed on the system under the same name to that copy.
* No Google Fonts. The HTML widgets' `chanwe-fonts` dependency and
  `chanwe_reporting_css()` load the bundled WOFF2 with local `@font-face`
  rules, so rendered reports make no font requests and work offline.

## Deprecations

* `theme_chanwe(base_family = "Inter")` (and `"Inter Light"`,
  `"Inter Medium"`) still works but warns and uses `"Satoshi"`
  (`"Satoshi Light"`, `"Satoshi Medium"`). No argument was renamed.
* `chanwe_load_fonts()` no longer registers the `"Inter"`, `"Inter Light"`
  and `"Inter Medium"` families.

## Colours

* `chanwe_palette("brand")` adds the `tokens.json` colours it was missing:
  `ink-light` `#232A35`, `surface-raised` `#FFFFFF`, `violet` `#7C3AED`,
  `violet-soft` `#EFE7FD`. The extension's `brand.yml` and `colors.json` gain
  `ink-light`, matching chanwe-brand.
* The legacy groups keep their names and lengths but are rebuilt from brand
  tokens; no retired or off-palette value is left (the old `#E94B2B` orange,
  the `#101010` black, `#F40C0C`, the warm greys):
  * `p13_orange` / `mb_orange`: tints of `primary` (was `#E94B2B`).
  * `p13_gray` / `mb_dark`: tints of `ink` (was `#101010`).
  * `p14_accents`: the red pair is `status-error` / `status-error-bg`; the
    magenta soft is a 75% tint of `chart-magenta`.
  * `p15_*`: coral from `primary`, vermillion from `chart-red`, mustard from
    `exec-status-regular`, violet from `violet` to `violet-soft`, teal from
    `chart-teal`, ink from `ink`; green, blue, yellow and cyan are rebuilt
    from their status/neon token and its soft partner (1-step rounding
    changes only).
* The sequential `"orange"`, `"mustard"` and `"ink"` ramps follow (the
  default continuous scale now runs to `primary` through its own tints).
* `chanwe_brand_tokens()$reporting$caption_color` is `fg-muted` `#475569`
  (was `fg-subtle` `#8A94A6`), and the reporting stylesheet's captions too:
  the guide keeps `fg-subtle` for large or decorative text.

## Rules

* One radius: `chanwe_brand_tokens()$geometry` is 4 for `radius_small`,
  `radius_base` and `radius_large` (were 3, 4, 6), and `chanwe_reactable()`
  page buttons take 4px corners (were square).
* `chanwe_highchart()` eyebrows are the brand eyebrow: an orange rule and
  uppercase JetBrains Mono with wide tracking (was a typed `——` prefix,
  without uppercase or tracking).

## Assets

* `inst/assets` marks are the current brandbook files: `Logo_Color.png`,
  `Logo_Negro.png` (lockups; the wordmark alone since the next release),
  `Logo_Color1.png`, `Logo_Blanco.png` (wordmarks), `Estrategia_Color1.png` (Aspa), `MH_Color.png` (Rombo) and
  `Tecno_Color.png` (Damero). The previous files were archive cuts in
  `#E94B2B` / `#101010`.
* `chanwe_logo_path()` no longer falls back to the repository's legacy
  top-level `assets/` folder.

# chanwer 2.5.0

* `brand.yml` palette, fonts, slate rules and orange stamp captions.
