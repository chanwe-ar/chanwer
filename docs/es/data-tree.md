# chanwer: árbol de datos

Verificado contra el código el 2026-11-19. chanwer no guarda datos propios: lo único que "fluye" son los valores
de la marca, desde el hub hasta cada gráfico y tabla, y los datos del usuario, que entran como data frame y salen
como gráfico.

## De dónde salen los valores

```mermaid
flowchart LR
  hub["chanwe-brandbook<br/>brand/ui/tokens/tokens.json"] -->|genera| tr["tokens.R (hub)"]
  tr -->|copia: brand-sync| bt["R/brand-tokens.R<br/>chanwe_tokens"]
  bt --> pal["chanwe_palette()<br/>chanwe_brand_tokens()"]
  bt --> html["chanwe_html_tokens()"]
  pal --> th["theme_chanwe()<br/>escalas _focus/_d/_c/_div"]
  th --> pb["constructores de papel<br/>chanwe_bars() …"]
  html --> hc["chanwe_highchart()"] --> ib["constructores interactivos<br/>chanwe_hc_bars() …"]
  html --> gt["chanwe_gt() · chanwe_reactable()"]
  pal --> kbl["chanwe_kbl() (Typst)"]
  fonts["fonts/ (Satoshi, Schibsted Grotesk, JetBrains Mono)"] --> lf["chanwe_load_fonts()"] --> th
```

| Valor | Dueño | Dónde lo lee chanwer |
|---|---|---|
| Colores, radios, tipografía, `plot.*` | `tokens.json` del hub | `R/brand-tokens.R` (generado; nunca a mano) |
| Señal y contexto (`plot.focus`, `plot.slate`) | hub | `scale_*_chanwe_focus()`, `chanwe_focus_colors()`, todos los constructores |
| Signo (`signed-positive/negative/neutral`) | hub | `chanwe_col_signed()`, `signed =`, el heatmap |
| Fuentes | `chanwe-brandbook/brand/ui/fonts` | `inst/fonts`, `chanwe_load_fonts()` |

## De los datos al gráfico

```mermaid
flowchart TD
  df["data frame del usuario"] --> b{"¿papel o interactivo?"}
  b -->|papel| p["chanwe_* (ggplot)"] --> fr["chanwe_figure() opcional:<br/>encabezado, KPI, pie"] --> out1["PNG/SVG en el PDF o HTML"]
  b -->|interactivo| i["chanwe_hc_* (highcharter)"] --> w["htmlwidget en HTML"]
  df --> t{"¿tabla?"}
  t -->|PDF| k["chanwe_kbl()"] --> typ["bloque Typst crudo"]
  t -->|HTML| g["chanwe_gt() / chanwe_reactable()"]
```

## Quién escribe y quién lee

| Pieza | La escribe | La leen |
|---|---|---|
| `R/brand-tokens.R` | el flujo brand-sync del hub (PR `chore/brand-tokens`) | todo el paquete |
| `_extensions/` | copia de chanwe-brand (la versión fijada) | los showcases y el catálogo |
| `catalogue/external/*.jpg` | el render de revisión del catálogo | `chanwer-catalogue.qmd` |
