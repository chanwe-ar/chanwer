# Interactive builders: the paper catalogue on highcharter. Each one draws the
# same chart as its paper twin (chanwe_bars(), chanwe_lines(), …): the focus in
# orange, the rest on the slate ramp, names and values quiet in mono, numbers
# in Spanish. The header, the caption and the v2 shell come from
# chanwe_highchart(), which every builder calls with `...`.

# Spanish numbers and months in Highcharts' own formatters.
.hc_js_num <- "function(v, d) { return Highcharts.numberFormat(v, d, ',', '.'); }"
.hc_js_month <- paste0(
  "function() { var m = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];",
  " var d = new Date(this.value); return m[d.getUTCMonth()] + '-' + String(d.getUTCFullYear()).slice(2); }"
)
.hc_mono <- function() gsub("'", "\"", .cw_font_mono, fixed = TRUE)
.hc_label_style <- function(colour = chanwe_html_tokens()$fg_muted) {
  list(fontFamily = .hc_mono(), fontSize = paste0(chanwe_tokens$type$caption, "px"), fontWeight = "normal",
       color = colour, textOutline = "none")
}
.hc_x <- function(v) if (inherits(v, "Date")) highcharter::datetime_to_timestamp(v) else v
.hc_tooltip <- function(digits) {
  highcharter::JS(sprintf(paste0(
    "function() { var f = %s; var p = this.points || [this];",
    " return p.map(function(q) { return '<span style=\"color:' + q.color + '\">\\u25CF</span> ' +",
    " (q.series.name || '') + ' ' + f(q.y, %d); }).join('<br/>'); }"), .hc_js_num, digits))
}
.hc_value_labels <- function(digits, colour = chanwe_html_tokens()$fg_muted) {
  list(enabled = TRUE, style = .hc_label_style(colour), crop = FALSE, overflow = "allow",
       formatter = highcharter::JS(sprintf("function() { return (%s)(this.y, %d); }", .hc_js_num, digits)))
}
.hc_date_axis <- function(hc, dates) {
  if (!dates) return(hc)
  highcharter::hc_xAxis(hc, type = "datetime", labels = list(formatter = highcharter::JS(.hc_js_month)))
}

#' Interactive Bars
#'
#' The interactive twin of [chanwe_bars()]: vertical bars with their value on
#' top (`"labelled"`, the default) or a sorted horizontal ranking
#' (`"ranking"`); the focus in orange, the rest on the slate ramp, no y-axis.
#'
#' @param data A data frame.
#' @param x,y Column names (strings): the category and its value.
#' @param focus The category that carries the orange. Default: the largest.
#' @param style `"labelled"` or `"ranking"`.
#' @param digits Decimals of the value labels.
#' @param ... Header and frame arguments for [chanwe_highchart()] (`title`,
#'   `subtitle`, `eyebrow`, `caption`, `height`, `bg`).
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' d <- data.frame(region = c("Cuyo", "Pampeana", "NOA"), ventas = c(41.2, 33.8, 27.5))
#' w <- chanwe_hc_bars(d, "region", "ventas", title = "Cuyo lidera")
chanwe_hc_bars <- function(data, x, y, focus = NULL, style = c("labelled", "ranking"), digits = 1, ...) {
  chanwe_require_package("highcharter")
  style <- match.arg(style)
  d <- data[order(-data[[y]]), , drop = FALSE]
  cats <- as.character(d[[x]])
  focus <- focus %||_% cats[[1]]
  cols <- unname(chanwe_focus_colors(cats, focus)[cats])
  hc <- highcharter::highchart() |>
    highcharter::hc_chart(type = if (style == "ranking") "bar" else "column") |>
    highcharter::hc_xAxis(categories = cats) |>
    highcharter::hc_yAxis(labels = list(enabled = FALSE), gridLineWidth = 0, title = list(text = "")) |>
    highcharter::hc_add_series(name = y, data = as.numeric(d[[y]]), colorByPoint = TRUE, colors = cols,
                               dataLabels = .hc_value_labels(digits), pointPadding = .08, groupPadding = .12) |>
    highcharter::hc_tooltip(formatter = .hc_tooltip(digits), shared = FALSE)
  hc <- chanwe_highchart(hc, ...)
  # chanwe_highchart() sets the y grid for every chart; a labelled bar needs none.
  hc |> highcharter::hc_yAxis(labels = list(enabled = FALSE), gridLineWidth = 0, title = list(text = ""))
}

#' Interactive Lines
#'
#' The interactive twin of [chanwe_lines()]: one line per group, the focus in
#' orange and the rest on the slate ramp (`"direct"`), or the rest as thin
#' ghosts (`"spaghetti"`). Each line is named at its end in slate mono with its
#' last value; names that crowd are pushed apart, so there is no legend.
#'
#' @param data A long data frame.
#' @param x,y,group Column names (strings). `x` may be a Date.
#' @param focus The group that carries the orange. Default: the first.
#' @param style `"direct"` or `"spaghetti"`.
#' @param digits Decimals of the end values.
#' @inheritParams chanwe_hc_bars
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' d <- data.frame(t = rep(1:5, 2), v = c(1:5, 2:6), s = rep(c("A", "B"), each = 5))
#' w <- chanwe_hc_lines(d, "t", "v", "s")
chanwe_hc_lines <- function(data, x, y, group, focus = NULL, style = c("direct", "spaghetti"), digits = 1, ...) {
  chanwe_require_package("highcharter")
  style <- match.arg(style)
  groups <- unique(as.character(data[[group]]))
  focus <- focus %||_% groups[[1]]
  cols <- chanwe_focus_colors(groups, focus)
  ghost <- chanwe_html_tokens()$n300
  hc <- highcharter::highchart()
  ends <- data.frame()
  for (g in c(setdiff(groups, focus), focus)) {
    s <- data[as.character(data[[group]]) == g, , drop = FALSE]
    s <- s[order(s[[x]]), , drop = FALSE]
    is_f <- g == focus
    col <- if (style == "spaghetti" && !is_f) ghost else unname(cols[[g]])
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = g, color = col, zIndex = if (is_f) 10 else 1,
      lineWidth = if (style == "spaghetti" && !is_f) 1 else chanwe_tokens$plot$`line-width`,
      data = Map(function(a, b) list(a, b), .hc_x(s[[x]]), as.numeric(s[[y]])))
    if (style == "direct" || is_f) {
      last <- s[nrow(s), , drop = FALSE]
      ends <- rbind(ends, data.frame(x = .hc_x(last[[x]]), y = as.numeric(last[[y]]), name = g, col = col))
    }
  }
  # The names: a point per line at its end, the label beside it, spread apart.
  ends$label_y <- .cwa_spread(ends$y, 0.1 * diff(range(data[[y]], na.rm = TRUE)))
  hc <- hc |> highcharter::hc_add_series(
    type = "scatter", name = "ends", showInLegend = FALSE, enableMouseTracking = FALSE, zIndex = 11,
    marker = list(enabled = FALSE),
    data = lapply(seq_len(nrow(ends)), function(i) list(
      x = ends$x[i], y = ends$label_y[i],
      dataLabels = list(enabled = TRUE, align = "left", x = 8, verticalAlign = "middle", crop = FALSE,
                        overflow = "allow", allowOverlap = TRUE, style = .hc_label_style(),
                        format = paste0(toupper(ends$name[i]), "  ", .cwa_num(ends$y[i], digits))))))
  hc <- hc |> highcharter::hc_add_series(
    type = "scatter", name = "dots", showInLegend = FALSE, enableMouseTracking = FALSE, zIndex = 12,
    data = lapply(seq_len(nrow(ends)), function(i) list(x = ends$x[i], y = ends$y[i], color = ends$col[i])),
    marker = list(radius = 3, symbol = "circle"))
  hc <- hc |>
    .hc_date_axis(inherits(data[[x]], "Date")) |>
    highcharter::hc_xAxis(maxPadding = .18) |>
    highcharter::hc_tooltip(formatter = .hc_tooltip(digits))
  chanwe_highchart(hc, ...)
}

#' Interactive Area
#'
#' The interactive twin of [chanwe_area()]: the line in orange over a gradient
#' that fades to the axis, the last value in an ink pill.
#'
#' @param data A data frame.
#' @param x,y Column names (strings). `x` may be a Date.
#' @param digits Decimals of the last value.
#' @inheritParams chanwe_hc_bars
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' d <- data.frame(t = 1:12, v = cumsum(c(5, rnorm(11))))
#' w <- chanwe_hc_area(d, "t", "v")
chanwe_hc_area <- function(data, x, y, digits = 1, ...) {
  chanwe_require_package("highcharter")
  tk <- chanwe_html_tokens()
  d <- data[order(data[[x]]), , drop = FALSE]
  n <- nrow(d)
  pts <- Map(function(a, b, i) {
    p <- list(x = a, y = b)
    if (i == n) p$dataLabels <- list(
      enabled = TRUE, align = "left", x = 10, y = 0, verticalAlign = "middle", crop = FALSE, overflow = "allow",
      backgroundColor = tk$ink, borderRadius = tk$radius_pill, padding = 4,
      style = .hc_label_style(tk$white), format = .cwa_num(b, digits))
    p
  }, .hc_x(d[[x]]), as.numeric(d[[y]]), seq_len(n))
  hc <- highcharter::highchart() |>
    highcharter::hc_add_series(
      type = "area", name = y, data = pts, color = tk$primary, zIndex = 2,
      fillColor = list(linearGradient = list(x1 = 0, y1 = 0, x2 = 0, y2 = 1),
                       stops = list(list(0, .hc_alpha(tk$primary, .32)), list(1, .hc_alpha(tk$primary, 0))))) |>
    .hc_date_axis(inherits(data[[x]], "Date")) |>
    highcharter::hc_xAxis(maxPadding = .08) |>
    highcharter::hc_tooltip(formatter = .hc_tooltip(digits))
  chanwe_highchart(hc, ...)
}

#' Interactive Scatter
#'
#' The interactive twin of [chanwe_scatter()]: slate points, the highlighted
#' ones in ink, the focus in orange and larger; the focus and the highlights
#' are named in slate mono. `"trend"` adds the linear fit in ink.
#'
#' @param data A data frame.
#' @param x,y Column names (strings).
#' @param label Column naming each point (string), shown in the tooltip.
#' @param focus The point that carries the orange (a `label` value).
#' @param highlight Points drawn in ink and named (`label` values).
#' @param style `"named"` or `"trend"`.
#' @inheritParams chanwe_hc_bars
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' cars <- transform(mtcars, car = rownames(mtcars))
#' w <- chanwe_hc_scatter(cars, "wt", "mpg", "car", focus = "Fiat 128")
chanwe_hc_scatter <- function(data, x, y, label = NULL, focus = NULL, highlight = NULL,
                              style = c("named", "trend"), ...) {
  chanwe_require_package("highcharter")
  style <- match.arg(style)
  tk <- chanwe_html_tokens()
  lab <- if (is.null(label)) rep("", nrow(data)) else as.character(data[[label]])
  role <- ifelse(lab %in% focus, "focus", ifelse(lab %in% highlight, "highlight", "rest"))
  colour <- c(focus = tk$primary, highlight = tk$ink, rest = chanwe_tokens$plot$slate[[3]])
  radius <- c(focus = 5, highlight = 3.5, rest = chanwe_tokens$plot$`point-size`)
  # A name in the right third of the plot reads leftwards, so it stays inside.
  right <- as.numeric(data[[x]]) > min(data[[x]], na.rm = TRUE) + diff(range(data[[x]], na.rm = TRUE)) * 2 / 3
  pts <- lapply(order(role != "rest"), function(i) {
    p <- list(x = as.numeric(data[[x]][i]), y = as.numeric(data[[y]][i]), name = lab[i],
              color = unname(colour[role[i]]), marker = list(radius = unname(radius[role[i]])))
    if (role[i] != "rest") p$dataLabels <- list(
      enabled = TRUE, format = toupper(lab[i]), align = if (right[i]) "right" else "left", x = if (right[i]) -6 else 6,
      y = -6, style = .hc_label_style(), crop = FALSE, overflow = "allow", allowOverlap = TRUE)
    p
  })
  hc <- highcharter::highchart() |>
    highcharter::hc_add_series(type = "scatter", name = label %||_% y, data = pts, zIndex = 3)
  if (style == "trend") {
    fit <- stats::lm(data[[y]] ~ data[[x]])
    xs <- range(data[[x]], na.rm = TRUE)
    hc <- hc |> highcharter::hc_add_series(
      type = "line", name = "Tendencia", color = tk$ink, lineWidth = 1, enableMouseTracking = FALSE, zIndex = 2,
      data = list(list(xs[1], unname(stats::coef(fit)[1] + stats::coef(fit)[2] * xs[1])),
                  list(xs[2], unname(stats::coef(fit)[1] + stats::coef(fit)[2] * xs[2]))))
  }
  hc <- hc |>
    highcharter::hc_xAxis(title = list(text = x)) |>
    highcharter::hc_yAxis(title = list(text = y)) |>
    highcharter::hc_tooltip(shared = FALSE, pointFormat = paste0("<b>{point.name}</b><br/>", x, " {point.x}<br/>",
                                                                 y, " {point.y}"), headerFormat = "")
  chanwe_highchart(hc, ...)
}

#' Interactive Heatmap
#'
#' The interactive twin of [chanwe_heatmap()]: signed tiles, red through white
#' to green on symmetric limits, so zero is white. `labels = TRUE` prints each
#' value in mono.
#'
#' @param data A long data frame.
#' @param x,y,fill Column names (strings): the two axes and the signed value.
#' @param labels Print the values in the tiles.
#' @param digits Decimals of the values.
#' @inheritParams chanwe_hc_bars
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' d <- expand.grid(week = 1:6, region = c("Norte", "Sur"))
#' d$delta <- c(-2, -1, 0, 1, 2, 3, 1, 0, -1, -2, 1, 2)
#' w <- chanwe_hc_heatmap(d, "week", "region", "delta")
chanwe_hc_heatmap <- function(data, x, y, fill, labels = FALSE, digits = 1, ...) {
  chanwe_require_package("highcharter")
  tk <- chanwe_html_tokens()
  xs <- unique(as.character(data[[x]])); ys <- unique(as.character(data[[y]]))
  m <- max(abs(data[[fill]]), na.rm = TRUE)
  pts <- lapply(seq_len(nrow(data)), function(i) list(
    match(as.character(data[[x]][i]), xs) - 1, match(as.character(data[[y]][i]), ys) - 1, as.numeric(data[[fill]][i])))
  hc <- highcharter::highchart() |>
    highcharter::hc_add_series(
      type = "heatmap", name = fill, data = pts, borderWidth = 2, borderColor = tk$white,
      dataLabels = if (labels) list(
        enabled = TRUE, style = .hc_label_style(tk$ink),
        formatter = highcharter::JS(sprintf("function() { return (%s)(this.point.value, %d); }", .hc_js_num, digits))
      ) else list(enabled = FALSE)) |>
    highcharter::hc_xAxis(categories = xs) |>
    highcharter::hc_yAxis(categories = ys, title = list(text = ""), reversed = TRUE, gridLineWidth = 0) |>
    highcharter::hc_colorAxis(min = -m, max = m) |>
    highcharter::hc_legend(enabled = FALSE) |>
    highcharter::hc_tooltip(shared = FALSE, formatter = highcharter::JS(sprintf(
      "function() { return this.series.xAxis.categories[this.point.x] + ' \\u00B7 ' +
       this.series.yAxis.categories[this.point.y] + ': ' + (%s)(this.point.value, %d); }", .hc_js_num, digits)))
  hc <- chanwe_highchart(hc, ...)
  hc |> highcharter::hc_yAxis(gridLineWidth = 0)
}

#' Interactive Stacked Columns
#'
#' The interactive twin of [chanwe_stack()]: columns stacked by part
#' (`"stacked"`) or as shares of 100 % (`"share"`); the focus part in orange
#' at the base, the rest on the slate ramp, a pill legend.
#'
#' @param data A long data frame.
#' @param x,part,value Column names (strings).
#' @param focus The part that carries the orange. Default: the first.
#' @param style `"stacked"` or `"share"`.
#' @inheritParams chanwe_hc_bars
#' @return A highchart htmlwidget.
#' @export
#' @examples
#' d <- data.frame(y = rep(c("2024", "2025"), each = 2), s = rep(c("A", "B"), 2), v = c(3, 5, 4, 6))
#' w <- chanwe_hc_stack(d, "y", "s", "v")
chanwe_hc_stack <- function(data, x, part, value, focus = NULL, style = c("stacked", "share"), digits = 1, ...) {
  chanwe_require_package("highcharter")
  style <- match.arg(style)
  cats <- unique(as.character(data[[x]]))
  parts <- unique(as.character(data[[part]]))
  focus <- focus %||_% parts[[1]]
  cols <- chanwe_focus_colors(parts, focus)
  hc <- highcharter::highchart() |>
    highcharter::hc_chart(type = "column") |>
    highcharter::hc_xAxis(categories = cats) |>
    highcharter::hc_plotOptions(column = list(stacking = if (style == "share") "percent" else "normal",
                                              borderColor = chanwe_html_tokens()$white, borderWidth = 1))
  # The focus last, so Highcharts stacks it at the base.
  for (p in c(setdiff(parts, focus), focus)) {
    v <- vapply(cats, function(cc) sum(data[[value]][as.character(data[[x]]) == cc & as.character(data[[part]]) == p]),
                numeric(1))
    hc <- hc |> highcharter::hc_add_series(name = p, data = unname(v), color = unname(cols[[p]]),
                                           legendIndex = match(p, parts))
  }
  hc <- hc |> highcharter::hc_tooltip(formatter = .hc_tooltip(digits))
  args <- utils::modifyList(list(legend = TRUE), list(...))
  hc <- do.call(chanwe_highchart, c(list(hc), args))
  hc |> highcharter::hc_legend(align = "center", verticalAlign = "bottom", layout = "horizontal")
}

# A colour at an opacity, as CSS rgba() for Highcharts.
.hc_alpha <- function(hex, a) {
  v <- grDevices::col2rgb(hex)
  sprintf("rgba(%d,%d,%d,%s)", v[1], v[2], v[3], format(a))
}
