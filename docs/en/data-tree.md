# chanwer: data tree

Checked against the code on 2026-11-19. chanwer keeps no data of its own: what flows is the brand's values, from
the hub to every chart and table, and the user's data, which comes in as a data frame and leaves as a chart.

## Where the values come from

```mermaid
flowchart LR
  hub["chanwe-brandbook<br/>brand/ui/tokens/tokens.json"] -->|generates| tr["tokens.R (hub)"]
  tr -->|copy: brand-sync| bt["R/brand-tokens.R<br/>chanwe_tokens"]
  bt --> pal["chanwe_palette()<br/>chanwe_brand_tokens()"]
  bt --> html["chanwe_html_tokens()"]
  pal --> th["theme_chanwe()<br/>scales _focus/_d/_c/_div"]
  th --> pb["paper builders<br/>chanwe_bars() …"]
  html --> hc["chanwe_highchart()"] --> ib["interactive builders<br/>chanwe_hc_bars() …"]
  html --> gt["chanwe_gt() · chanwe_reactable()"]
  pal --> kbl["chanwe_kbl() (Typst)"]
  fonts["fonts/ (Satoshi, Schibsted Grotesk, JetBrains Mono)"] --> lf["chanwe_load_fonts()"] --> th
```

| Value | Owner | Where chanwer reads it |
|---|---|---|
| Colours, radii, type, `plot.*` | the hub's `tokens.json` | `R/brand-tokens.R` (generated; never by hand) |
| Signal and context (`plot.focus`, `plot.slate`) | hub | `scale_*_chanwe_focus()`, `chanwe_focus_colors()`, every builder |
| Sign (`signed-positive/negative/neutral`) | hub | `chanwe_col_signed()`, `signed =`, the heatmap |
| Fonts | `chanwe-brandbook/brand/ui/fonts` | `inst/fonts`, `chanwe_load_fonts()` |

## From data to chart

```mermaid
flowchart TD
  df["the user's data frame"] --> b{"paper or interactive?"}
  b -->|paper| p["chanwe_* (ggplot)"] --> fr["chanwe_figure() optional:<br/>header, KPI, foot"] --> out1["PNG/SVG in the PDF or HTML"]
  b -->|interactive| i["chanwe_hc_* (highcharter)"] --> w["htmlwidget in HTML"]
  df --> t{"table?"}
  t -->|PDF| k["chanwe_kbl()"] --> typ["raw Typst block"]
  t -->|HTML| g["chanwe_gt() / chanwe_reactable()"]
```

## Who writes and who reads

| Piece | Written by | Read by |
|---|---|---|
| `R/brand-tokens.R` | the hub's brand-sync flow (PR `chore/brand-tokens`) | the whole package |
| `_extensions/` | a copy of chanwe-brand (the pinned version) | the showcases and the catalogue |
| `catalogue/external/*.jpg` | the catalogue's review render | `chanwer-catalogue.qmd` |
