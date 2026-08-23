# Chanwe Publications

`chanwe-publications-typst` is a Letter-sized publication format with the same
body components, filters, pages, charts, and back-cover helpers as
`chanwe-report-typst`. Its cover reproduces the four-cover Chanwe Research
system in `reports-covers.pdf`.

## Use

```yaml
brand: false
format:
  chanwe-publications-typst:
    chanwe-assets: "../../_extensions/chanwe-publications/assets/"
    font-paths:
      - ../../_extensions/chanwe-publications/fonts
chanwe:
  publication-period: "Abril 2026"
  publication-edition: "EDICIÓN 04 · 2026"
  publication-art: "../../_extensions/chanwe-publications/assets/01-radar-macro.svg"
  publication-series: "CHANWE / RESEARCH"
  publication-location: "MENDOZA / ARGENTINA"
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS"
  meta-rows:
    - { label: "Extensión", value: "14 páginas" }
    - { label: "Alcance", value: "Argentina" }
    - { label: "Tema", value: "Macroeconomía" }
```

`title` and `subtitle` supply the lower title group. `meta-rows` accepts any
three publication facts. Existing `chanwe-report-typst` body YAML and custom
Divs work unchanged.

## Cover metadata

All keys live under `chanwe:` and fall back to report-cover metadata, so an
existing report front matter renders a sensible publication cover unmodified.

| Key | Cover slot | Fallback |
|---|---|---|
| `publication-period` | Masthead period, top left | `date` |
| `publication-edition` | Orange edition label under the period | `edition` |
| `publication-art` | Editorial artwork field | `hero-image`, then `01-radar-macro.svg` |
| `publication-series` | Footer, left | `CHANWE / RESEARCH` |
| `publication-location` | Footer, right | `MENDOZA / ARGENTINA` |
| `publication-copyright` | Rotated legal gutter | overridden by `cover-edge` when set |
| `meta-rows` | Three label/value rows above the title | hidden when empty |

`publication-audience` is accepted for forward compatibility but is reserved:
the current cover does not render it.

## Bundled cover art

| Publication | Asset |
|---|---|
| Radar Macro | `assets/01-radar-macro.svg` |
| Quarterly Review | `assets/02-quarterly-review.svg` |
| Industry Insights | `assets/03-industry-insights.svg` |
| Business Buzz | `assets/04-business-buzz.svg` |

The cover geometry is fixed to US Letter: a 532 px editorial field, 34 px
legal gutter, 250 px black brand rail, and 52 px footer on an 816 × 1056 px
reference canvas. IBM Plex Mono, Archivo, and Cormorant Garamond render the
cover, and all three are bundled to keep it portable and visually stable.
