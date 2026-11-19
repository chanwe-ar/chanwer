# chanwer: guía

## Un gráfico de papel

Un constructor por forma. Cada uno aplica la regla de la marca —el naranja es la única señal, el resto va en la
rampa slate, los nombres y los valores en mono sin protagonismo— y devuelve un ggplot, así que `labs()` y
`theme()` siguen valiendo. El título dice la conclusión; el subtítulo, qué se mide, en qué unidad y qué período;
el rótulo (eyebrow), el tema; la fuente va al pie.

```r
library(chanwer)
chanwe_load_fonts()
regiones <- data.frame(region = c("Cuyo", "Pampeana", "NOA"), usd = c(412.1, 388.4, 251.9))
chanwe_bars(regiones, "region", "usd", focus = "Cuyo") +
  ggplot2::labs(
    title = chanwe_title("Cuyo lidera las ventas", eyebrow = "Ventas"),
    subtitle = "Ventas por región, USD millones, 2025",
    caption = chanwe_caption("Fuente · ledger")
  )
```

| Necesidad | Constructor | Estilos (`style =`) |
|---|---|---|
| Comparar categorías | `chanwe_bars()` | `labelled` (por defecto), `ranking`, `lollipop` |
| Series en el tiempo | `chanwe_lines()` | `direct` (por defecto), `spaghetti` |
| Una serie, su nivel | `chanwe_area()` | — |
| Desvíos con signo en una grilla | `chanwe_heatmap()` | `labels = TRUE` |
| Distribuciones | `chanwe_density()`, `chanwe_histogram()`, `chanwe_spread()` | `gradient`/`outline`; `median`/`split`; `box`/`violin` |
| Un valor por categoría, o su rango | `chanwe_dots()` | `values`, `range` |
| Antes y después | `chanwe_dumbbell()`, `chanwe_slope()` | — |
| Dos variables | `chanwe_scatter()` | `named`, `trend`, `bubble` |
| Puente de un total | `chanwe_waterfall()` | `signed`, `totals` |
| Composición | `chanwe_stack()`, `chanwe_whole()` | `stacked`/`share`/`grouped`; `bar`/`donut`/`waffle`/`treemap` |
| Posiciones en el tiempo | `chanwe_bump()` | — |
| Muchas series, un panel cada una | `chanwe_multiples()` | — |
| Contra una meta | `chanwe_bullet()` | — |
| Proyección | `chanwe_forecast()` | `fan`, `zone` |
| Nivel y variación | `chanwe_level_change()` | `change` (por defecto), `panels`, `strip` |

## Un gráfico interactivo

Los interactivos imitan a los de papel (highcharter): el mismo foco, la misma rampa, los nombres al final de cada
línea, números en castellano. El encabezado va en los argumentos.

```r
chanwe_hc_bars(regiones, "region", "usd", focus = "Cuyo",
  title = "Cuyo lidera las ventas", subtitle = "Ventas por región, USD millones, 2025",
  eyebrow = "Ventas", caption = "Fuente · ledger")
```

Hay seis: `chanwe_hc_bars()`, `chanwe_hc_lines()`, `chanwe_hc_area()`, `chanwe_hc_scatter()`,
`chanwe_hc_heatmap()` y `chanwe_hc_stack()`. Para cualquier otro gráfico de highcharter, `chanwe_highchart()` le
da el encabezado y el marco. En Python, los mismos seis viven en el paquete `radar` (`radar.paper`).

## Una tabla

- PDF (Typst): `chanwe_kbl()`, con `chanwe_col_signed()` para variaciones con signo.
- HTML estático: `chanwe_gt()`; interactivo: `chanwe_reactable()`. Los dos con `signed =` para columnas con signo.

## Cambiarlo y publicarlo

1. Rama desde `origin/main` (`feat/…`, `fix/…`). Un cambio de aspecto se ve en `chanwer-catalogue.qmd` o en el
   showcase: renderizar y mirar la página.
2. `devtools::document()`, `devtools::test()`, `devtools::check()` sin errores.
3. Una línea en `NEWS.md` bajo `# chanwer (development version)`.
4. Para publicar: en `main`, renombrar ese encabezado a `# chanwer X.Y.Z`, poner `Version: X.Y.Z` en
   `DESCRIPTION`, mergear y correr `scripts/release.sh X.Y.Z`. El release lleva también
   `chanwer-catalogue-vX.Y.Z.zip` (el catálogo para la biblioteca de marca, de `scripts/export-catalogue.R`). Después, subir el pin en chanwe-desktop-app
   (`components.lock.json`).
