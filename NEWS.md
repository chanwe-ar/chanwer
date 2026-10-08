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
  `Logo_Negro.png` (lockups), `Logo_Color1.png`, `Logo_Blanco.png`
  (wordmarks), `Estrategia_Color1.png` (Aspa), `MH_Color.png` (Rombo) and
  `Tecno_Color.png` (Damero). The previous files were archive cuts in
  `#E94B2B` / `#101010`.
* `chanwe_logo_path()` no longer falls back to the repository's legacy
  top-level `assets/` folder.

# chanwer 2.5.0

* `brand.yml` palette, fonts, slate rules and orange stamp captions.
