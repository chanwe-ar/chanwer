# The chart builders (Ale's picks, round 6, 2026-11-19): one function per
# everyday chart, its look decided once. Each returns a ggplot with the Chanwe
# theme; add labs() for the title, the subtitle and the source. The first value
# of `style` is the default; the others are the alternatives he kept.

.cwc_col <- function(name) chanwe_get_colors()[[name]]
.cwc_slate <- function(i) chanwe_tokens$plot$slate[[i]]

# The focus: the series, bar or group that carries the orange. Without one the
# builders take the first level (the top of a sorted ranking, the first series).
.cwc_focus <- function(values, focus) {
  if (!is.null(focus)) return(focus)
  lv <- if (is.factor(values)) levels(values) else unique(as.character(values))
  lv[[1]]
}

.cwc_signed <- function(v, digits = 1) {
  out <- .cwa_num(v, digits)
  ifelse(v > 0, paste0("+", out), out)
}

#' Bars
#'
#' The Chanwe bar chart. `style = "labelled"` (the default) draws vertical bars
#' with their value on top in mono, no y-axis and no grid; `"ranking"` lays them
#' flat, sorted, the value at the end and an optional reference (the median);
#' `"lollipop"` draws a hairline stem and a dot per category, for long lists.
#' The focus bar is orange, the rest sit on the slate ramp.
#'
#' @param data A data frame.
#' @param x,y Column names (strings): the category and the value.
#' @param focus The category that carries the orange; default the largest.
#' @param style `"labelled"`, `"ranking"` or `"lollipop"`.
#' @param labels Print the values. Default `TRUE`.
#' @param digits Decimals of the labels.
#' @param reference A value to mark on a ranking (for example the median), or
#'   `NULL`.
#' @param reference_label Its name.
#' @param sort Sort the categories by value. Default `TRUE`.
#' @param theme The theme; default [theme_chanwe()].
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(region = c("Cuyo", "Pampeana", "NOA"), ventas = c(41.2, 33.8, 27.5))
#' p <- chanwe_bars(d, "region", "ventas")
chanwe_bars <- function(data, x, y, focus = NULL, style = c("labelled", "ranking", "lollipop"),
                        labels = TRUE, digits = 1, reference = NULL, reference_label = "Mediana",
                        sort = TRUE, theme = theme_chanwe()) {
  style <- match.arg(style)
  d <- data
  ord <- if (sort) as.character(d[[x]])[order(-d[[y]])] else unique(as.character(d[[x]]))
  focus <- if (is.null(focus)) ord[[1]] else focus
  d$.lab <- .cwa_num(d[[y]], digits)
  d$.focus <- as.character(d[[x]]) == focus
  mono <- "JetBrains Mono"
  if (style == "labelled") {
    d[[x]] <- factor(d[[x]], ord)
    p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data[[y]], fill = .data[[x]])) +
      geom_chanwe_col(width = .62, show.legend = FALSE) +
      scale_fill_chanwe_focus(focus) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(c(0, .14))) +
      theme + ggplot2::theme(axis.text.y = ggplot2::element_blank(),
                             panel.grid.major.y = ggplot2::element_blank(), panel.grid.major.x = ggplot2::element_blank())
    if (labels) p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$.lab, colour = .data$.focus), vjust = -.7,
                                            family = mono, size = 2.5, show.legend = FALSE) +
      ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("ink"), `FALSE` = .cwc_col("fg-muted")), guide = "none")
    return(p + ggplot2::labs(x = NULL, y = NULL))
  }
  d[[x]] <- factor(d[[x]], rev(ord))
  if (style == "ranking") {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data[[y]], .data[[x]], fill = .data[[x]])) +
      geom_chanwe_col(orientation = "y", width = .58, show.legend = FALSE) +
      scale_fill_chanwe_focus(focus)
  } else {
    p <- ggplot2::ggplot(d, ggplot2::aes(.data[[y]], .data[[x]], colour = .data[[x]])) +
      ggplot2::geom_segment(ggplot2::aes(x = 0, xend = .data[[y]], yend = .data[[x]]), linewidth = .5, show.legend = FALSE) +
      ggplot2::geom_point(size = 3, show.legend = FALSE) +
      scale_color_chanwe_focus(focus)
  }
  if (labels) p <- p + ggplot2::geom_text(ggplot2::aes(label = .data$.lab), hjust = if (style == "ranking") -.25 else -.45,
                                          family = mono, size = 2.5, colour = .cwc_col("fg-muted"), inherit.aes = TRUE,
                                          show.legend = FALSE)
  if (!is.null(reference)) p <- p + annotate_chanwe_reference(reference, reference_label, n_bars = nrow(d))
  # A ranking labels itself, so it drops the x-axis and its grid; a lollipop
  # keeps the vertical grid as its scale.
  tweak <- if (style == "ranking") ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                                                  panel.grid.major.x = ggplot2::element_blank(),
                                                  panel.grid.major.y = ggplot2::element_blank())
           else ggplot2::theme(panel.grid.major.y = ggplot2::element_blank())
  p + ggplot2::scale_x_continuous(expand = ggplot2::expansion(c(0, .12))) + theme + tweak +
    ggplot2::labs(x = NULL, y = NULL)
}

#' Several Series
#'
#' The Chanwe line chart for several series. `style = "direct"` (the default):
#' the focus series in orange, the rest on the slate ramp, each named at its end
#' with its last value, no legend. `"spaghetti"`: every other series as a thin
#' slate line, unnamed, and only the focus in orange and named; for many series.
#'
#' @param data A data frame in long form.
#' @param x,y,group Column names (strings).
#' @param focus The series that carries the orange; default the first level.
#' @param style `"direct"` or `"spaghetti"`.
#' @param values Print the last value beside each name. Default `TRUE`.
#' @param theme The theme; default [theme_chanwe()].
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(t = rep(1:5, 2), v = c(1:5, 2:6), s = rep(c("A", "B"), each = 5))
#' p <- chanwe_lines(d, "t", "v", "s")
chanwe_lines <- function(data, x, y, group, focus = NULL, style = c("direct", "spaghetti"),
                         values = TRUE, theme = theme_chanwe()) {
  style <- match.arg(style)
  focus <- .cwc_focus(data[[group]], focus)
  dates <- inherits(data[[x]], "Date")
  xs <- if (dates) ggplot2::scale_x_date(labels = label_chanwe_month(), expand = ggplot2::expansion(c(.01, .22)))
        else ggplot2::scale_x_continuous(expand = ggplot2::expansion(c(.01, .22)))
  if (style == "direct") {
    p <- ggplot2::ggplot(data, ggplot2::aes(.data[[x]], .data[[y]], colour = .data[[group]])) +
      ggplot2::geom_line(linewidth = .65, show.legend = FALSE) +
      annotate_chanwe_ends(data, x, y, group, values = values) +
      scale_color_chanwe_focus(focus)
  } else {
    fd <- data[as.character(data[[group]]) == focus, , drop = FALSE]
    rest <- data[as.character(data[[group]]) != focus, , drop = FALSE]
    p <- ggplot2::ggplot(data, ggplot2::aes(.data[[x]], .data[[y]], group = .data[[group]])) +
      ggplot2::geom_line(data = rest, colour = .cwc_slate(4), linewidth = .45) +
      ggplot2::geom_line(data = fd, colour = .cwc_col("primary"), linewidth = .8) +
      annotate_chanwe_ends(fd, x, y, group, values = values) +
      ggplot2::scale_colour_manual(values = stats::setNames(.cwc_col("primary"), focus), guide = "none")
  }
  # The end labels sit outside the last point, so the panel does not clip them.
  p + xs + ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::theme(legend.position = "none") +
    ggplot2::labs(x = NULL, y = NULL)
}

#' Area
#'
#' The Chanwe area chart: the line at 2px over a gradient of its own colour that
#' fades to nothing at the axis, and the last value in the ink pill. Orange is
#' never the background of an area: the gradient carries it lightly.
#'
#' @param data A data frame.
#' @param x,y Column names (strings).
#' @param colour The line's colour; default the brand orange.
#' @param main Mark the last value ([annotate_chanwe_main()]). Default `TRUE`.
#' @param digits Decimals of that value.
#' @param theme The theme; default [theme_chanwe()].
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(t = 1:12, v = cumsum(c(5, rnorm(11))))
#' p <- chanwe_area(d, "t", "v")
chanwe_area <- function(data, x, y, colour = NULL, main = TRUE, digits = 1, theme = theme_chanwe()) {
  colour <- colour %||_% .cwc_col("primary")
  grad <- grid::linearGradient(colours = c(grDevices::adjustcolor(colour, .32), grDevices::adjustcolor(colour, 0)),
                               x1 = 0, y1 = 1, x2 = 0, y2 = 0)
  dates <- inherits(data[[x]], "Date")
  xs <- if (dates) ggplot2::scale_x_date(labels = label_chanwe_month(), expand = ggplot2::expansion(c(.01, .08)))
        else ggplot2::scale_x_continuous(expand = ggplot2::expansion(c(.01, .08)))
  p <- ggplot2::ggplot(data, ggplot2::aes(.data[[x]], .data[[y]])) +
    ggplot2::geom_area(fill = grad) +
    ggplot2::geom_line(colour = colour, linewidth = .7)
  if (main) {
    last <- data[which.max(data[[x]]), , drop = FALSE]
    p <- p + annotate_chanwe_main(last[[x]], last[[y]], label = .cwa_num(last[[y]], digits))
  }
  p + xs + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Diverging Heatmap
#'
#' The Chanwe heatmap: tiles on the diverging ramp, symmetric around zero.
#' `labels = TRUE` prints the signed value in each cell in mono.
#'
#' @param data A data frame.
#' @param x,y,fill Column names (strings).
#' @param labels Print the values in the cells. Default `FALSE`.
#' @param limits The ramp's limits; default symmetric around zero.
#' @param digits Decimals of the labels.
#' @param theme The theme; default [theme_chanwe()] without a grid.
#' @return A ggplot.
#' @export
#' @examples
#' d <- expand.grid(w = 1:4, r = c("Norte", "Sur")); d$delta <- c(-3, 1, 4, -2, 0, 5, -6, 2)
#' p <- chanwe_heatmap(d, "w", "r", "delta", labels = TRUE)
chanwe_heatmap <- function(data, x, y, fill, labels = FALSE, limits = NULL, digits = 1,
                           theme = theme_chanwe(grid = "none")) {
  m <- max(abs(data[[fill]]), na.rm = TRUE)
  limits <- limits %||_% c(-m, m)
  p <- ggplot2::ggplot(data, ggplot2::aes(.data[[x]], .data[[y]], fill = .data[[fill]])) +
    ggplot2::geom_tile(colour = .cwc_col("pure-white"), linewidth = .6) +
    scale_fill_chanwe_div(limits = limits)
  if (labels) {
    d <- data
    d$.lab <- .cwc_signed(d[[fill]], digits)
    # On the strongest cells the label goes white, as text on a deep fill.
    d$.strong <- abs(d[[fill]]) > max(abs(limits)) * .6
    p <- p + ggplot2::geom_text(data = d, ggplot2::aes(label = .data$.lab, colour = .data$.strong),
                                family = "JetBrains Mono", size = 2.1, show.legend = FALSE) +
      ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("pure-white"), `FALSE` = .cwc_col("ink")), guide = "none")
  }
  if (is.numeric(data[[x]])) p <- p + ggplot2::scale_x_continuous(breaks = sort(unique(data[[x]])))
  p + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Distributions
#'
#' The Chanwe density chart. `style = "gradient"` (the default): each
#' distribution as a line over a gradient of its own colour that fades to white
#' at the axis, named on the chart, the focus group in orange and the rest on the
#' slate ramp. `"outline"`: the lines alone. `medians = TRUE` adds each median as
#' a dotted line.
#'
#' @param data A data frame.
#' @param x Column name (string) of the values.
#' @param group Column name (string) of the groups, or `NULL` for one.
#' @param focus The group that carries the orange; default the first level.
#' @param style `"gradient"` or `"outline"`.
#' @param medians Mark each median. Default `FALSE`.
#' @param theme The theme; default [theme_chanwe()].
#' @return A ggplot.
#' @export
#' @examples
#' p <- chanwe_density(mtcars, "mpg")
chanwe_density <- function(data, x, group = NULL, focus = NULL, style = c("gradient", "outline"),
                           medians = FALSE, theme = theme_chanwe()) {
  style <- match.arg(style)
  d <- data
  if (is.null(group)) { d$.g <- "all"; group <- ".g" }
  d[[group]] <- factor(d[[group]], if (is.factor(d[[group]])) levels(d[[group]]) else unique(d[[group]]))
  focus <- .cwc_focus(d[[group]], focus)
  lv <- levels(d[[group]])
  others <- setdiff(lv, focus)
  cols <- stats::setNames(c(.cwc_col("primary"), vapply(seq_along(others), function(i) .cwc_slate(min(1 + i, 5)), "")),
                          c(focus, others))
  dens <- do.call(rbind, lapply(lv, function(g) {
    v <- d[[x]][d[[group]] == g]
    k <- stats::density(v, na.rm = TRUE)
    data.frame(x = k$x, y = k$y, g = g)
  }))
  p <- ggplot2::ggplot(dens, ggplot2::aes(.data$x, .data$y))
  if (style == "gradient") for (g in lv) {
    grad <- grid::linearGradient(colours = c(grDevices::adjustcolor(cols[[g]], .26), grDevices::adjustcolor(.cwc_col("pure-white"), 0)),
                                 x1 = 0, y1 = 1, x2 = 0, y2 = 0)
    p <- p + ggplot2::geom_area(data = dens[dens$g == g, ], fill = grad, position = "identity")
  }
  p <- p + ggplot2::geom_line(ggplot2::aes(colour = .data$g), linewidth = .7, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = cols)
  if (medians) {
    md <- data.frame(g = lv, m = vapply(lv, function(g) stats::median(d[[x]][d[[group]] == g], na.rm = TRUE), 0))
    p <- p + ggplot2::geom_vline(data = md, ggplot2::aes(xintercept = .data$m, colour = .data$g),
                                 linetype = "22", linewidth = .3, show.legend = FALSE)
  }
  if (length(lv) > 1) {
    peaks <- do.call(rbind, lapply(lv, function(g) { s <- dens[dens$g == g, ]; s[which.max(s$y), ] }))
    p <- p + ggplot2::geom_text(data = peaks, ggplot2::aes(.data$x, .data$y, label = toupper(.data$g), colour = .data$g),
                                vjust = -.8, family = "JetBrains Mono", size = 2.3, show.legend = FALSE)
  }
  p + ggplot2::scale_y_continuous(expand = ggplot2::expansion(c(0, .12))) + theme + ggplot2::labs(x = NULL, y = NULL)
}
