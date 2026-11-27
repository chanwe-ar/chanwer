# Exports the chart catalogue for the brand library (chanwe-brandbook, «Visualizaciones de papel»):
# <out>/chanwer-catalogue.json, one entry per builder and style, and <out>/images/<builder>-<style>.png,
# each rendered from the same demo data as chanwer-catalogue.qmd at 1200 px wide (2x).
#
#   Rscript scripts/export-catalogue.R <out>
#
# Run from the repo root. It loads the package from the checkout, so the images match the version in
# DESCRIPTION; scripts/release.sh runs it and attaches the zip to the release.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) stop("usage: Rscript scripts/export-catalogue.R <out>", call. = FALSE)
out <- normalizePath(args[[1]], mustWork = FALSE)
dir.create(file.path(out, "images"), recursive = TRUE, showWarnings = FALSE)
suppressPackageStartupMessages({
  pkgload::load_all(".", quiet = TRUE)
  library(ggplot2)
})
chanwe_load_fonts()
version <- as.character(read.dcf("DESCRIPTION", fields = "Version"))

# The demo data, shown in the manifest so every call can be run as written.
setup <- '
set.seed(11)
prov <- c("Mendoza", "Córdoba", "Santa Fe", "Buenos Aires", "Tucumán", "Salta", "Neuquén", "Chubut", "Misiones", "Entre Ríos")
months <- seq(as.Date("2021-01-01"), by = "month", length.out = 60)
unemp <- data.frame(date = months, value = 9 + cumsum(rnorm(60, 0, .25)) + 2.5 * plogis((seq_along(months) - 38) / 2))
cn <- c("Argentina", "Brasil", "Chile", "Uruguay", "Paraguay", "Perú", "Bolivia", "Colombia")
act <- do.call(rbind, lapply(seq_along(cn), function(i) data.frame(date = months, country = cn[i],
  value = 100 + cumsum(rnorm(60, c(.15, .35, .45, .3, .25, .4, .2, .3)[i], .9)))))
act$country <- factor(act$country, cn)
act4 <- act[act$country %in% cn[1:4], ]
regions <- data.frame(region = c("Cuyo", "Pampeana", "NOA", "Patagonia", "NEA"), value = c(41.2, 33.8, 27.5, 22.9, 18.4))
weeks <- expand.grid(week = 1:12, region = c("Norte", "Centro", "Oeste", "Sur")); weeks$delta <- round(rnorm(48, 0, 4.5), 1)
mt <- mtcars; mt$tr <- factor(ifelse(mt$am == 1, "Manual", "Automática"), c("Manual", "Automática"))
dp <- data.frame(p = prov, v = round(runif(10, 18, 46), 1)); dp$lo <- dp$v - runif(10, 2, 6); dp$hi <- dp$v + runif(10, 2, 6)
db <- data.frame(p = prov[1:8], a = round(runif(8, 20, 40), 1)); db$b <- db$a + round(rnorm(8, 3, 4), 1)
sl <- data.frame(p = prov[1:7], a = round(runif(7, 10, 30), 1)); sl$b <- sl$a + round(rnorm(7, 1, 5), 1)
sc <- data.frame(p = c(prov, paste("Región", 1:14)), x = runif(24, 20, 60)); sc$y <- 8 + .45 * sc$x + rnorm(24, 0, 4); sc$pop <- runif(24, .3, 9)
wf <- data.frame(k = c("2024", "Precios", "Volumen", "Mix", "Tipo de cambio", "Costos"), v = c(120, 18, 9, -4, -14, -7))
st <- expand.grid(y = 2021:2025, s = c("Energía", "Agro", "Industria", "Servicios"))
st$v <- c(18, 22, 25, 31, 38, 30, 29, 33, 31, 34, 22, 21, 20, 19, 18, 12, 13, 14, 16, 17)
hv <- data.frame(v = rlnorm(900, 6.4, .45))
bx <- data.frame(r = rep(c("Cuyo", "Pampeana", "NOA", "Patagonia", "NEA"), each = 60))
bx$v <- rlnorm(300, rep(c(6.3, 6.5, 6.1, 6.7, 6.0), each = 60), .35)
bp <- expand.grid(y = 2019:2025, p = prov[1:7])
bp$score <- rnorm(nrow(bp), 0, .35) + rep(seq(1.2, -1.2, length.out = 7), each = 7) + as.numeric(bp$p == "Mendoza") * ((bp$y - 2019) * .55 - 1.6)
bp <- do.call(rbind, lapply(split(bp, bp$y), function(g) transform(g, rk = rank(-score))))
mm <- expand.grid(t = 1:36, p = prov[1:6]); mm$v <- ave(rnorm(nrow(mm), .3, 1), mm$p, FUN = cumsum)
bt <- data.frame(k = c("Ventas", "Margen", "Clientes nuevos", "Retención", "NPS"), a = c(82, 64, 91, 77, 58), t = c(90, 70, 85, 80, 65))
pw <- data.frame(k = c("Energía", "Agro", "Industria", "Servicios", "Turismo", "Otros"), v = c(34, 28, 16, 10, 7, 5))
mo <- seq(as.Date("2023-01-01"), by = "month", length.out = 48)
fv <- data.frame(d = mo, v = 2.6 + cumsum(c(rnorm(36, -.03, .22), rep(-.04, 12))), s = pmax(seq_len(48) - 36, 0) * .15)
cb <- data.frame(y = 2014:2025, v = c(700, 735, 690, 760, 820, 790, 640, 760, 880, 910, 870, 960))
tsd <- rbind(data.frame(t = mo[1:36], v = round(160 * exp(-(1:36) / 9) + 30, 1), s = "Inflaci\u00f3n"),
             data.frame(t = mo[1:36], v = round(cumsum(rnorm(36, .15, 1.4)) - 2, 1), s = "Actividad"))
'
env <- new.env()
eval(parse(text = setup, encoding = "UTF-8"), envir = env)

# One builder: what it answers and when not to use it, in Spanish and English.
B <- function(builder, need_es, need_en, not_es, not_en, styles) {
  list(builder = builder, need = list(es = need_es, en = need_en), not = list(es = not_es, en = not_en), styles = styles)
}
# One style: its id and name, the call, the header it is shown with, and its interactive twin.
S <- function(id, es, en, call, header, hc = NULL, default = FALSE) {
  list(id = id, name = list(es = es, en = en), call = call, header = header, hc = hc, default = default)
}
H <- function(eyebrow, title, subtitle, source) list(eyebrow = eyebrow, title = title, subtitle = subtitle, source = source)

h_bars <- H("Ventas · Región", "Cuyo lidera las ventas", "USD millones, acumulado ene-dic 2025", "elaboración propia")
h_act <- H("Actividad · Región", "Argentina crece por debajo de sus vecinos", "Índice, 2016 = 100, mensual, ene-21 a dic-25", "INDEC, bancos centrales")
h_heat <- H("Desvío · Plan", "Desvío semanal contra el plan", "Puntos porcentuales, semanas 1 a 12 de 2026", "elaboración propia")
h_dens <- H("Consumo", "Los manuales rinden más", "Densidad de millas por galón, 32 modelos, 1974", "Motor Trend, 1974")
h_dots <- H("Empleo · Provincias", "Mendoza, cuarta en informalidad", "Asalariados sin descuento jubilatorio, %, 3.er trimestre 2025", "EPH, INDEC")
h_sc <- H("Productividad", "Más inversión, más productividad", "Inversión por ocupado (USD miles) y productividad (índice), 2025", "elaboración propia")
h_wf <- H("Resultado", "Los precios explican casi todo el aumento", "Resultado operativo, USD millones, 2024 a 2025", "estados contables")
h_st <- H("Exportaciones · Sectores", "La energía ya es la primera exportación", "Exportaciones de Mendoza por sector, USD millones", "INDEC")
h_hist <- H("Ingresos", "La mitad gana menos de 600 mil", "Ingreso mensual por ocupado, miles de pesos, 3.er trimestre 2025", "EPH, INDEC")
h_bx <- H("Ingresos · Regiones", "Patagonia paga más y más parejo", "Ingreso mensual por ocupado, miles de pesos, 3.er trimestre 2025", "EPH, INDEC")
h_pw <- H("Exportaciones · Sectores", "La energía, un tercio de lo exportado", "Exportaciones de Mendoza por sector, %, 2025", "INDEC")
h_fc <- H("Inflación", "La inflación seguiría bajando en 2026", "Variación mensual del IPC, %, ene-23 a dic-26; proyección desde ene-26", "INDEC, proyección propia")
h_ts <- H("Precios · Actividad", "La inflación baja y la actividad se recupera", "Variación interanual, %, inflación (izq.) y actividad (der.), ene-23 a dic-25", "INDEC")
h_lc <- H("Producción", "2025, récord de la serie", "Producción, miles de toneladas, y su variación anual, 2014 a 2025", "elaboración propia")

catalogue <- list(
  B("chanwe_bars", "Comparar categorías en un momento: quién lidera, cuánto más.", "Compare categories at one moment: who leads, by how much.",
    "Series en el tiempo (líneas) o partes de un total (composición).", "Series over time (lines) or parts of a whole (composition).", list(
    S("labelled", "Barras con valor", "Labelled bars", 'chanwe_bars(regions, "region", "value", focus = "Cuyo")', h_bars, "chanwe_hc_bars", TRUE),
    S("ranking", "Ranking", "Ranking", 'chanwe_bars(regions, "region", "value", style = "ranking", reference = median(regions$value))', h_bars, "chanwe_hc_bars"),
    S("lollipop", "Piruleta", "Lollipop", 'chanwe_bars(regions, "region", "value", style = "lollipop")', h_bars))),
  B("chanwe_lines", "Varias series en el tiempo, una protagonista.", "Several series over time, one of them the point.",
    "Más de ocho series con nombre: usar spaghetti o múltiplos.", "More than eight named series: use spaghetti or multiples.", list(
    S("direct", "Etiquetas directas", "Direct labels", 'chanwe_lines(act4, "date", "value", "country")', h_act, "chanwe_hc_lines", TRUE),
    S("spaghetti", "Spaghetti", "Spaghetti", 'chanwe_lines(act, "date", "value", "country", style = "spaghetti")', h_act, "chanwe_hc_lines"))),
  B("chanwe_area", "El nivel de una sola serie en el tiempo.", "The level of a single series over time.",
    "Varias series (se tapan) o un valor que no parte de cero.", "Several series (they hide each other) or a value that does not start at zero.", list(
    S("default", "Área con degradé", "Gradient area", 'chanwe_area(unemp, "date", "value")',
      H("Empleo", "El desempleo sube desde 2024", "Personas desocupadas, millones, mensual, ene-21 a dic-25", "INDEC"), "chanwe_hc_area", TRUE))),
  B("chanwe_heatmap", "Desvíos con signo en una grilla de dos dimensiones.", "Signed deviations on a two-dimensional grid.",
    "Magnitudes sin signo: usar barras o una escala secuencial.", "Unsigned magnitudes: use bars or a sequential scale.", list(
    S("tiles", "Celdas", "Tiles", 'chanwe_heatmap(weeks, "week", "region", "delta")', h_heat, "chanwe_hc_heatmap", TRUE),
    S("labels", "Celdas con valor", "Labelled tiles", 'chanwe_heatmap(weeks, "week", "region", "delta", labels = TRUE)', h_heat, "chanwe_hc_heatmap"))),
  B("chanwe_density", "La forma de una distribución, o dos comparadas.", "The shape of a distribution, or two compared.",
    "Pocos datos (menos de 30): usar puntos o un histograma.", "Few data points (under 30): use dots or a histogram.", list(
    S("gradient", "Contorno con degradé", "Gradient outline", 'chanwe_density(mt, "mpg", "tr")', h_dens, NULL, TRUE),
    S("outline", "Contorno", "Outline", 'chanwe_density(mt, "mpg", "tr", style = "outline")', h_dens))),
  B("chanwe_dots", "Un valor por categoría, o su rango, con muchas categorías.", "One value per category, or its range, across many categories.",
    "Pocas categorías con valores muy distintos: usar barras.", "Few categories with very different values: use bars.", list(
    S("values", "Puntos con valor", "Dots with values", 'chanwe_dots(dp, "p", "v", focus = "Mendoza")', h_dots, NULL, TRUE),
    S("range", "Rango", "Range", 'chanwe_dots(dp, "p", "v", focus = "Mendoza", style = "range", lo = "lo", hi = "hi")', h_dots))),
  B("chanwe_dumbbell", "Antes y después por categoría: el cambio y su dirección.", "Before and after per category: the change and its direction.",
    "Más de dos momentos: usar líneas.", "More than two moments: use lines.", list(
    S("default", "Pesas", "Dumbbell", 'chanwe_dumbbell(db, "p", "a", "b", labels = c("2024", "2025"))',
      H("Pobreza · Provincias", "La pobreza cambió poco", "Personas pobres, %, 1.er semestre 2024 y 2025", "EPH, INDEC"), NULL, TRUE))),
  B("chanwe_slope", "Cómo cambió el orden entre dos momentos.", "How the order changed between two moments.",
    "Muchas categorías que se cruzan: usar pesas o un ranking.", "Many categories that cross: use a dumbbell or a ranking.", list(
    S("default", "Pendiente", "Slope", 'chanwe_slope(sl, "p", "a", "b", labels = c("2020", "2025"), focus = "Mendoza")',
      H("Exportaciones · Provincias", "Mendoza ganó terreno", "Participación en las exportaciones regionales, %, 2020 y 2025", "INDEC"), NULL, TRUE))),
  B("chanwe_scatter", "La relación entre dos variables, con los casos que importan nombrados.", "The relation between two variables, with the cases that matter named.",
    "Una variable en el tiempo: usar líneas.", "One variable over time: use lines.", list(
    S("named", "Con nombres", "Named", 'chanwe_scatter(sc, "x", "y", "p", focus = "Mendoza", highlight = c("Córdoba", "Neuquén"))', h_sc, "chanwe_hc_scatter", TRUE),
    S("trend", "Con tendencia", "With trend", 'chanwe_scatter(sc, "x", "y", "p", focus = "Mendoza", style = "trend")', h_sc, "chanwe_hc_scatter"),
    S("bubble", "Burbujas", "Bubbles", 'chanwe_scatter(sc, "x", "y", "p", focus = "Mendoza", style = "bubble", size = "pop")', h_sc))),
  B("chanwe_waterfall", "Cómo se llega de un total a otro: qué sumó y qué restó.", "How one total becomes another: what added and what took away.",
    "Partes que no suman a un total: usar barras.", "Parts that do not add up to a total: use bars.", list(
    S("signed", "Con signo", "Signed", 'chanwe_waterfall(wf, "k", "v", end_label = "2025")', h_wf, NULL, TRUE),
    S("totals", "Con totales", "Totals", 'chanwe_waterfall(wf, "k", "v", end_label = "2025", style = "totals")', h_wf))),
  B("chanwe_stack", "La composición de un total y cómo cambia en el tiempo.", "The make-up of a total and how it changes over time.",
    "Comparar partes chicas entre sí: usar barras agrupadas o múltiplos.", "Comparing small parts with each other: use grouped bars or multiples.", list(
    S("stacked", "Apiladas", "Stacked", 'chanwe_stack(st, "y", "s", "v")', h_st, "chanwe_hc_stack", TRUE),
    S("share", "Participación", "Share", 'chanwe_stack(st, "y", "s", "v", style = "share")',
      H("Exportaciones · Sectores", "La energía ya es la primera exportación", "Participación por sector, % del total", "INDEC"), "chanwe_hc_stack"),
    S("grouped", "Agrupadas", "Grouped", 'chanwe_stack(st, "y", "s", "v", style = "grouped", compare = c("2021", "2025"))',
      H("Exportaciones · Sectores", "La energía ya es la primera exportación", "USD millones, 2021 y 2025", "INDEC")))),
  B("chanwe_histogram", "La distribución de una variable y dónde cae la mediana.", "A variable's distribution and where the median falls.",
    "Comparar varios grupos: usar dispersión o densidad.", "Comparing several groups: use spread or density.", list(
    S("median", "Con mediana", "With median", 'chanwe_histogram(hv, "v")', h_hist, NULL, TRUE),
    S("split", "Partido en la mediana", "Split at the median", 'chanwe_histogram(hv, "v", style = "split", note = "← La mitad que gana menos")', h_hist))),
  B("chanwe_spread", "La dispersión de una variable entre grupos.", "A variable's spread across groups.",
    "Un solo grupo: usar un histograma.", "A single group: use a histogram.", list(
    S("box", "Cajas", "Box", 'chanwe_spread(bx, "r", "v", focus = "Cuyo")', h_bx, NULL, TRUE),
    S("violin", "Violín", "Violin", 'chanwe_spread(bx, "r", "v", focus = "Cuyo", style = "violin")', h_bx))),
  B("chanwe_bump", "Cómo cambian las posiciones de un ranking en el tiempo.", "How a ranking's positions change over time.",
    "Importan los valores, no el orden: usar líneas.", "The values matter, not the order: use lines.", list(
    S("default", "Ranking en el tiempo", "Bump", 'chanwe_bump(bp, "y", "p", "rk", focus = "Mendoza")',
      H("Competitividad", "Mendoza subió al primer puesto", "Ranking provincial de competitividad, 2019 a 2025", "elaboración propia"), NULL, TRUE))),
  B("chanwe_multiples", "Muchas series, cada una en su panel y contra las demás.", "Many series, each in its own panel against the rest.",
    "Dos o tres series: usar líneas en un solo panel.", "Two or three series: use lines in one panel.", list(
    S("default", "Múltiplos", "Small multiples", 'chanwe_multiples(mm, "t", "v", "p")',
      H("Empleo · Provincias", "Seis provincias, seis caminos", "Empleo registrado, variación acumulada en puntos, ene-23 a dic-25", "SIPA"), NULL, TRUE))),
  B("chanwe_bullet", "El avance contra una meta, indicador por indicador.", "Progress against a target, indicator by indicator.",
    "Sin meta: usar barras.", "No target: use bars.", list(
    S("default", "Bala", "Bullet", 'chanwe_bullet(bt, "k", "a", "t")',
      H("Metas · 2025", "Cuatro de cinco metas, todavía lejos", "Avance contra la meta anual, %, a noviembre de 2025", "tablero de gestión"), NULL, TRUE))),
  B("chanwe_whole", "Las partes de un total en un momento.", "The parts of a total at one moment.",
    "Más de seis partes o partes en el tiempo: usar barras o composición.", "More than six parts, or parts over time: use bars or stack.", list(
    S("bar", "Barra", "Bar", 'chanwe_whole(pw, "k", "v")', h_pw, NULL, TRUE),
    S("donut", "Dona", "Donut", 'chanwe_whole(pw, "k", "v", style = "donut")', h_pw),
    S("waffle", "Waffle", "Waffle", 'chanwe_whole(pw, "k", "v", style = "waffle")', h_pw),
    S("treemap", "Treemap", "Treemap", 'chanwe_whole(pw, "k", "v", style = "treemap")', h_pw))),
  B("chanwe_forecast", "Una serie y su proyección, con el rango de lo probable.", "A series and its projection, with the range of what is likely.",
    "Sin incertidumbre que mostrar: usar líneas con la proyección punteada.", "No uncertainty to show: use lines with a dotted projection.", list(
    S("fan", "Abanico", "Fan", 'chanwe_forecast(fv, "d", "v", from = mo[36], spread = "s")', h_fc, NULL, TRUE),
    S("zone", "Zona", "Zone", 'chanwe_forecast(fv, "d", "v", from = mo[36], spread = "s", style = "zone")', h_fc))),
  B("chanwe_level_change", "El nivel de una serie y su variación, sin doble eje.", "A series' level and its change, with no second axis.",
    "Sólo importa la variación: usar barras con signo.", "Only the change matters: use signed bars.", list(
    S("change", "Nivel y variación", "Level and change", 'chanwe_level_change(cb, "y", "v")', h_lc, NULL, TRUE),
    S("panels", "Paneles", "Panels", 'chanwe_level_change(cb, "y", "v", style = "panels", level_name = "Miles de toneladas")', h_lc),
    S("strip", "Franja", "Strip", 'chanwe_level_change(cb, "y", "v", style = "strip")', h_lc))),
  B("chanwe_timeseries", "Series fechadas en un eje de días, meses, trimestres, semestres o años: líneas, barras y áreas juntas, un segundo eje, apiladas.",
    "Dated series on a day, month, quarter, half-year or year axis: lines, bars and areas together, a second axis, stacked.",
    "Sin fechas, o una sola serie sin necesidad de eje de períodos: usar líneas o área.", "No dates, or one series that needs no period axis: use lines or area.", list(
    S("lines", "Líneas", "Lines", 'chanwe_timeseries(tsd[tsd$s != "Actividad", ], "t", "v", "s", number = label_chanwe_number(suffix = " %"))', h_ts, NULL, TRUE),
    S("combo", "Línea y barras, dos ejes", "Line and bars, two axes",
      'chanwe_timeseries(tsd, "t", "v", "s", mark = c(Actividad = "bar"), side = c(Actividad = "right"), number = label_chanwe_number(suffix = " %"))', h_ts)))
)

entries <- list()
for (b in catalogue) for (s in b$styles) {
  file <- sprintf("%s-%s.png", sub("^chanwe_", "", b$builder), s$id)
  h <- s$header
  p <- eval(parse(text = s$call, encoding = "UTF-8"), envir = env) +
    labs(title = chanwe_title(h$title, eyebrow = h$eyebrow), subtitle = h$subtitle, caption = paste("Fuente ·", h$source))
  ggsave(file.path(out, "images", file), p, width = 6, height = 4.2, dpi = 200, device = ragg::agg_png, bg = "white")
  entries[[length(entries) + 1]] <- list(
    builder = b$builder, style = s$id, default = s$default, name = s$name, need = b$need, not = b$not,
    call = s$call, header = h, hc = s$hc, image = paste0("images/", file))
  message("  ", file)
}

manifest <- list(
  package = "chanwer", version = version, generated = format(Sys.Date()),
  image = list(format = "png", width = 1200, height = 840, scale = 2, theme = "light"),
  grammar = list(
    es = c("Una sola señal naranja: la serie o categoría que importa; el resto en la rampa slate.",
           "Nombres y valores en mono, visibles pero sin protagonismo.",
           "Grilla horizontal fina, sin líneas de eje ni marcas.",
           "El rótulo nombra el tema, el título dice la conclusión, el subtítulo qué, en qué unidad y qué período; la fuente al pie.",
           "Números en castellano: coma decimal, punto de miles, meses como jun-25."),
    en = c("One orange signal: the series or category that matters; the rest on the slate ramp.",
           "Names and values in mono, visible but not the protagonist.",
           "Horizontal hairline grid, no axis lines or ticks.",
           "The eyebrow names the topic, the title states the claim, the subtitle what, unit and period; the source in the foot.",
           "Numbers in Spanish: decimal comma, thousands dot, months as jun-25.")),
  header = "Each image adds labs(title = chanwe_title(<title>, eyebrow = <eyebrow>), subtitle = <subtitle>, caption = 'Fuente · <source>').",
  setup = trimws(setup),
  entries = entries)
jsonlite::write_json(manifest, file.path(out, "chanwer-catalogue.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
message(sprintf("chanwer %s: %d entries and images in %s", version, length(entries), out))
