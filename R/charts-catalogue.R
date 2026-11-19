# The chart catalogue (Ale's picks, round 7, 2026-11-19). One builder per chart
# type; the first value of `style` is the default. Names and axis labels are
# visible but quiet: slate mono, never the series colour.

.cwc_mono <- "JetBrains Mono"
.cwc_quiet <- function() .cwc_col("fg-muted")
.cwc_label <- function(...) ggplot2::geom_text(..., family = .cwc_mono, size = 2.3, colour = .cwc_quiet())
.cwc_pastel <- function(name, t = .5) .cw_mix(.cwc_col(name), .cwc_col("pure-white"), t)
.cwc_ord <- function(d, x, y, desc = TRUE) {
  o <- as.character(d[[x]])[order(if (desc) -d[[y]] else d[[y]])]
  factor(d[[x]], rev(o))
}

#' Dot Plot
#'
#' One dot per category. `style = "values"` (default): the dot on a hairline
#' guide with its value; `"range"`: the dot on the band of its range
#' (`lo` to `hi`), to show where each one stands against itself.
#'
#' @param data A data frame.
#' @param x,y Column names (strings): the category and the value.
#' @param focus The category in orange; default the largest.
#' @param style `"values"` or `"range"`.
#' @param lo,hi Column names of the range, for `style = "range"`.
#' @param digits Decimals of the labels.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(p = c("A", "B", "C"), v = c(30, 22, 41))
#' p <- chanwe_dots(d, "p", "v")
chanwe_dots <- function(data, x, y, focus = NULL, style = c("values", "range"), lo = NULL, hi = NULL,
                        digits = 1, theme = theme_chanwe(grid = "none")) {
  style <- match.arg(style)
  d <- data
  d[[x]] <- .cwc_ord(d, x, y)
  focus <- focus %||_% rev(levels(d[[x]]))[[1]]
  d$.f <- as.character(d[[x]]) == focus
  cols <- c(`TRUE` = .cwc_col("primary"), `FALSE` = .cwc_slate(2))
  p <- ggplot2::ggplot(d, ggplot2::aes(.data[[y]], .data[[x]]))
  if (style == "values") {
    p <- p + ggplot2::geom_segment(ggplot2::aes(x = min(.data[[y]]) * .92, xend = .data[[y]], yend = .data[[x]]),
                                   colour = .cwc_col("rule"), linewidth = .35) +
      ggplot2::geom_point(ggplot2::aes(colour = .data$.f), size = 2.8, show.legend = FALSE) +
      .cwc_label(ggplot2::aes(label = .cwa_num(.data[[y]], digits)), hjust = -.6)
  } else {
    stopifnot(!is.null(lo), !is.null(hi))
    p <- p + ggplot2::geom_segment(ggplot2::aes(x = .data[[lo]], xend = .data[[hi]], yend = .data[[x]]),
                                   colour = .cwc_slate(5), linewidth = 2.2, lineend = "round") +
      ggplot2::geom_point(ggplot2::aes(colour = .data$.f), size = 2.6, show.legend = FALSE)
    cols[["FALSE"]] <- .cwc_col("ink")
  }
  p + ggplot2::scale_colour_manual(values = cols) + ggplot2::coord_cartesian(clip = "off") +
    theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Dumbbell
#'
#' Before and after per category: the earlier value in slate, the later in
#' orange, joined by a slate bar, and the change in mono at the end.
#'
#' @param data A data frame.
#' @param x Column name (string) of the categories.
#' @param from,to Column names of the two values.
#' @param labels The names of the two moments, for the key above the first row.
#' @param digits Decimals of the change.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(p = c("A", "B"), a = c(20, 30), b = c(24, 27))
#' p <- chanwe_dumbbell(d, "p", "a", "b", labels = c("2024", "2025"))
chanwe_dumbbell <- function(data, x, from, to, labels = c("Antes", "Después"), digits = 1,
                            theme = theme_chanwe(grid = "x")) {
  d <- data
  d$.chg <- d[[to]] - d[[from]]
  d[[x]] <- factor(d[[x]], as.character(d[[x]])[order(d$.chg)])
  top <- d[d[[x]] == levels(d[[x]])[nlevels(d[[x]])], ]
  ggplot2::ggplot(d, ggplot2::aes(y = .data[[x]])) +
    ggplot2::geom_segment(ggplot2::aes(x = .data[[from]], xend = .data[[to]], yend = .data[[x]]), colour = .cwc_slate(4), linewidth = .9) +
    ggplot2::geom_point(ggplot2::aes(x = .data[[from]]), colour = .cwc_slate(3), size = 2.6) +
    ggplot2::geom_point(ggplot2::aes(x = .data[[to]]), colour = .cwc_col("primary"), size = 2.8) +
    .cwc_label(ggplot2::aes(x = pmax(.data[[from]], .data[[to]]), label = .cwc_signed(.data$.chg, digits)), hjust = -.5) +
    ggplot2::annotate("text", x = c(top[[from]], top[[to]]), y = nlevels(d[[x]]) + .45, label = labels,
                      family = .cwc_mono, size = 2.1, colour = c(.cwc_slate(3), .cwc_col("primary"))) +
    ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Slope
#'
#' How a few categories moved between two dates: each line in slate, the focus
#' in orange, each named with its value at both ends, no axis.
#'
#' @param data A data frame, one row per category.
#' @param group Column name of the categories.
#' @param from,to Column names of the two values.
#' @param labels The names of the two dates.
#' @param focus The category in orange; default the largest gain.
#' @param digits Decimals.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(p = c("A", "B", "C"), a = c(10, 20, 15), b = c(18, 17, 16))
#' p <- chanwe_slope(d, "p", "a", "b", labels = c("2020", "2025"))
chanwe_slope <- function(data, group, from, to, labels = c("Antes", "Después"), focus = NULL, digits = 1,
                         theme = theme_chanwe(grid = "none")) {
  focus <- focus %||_% as.character(data[[group]])[which.max(data[[to]] - data[[from]])]
  long <- rbind(data.frame(g = data[[group]], t = 1, v = data[[from]]), data.frame(g = data[[group]], t = 2, v = data[[to]]))
  long$.f <- as.character(long$g) == focus
  ggplot2::ggplot(long, ggplot2::aes(.data$t, .data$v, group = .data$g, colour = .data$.f)) +
    ggplot2::geom_line(linewidth = .6, show.legend = FALSE) + ggplot2::geom_point(size = 1.8, show.legend = FALSE) +
    .cwc_label(data = long[long$t == 1, ], ggplot2::aes(label = paste(toupper(.data$g), .cwa_num(.data$v, digits))), hjust = 1.08) +
    .cwc_label(data = long[long$t == 2, ], ggplot2::aes(label = paste(.cwa_num(.data$v, digits), toupper(.data$g))), hjust = -.08) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("primary"), `FALSE` = .cwc_slate(4))) +
    ggplot2::scale_x_continuous(breaks = 1:2, labels = labels, expand = ggplot2::expansion(.55)) +
    ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::theme(axis.text.y = ggplot2::element_blank()) +
    ggplot2::labs(x = NULL, y = NULL)
}

#' Scatter
#'
#' `style = "named"` (default): every point in slate, the points in `highlight`
#' in ink and named, the `focus` in orange. `"trend"`: the fitted line and its
#' band on the slate tint. `"bubble"`: a third measure (`size`) as the area,
#' white rings so overlaps stay readable.
#'
#' @param data A data frame.
#' @param x,y Column names of the two measures.
#' @param label Column name of the point names.
#' @param focus The point in orange (a value of `label`).
#' @param highlight Other points to name.
#' @param style `"named"`, `"trend"` or `"bubble"`.
#' @param size Column name of the size, for `"bubble"`.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' p <- chanwe_scatter(transform(mtcars, n = rownames(mtcars)), "wt", "mpg", "n", focus = "Fiat 128")
chanwe_scatter <- function(data, x, y, label = NULL, focus = NULL, highlight = NULL,
                           style = c("named", "trend", "bubble"), size = NULL, theme = theme_chanwe(grid = "y")) {
  style <- match.arg(style)
  d <- data
  is_f <- if (!is.null(label) && !is.null(focus)) as.character(d[[label]]) == focus else rep(FALSE, nrow(d))
  P <- .cwc_col("primary")
  p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data[[y]]))
  if (style == "bubble") {
    stopifnot(!is.null(size))
    d$.f <- is_f
    p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data[[y]], size = .data[[size]])) +
      ggplot2::geom_point(ggplot2::aes(fill = .data$.f), shape = 21, colour = .cwc_col("pure-white"), stroke = .6, alpha = .9,
                          show.legend = FALSE) +
      ggplot2::scale_fill_manual(values = c(`TRUE` = P, `FALSE` = .cwc_slate(3))) + ggplot2::scale_size_area(max_size = 11)
  } else {
    if (style == "trend") p <- p + ggplot2::geom_smooth(method = "lm", formula = y ~ x, colour = .cwc_col("ink"),
                                                         fill = .cwc_col("surface-slate"), linewidth = .5, alpha = 1)
    p <- p + ggplot2::geom_point(colour = if (style == "trend") .cwc_slate(3) else .cwc_slate(4), size = 2.1)
    if (!is.null(label) && length(highlight)) {
      h <- d[as.character(d[[label]]) %in% highlight, , drop = FALSE]
      p <- p + ggplot2::geom_point(data = h, colour = .cwc_col("ink"), size = 2.3)
    }
    if (any(is_f)) p <- p + ggplot2::geom_point(data = d[is_f, , drop = FALSE], colour = P, size = 3)
  }
  if (!is.null(label)) {
    named <- d[as.character(d[[label]]) %in% c(focus, highlight), , drop = FALSE]
    if (nrow(named)) p <- p + .cwc_label(data = named, ggplot2::aes(.data[[x]], .data[[y]], label = toupper(.data[[label]])),
                                         hjust = -.15, vjust = -.7, inherit.aes = FALSE)
  }
  p + theme
}

#' Waterfall
#'
#' What explains the change from one total to another. The first row is the
#' starting total; the last total is computed. `style = "signed"` (default):
#' increases in pastel green, decreases in pastel red, the totals in pale slate;
#' `"totals"`: the steps in pale slate with the change as a signed pill and the
#' two totals in a pastel orange.
#'
#' @param data A data frame: the first row the starting total, then the steps.
#' @param step,value Column names (strings).
#' @param end_label The name of the final total.
#' @param style `"signed"` or `"totals"`.
#' @param digits Decimals.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(k = c("2024", "Precios", "Costos"), v = c(100, 12, -5))
#' p <- chanwe_waterfall(d, "k", "v", end_label = "2025")
chanwe_waterfall <- function(data, step, value, end_label = "Total", style = c("signed", "totals"), digits = 0,
                             theme = theme_chanwe(grid = "y")) {
  style <- match.arg(style)
  v <- data[[value]]
  k <- c(as.character(data[[step]]), end_label)
  end <- c(cumsum(v), sum(v))
  start <- c(0, head(cumsum(v), -1), 0)
  type <- c("total", ifelse(v[-1] > 0, "up", "down"), "total")
  d <- data.frame(i = seq_along(k), k = k, v = c(v, sum(v)), start = start, end = end, type = type)
  fills <- if (style == "signed") c(total = .cwc_slate(4), up = .cwc_pastel("kpi-green", .45), down = .cwc_pastel("kpi-red", .45))
           else c(total = .cwc_pastel("primary", .2), up = .cwc_slate(5), down = .cwc_slate(5))
  p <- ggplot2::ggplot(d) +
    ggplot2::geom_rect(ggplot2::aes(xmin = .data$i - .32, xmax = .data$i + .32, ymin = .data$start, ymax = .data$end, fill = .data$type)) +
    ggplot2::geom_segment(data = d[-nrow(d), ], ggplot2::aes(x = .data$i + .32, xend = .data$i + .68, y = .data$end, yend = .data$end),
                          colour = .cwc_slate(4), linewidth = .3, linetype = "22") +
    ggplot2::scale_fill_manual(values = fills, guide = "none")
  if (style == "signed") {
    p <- p + .cwc_label(ggplot2::aes(.data$i, pmax(.data$start, .data$end),
                                     label = ifelse(.data$type == "total", .cwa_num(.data$v, digits), .cwc_signed(.data$v, digits))), vjust = -.6)
  } else {
    st <- d[d$type != "total", ]
    p <- p + ggplot2::geom_label(data = st, ggplot2::aes(.data$i, pmax(.data$start, .data$end), label = .cwc_signed(.data$v, digits),
                                                         colour = .data$type), vjust = -.35, fill = .cwc_col("pure-white"),
                                 family = .cwc_mono, size = 2.1, label.size = 0, label.r = grid::unit(5, "pt"), show.legend = FALSE) +
      ggplot2::scale_colour_manual(values = c(up = .cwc_col("kpi-green"), down = .cwc_col("kpi-red"))) +
      .cwc_label(data = d[d$type == "total", ], ggplot2::aes(.data$i, .data$end, label = .cwa_num(.data$v, digits)), vjust = -.6)
  }
  p + ggplot2::scale_x_continuous(breaks = d$i, labels = d$k) +
    ggplot2::scale_y_continuous(expand = ggplot2::expansion(c(0, .1))) + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Composition Over Time
#'
#' How a total splits into parts. `style = "stacked"` (default): the focus part
#' at the base in orange, the rest on the slate ramp; `"share"`: 100 % with the
#' shares written in; `"grouped"`: two periods side by side per part (`compare`).
#'
#' @param data A data frame in long form.
#' @param x,part,value Column names (strings).
#' @param focus The part in orange; default the first level.
#' @param style `"stacked"`, `"share"` or `"grouped"`.
#' @param compare For `"grouped"`, the two values of `x` to compare.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(y = rep(2024:2025, each = 2), s = rep(c("A", "B"), 2), v = c(3, 5, 4, 5))
#' p <- chanwe_stack(d, "y", "s", "v")
chanwe_stack <- function(data, x, part, value, focus = NULL, style = c("stacked", "share", "grouped"),
                         compare = NULL, theme = theme_chanwe(grid = "y")) {
  style <- match.arg(style)
  d <- data
  lv <- if (is.factor(d[[part]])) levels(d[[part]]) else unique(as.character(d[[part]]))
  focus <- focus %||_% lv[[1]]
  lv <- c(focus, setdiff(lv, focus))
  ramp <- c(.cwc_slate(2), .cwc_slate(4), .cwc_slate(5), .cwc_col("surface-slate"))
  cols <- stats::setNames(c(.cwc_col("primary"), rep(ramp, length.out = length(lv) - 1)), lv)
  d[[x]] <- factor(d[[x]])
  if (style == "grouped") {
    compare <- compare %||_% range(as.character(d[[x]]))
    g <- d[as.character(d[[x]]) %in% compare, ]
    g[[part]] <- factor(g[[part]], lv); g[[x]] <- factor(g[[x]], compare)
    return(ggplot2::ggplot(g, ggplot2::aes(.data[[part]], .data[[value]], fill = .data[[x]])) +
      ggplot2::geom_col(position = ggplot2::position_dodge(.7), width = .62) +
      .cwc_label(ggplot2::aes(label = .cwa_num(.data[[value]], 0)), position = ggplot2::position_dodge(.7), vjust = -.6) +
      ggplot2::scale_fill_manual(values = stats::setNames(c(.cwc_slate(4), .cwc_col("primary")), compare), name = NULL) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(c(0, .12))) +
      theme + ggplot2::theme(axis.text.y = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank()) +
      ggplot2::labs(x = NULL, y = NULL))
  }
  d[[part]] <- factor(d[[part]], rev(lv))
  if (style == "share") {
    tot <- stats::ave(d[[value]], d[[x]], FUN = sum)
    d$.v <- d[[value]] / tot * 100
  } else d$.v <- d[[value]]
  p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data$.v, fill = .data[[part]])) +
    ggplot2::geom_col(width = .62, colour = .cwc_col("pure-white"), linewidth = .5) +
    ggplot2::scale_fill_manual(values = cols, breaks = lv, name = NULL)
  if (style == "share") p <- p + ggplot2::geom_text(ggplot2::aes(label = .cwa_num(.data$.v, 0), colour = .data[[part]] == focus),
                                                     position = ggplot2::position_stack(vjust = .5), family = .cwc_mono, size = 2.1,
                                                     show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("pure-white"), `FALSE` = .cwc_quiet()), guide = "none")
  p + theme + (if (style == "share") ggplot2::theme(axis.text.y = ggplot2::element_blank(), panel.grid.major.y = ggplot2::element_blank())) +
    ggplot2::labs(x = NULL, y = NULL)
}

#' Histogram
#'
#' `style = "median"` (default): slate bins and the median as an orange rule
#' with an ink pill; `"split"`: the bins below the median in orange, the rest in
#' pale slate, and an optional `note` in the editorial italic.
#'
#' @param data A data frame.
#' @param x Column name of the values.
#' @param style `"median"` or `"split"`.
#' @param bins Number of bins.
#' @param note For `"split"`, a sentence on the orange half.
#' @param label The pill's label.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' p <- chanwe_histogram(data.frame(v = rnorm(200)), "v")
chanwe_histogram <- function(data, x, style = c("median", "split"), bins = 36, note = NULL, label = "Mediana",
                             theme = theme_chanwe(grid = "y")) {
  style <- match.arg(style)
  md <- stats::median(data[[x]], na.rm = TRUE)
  W <- .cwc_col("pure-white")
  if (style == "median") {
    p <- ggplot2::ggplot(data, ggplot2::aes(.data[[x]])) +
      ggplot2::geom_histogram(bins = bins, fill = .cwc_slate(4), colour = W, linewidth = .3) +
      ggplot2::geom_vline(xintercept = md, colour = .cwc_col("primary"), linewidth = .6) +
      ggplot2::annotate("label", x = md, y = Inf, vjust = 1.4, label = paste(toupper(label), .cwa_num(md, 0)),
                        family = .cwc_mono, size = 2.1, colour = W, fill = .cwc_col("ink"), label.size = 0, label.r = grid::unit(5, "pt"))
  } else {
    d <- data; d$.lo <- d[[x]] < md
    p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], fill = .data$.lo)) +
      ggplot2::geom_histogram(bins = bins, colour = W, linewidth = .3, boundary = md, show.legend = FALSE) +
      ggplot2::scale_fill_manual(values = c(`TRUE` = .cwc_col("primary"), `FALSE` = .cwc_slate(5)))
    if (!is.null(note)) p <- p + ggplot2::annotate("text", x = md, y = Inf, vjust = 2, hjust = -.08, label = note,
                                                   family = "Cormorant Garamond", fontface = "italic", size = 3.6, colour = .cwc_col("ink"))
  }
  p + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Spread by Group
#'
#' `style = "box"` (default): every observation as a faint dot and a hairline
#' box over them, the focus box in orange; `"violin"`: the shape of each
#' distribution in pale slate (the focus in a pale orange) with the median dot.
#'
#' @param data A data frame.
#' @param group,value Column names (strings).
#' @param focus The group in orange; default none.
#' @param style `"box"` or `"violin"`.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' p <- chanwe_spread(mtcars, "cyl", "mpg")
chanwe_spread <- function(data, group, value, focus = NULL, style = c("box", "violin"), theme = theme_chanwe(grid = "x")) {
  style <- match.arg(style)
  d <- data
  d[[group]] <- factor(d[[group]])
  d$.f <- if (is.null(focus)) FALSE else as.character(d[[group]]) == focus
  P <- .cwc_col("primary"); INK <- .cwc_col("ink")
  p <- ggplot2::ggplot(d, ggplot2::aes(.data[[value]], .data[[group]]))
  if (style == "box") {
    p <- p + ggplot2::geom_jitter(height = .18, width = 0, colour = .cwc_slate(5), size = .7) +
      ggplot2::geom_boxplot(ggplot2::aes(colour = .data$.f), fill = NA, width = .45, outliers = FALSE, linewidth = .45, show.legend = FALSE) +
      ggplot2::scale_colour_manual(values = c(`TRUE` = P, `FALSE` = INK))
  } else {
    md <- stats::aggregate(d[[value]], list(g = d[[group]]), stats::median)
    names(md)[2] <- value; names(md)[1] <- group
    md$.f <- if (is.null(focus)) FALSE else as.character(md[[group]]) == focus
    p <- p + ggplot2::geom_violin(ggplot2::aes(fill = .data$.f), colour = NA, scale = "width", width = .8, show.legend = FALSE) +
      ggplot2::geom_point(data = md, ggplot2::aes(colour = .data$.f), size = 2.4, show.legend = FALSE) +
      ggplot2::scale_fill_manual(values = c(`TRUE` = .cwc_pastel("primary", .55), `FALSE` = .cwc_slate(5))) +
      ggplot2::scale_colour_manual(values = c(`TRUE` = P, `FALSE` = INK))
  }
  p + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Ranking Over Time
#'
#' A bump chart: rank lines in pale slate, the focus in orange, ringed dots, the
#' names at the end in slate.
#'
#' @param data A data frame in long form.
#' @param time,group,rank Column names (strings); rank 1 is the top.
#' @param focus The group in orange.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(t = rep(1:3, 2), g = rep(c("A", "B"), each = 3), r = c(1, 2, 2, 2, 1, 1))
#' p <- chanwe_bump(d, "t", "g", "r", focus = "A")
chanwe_bump <- function(data, time, group, rank, focus, theme = theme_chanwe(grid = "none")) {
  d <- data; d$.f <- as.character(d[[group]]) == focus
  last <- d[d[[time]] == max(d[[time]]), ]
  ggplot2::ggplot(d, ggplot2::aes(.data[[time]], .data[[rank]], group = .data[[group]], colour = .data$.f)) +
    ggplot2::geom_line(linewidth = .8, show.legend = FALSE) + ggplot2::geom_point(size = 3.2, show.legend = FALSE) +
    ggplot2::geom_point(colour = .cwc_col("pure-white"), size = 1.1) +
    .cwc_label(data = last, ggplot2::aes(label = toupper(.data[[group]])), hjust = -.25) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("primary"), `FALSE` = .cwc_slate(5))) +
    ggplot2::scale_y_reverse(breaks = sort(unique(d[[rank]]))) +
    ggplot2::scale_x_continuous(breaks = sort(unique(d[[time]])), expand = ggplot2::expansion(c(.03, .18))) +
    ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Small Multiples
#'
#' One panel per unit: its line in orange over every other unit's in pale
#' slate.
#'
#' @param data A data frame in long form.
#' @param x,y,group Column names (strings).
#' @param ncol Panels per row.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(t = rep(1:5, 2), v = c(1:5, 5:1), g = rep(c("A", "B"), each = 5))
#' p <- chanwe_multiples(d, "t", "v", "g")
chanwe_multiples <- function(data, x, y, group, ncol = 3, theme = theme_chanwe(grid = "y")) {
  units <- unique(as.character(data[[group]]))
  ghost <- do.call(rbind, lapply(units, function(u) { g <- data; g$.panel <- u; g }))
  d <- data; d$.panel <- as.character(d[[group]])
  ghost$.panel <- factor(ghost$.panel, units); d$.panel <- factor(d$.panel, units)
  ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data[[y]])) +
    ggplot2::geom_line(data = ghost, ggplot2::aes(group = .data[[group]]), colour = .cwc_slate(5), linewidth = .3) +
    ggplot2::geom_line(colour = .cwc_col("primary"), linewidth = .7) +
    ggplot2::facet_wrap(ggplot2::vars(.data$.panel), ncol = ncol) + theme +
    ggplot2::theme(strip.text = ggplot2::element_text(family = .cwc_mono, size = 6, colour = .cwc_quiet(), hjust = 0)) +
    ggplot2::labs(x = NULL, y = NULL)
}

#' Progress Against a Target
#'
#' A bullet per goal: a slate track to 100, the actual as a bar (green when it
#' meets the target, orange when not), the target as an ink tick, and the
#' actual over the target in mono.
#'
#' @param data A data frame.
#' @param k,actual,target Column names (strings); values in percent of the goal.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(k = c("Ventas", "Margen"), a = c(82, 64), t = c(90, 60))
#' p <- chanwe_bullet(d, "k", "a", "t")
chanwe_bullet <- function(data, k, actual, target, theme = theme_chanwe(grid = "none")) {
  d <- data; d[[k]] <- factor(d[[k]], rev(unique(d[[k]]))); d$.ok <- d[[actual]] >= d[[target]]
  ggplot2::ggplot(d, ggplot2::aes(y = .data[[k]])) +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = 100, yend = .data[[k]]), colour = .cwc_col("surface-slate"), linewidth = 6) +
    ggplot2::geom_segment(ggplot2::aes(x = 0, xend = .data[[actual]], yend = .data[[k]], colour = .data$.ok),
                          linewidth = 2.6, lineend = "round", show.legend = FALSE) +
    ggplot2::geom_segment(ggplot2::aes(x = .data[[target]], xend = .data[[target]], y = as.numeric(.data[[k]]) - .28,
                                       yend = as.numeric(.data[[k]]) + .28), colour = .cwc_col("ink"), linewidth = .7) +
    .cwc_label(ggplot2::aes(x = 103, label = paste0(.cwa_num(.data[[actual]], 0), " / ", .cwa_num(.data[[target]], 0))), hjust = 0) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = .cwc_col("kpi-green"), `FALSE` = .cwc_col("primary"))) +
    ggplot2::scale_x_continuous(limits = c(0, 118), breaks = c(0, 50, 100)) + theme + ggplot2::labs(x = NULL, y = NULL)
}

# A squarified treemap layout (Bruls, Huizing and van Wijk), no dependency.
.cwc_treemap <- function(values, x = 0, y = 0, w = 1, h = 1) {
  v <- values / sum(values) * w * h
  out <- matrix(0, length(v), 4); idx <- seq_along(v)
  worst <- function(r, side) { s <- sum(r); max(side^2 * max(r) / s^2, s^2 / (side^2 * min(r))) }
  while (length(idx)) {
    side <- min(w, h); row <- idx[1]
    while (length(row) < length(idx) && worst(v[c(row, idx[length(row) + 1])], side) <= worst(v[row], side)) row <- idx[seq_len(length(row) + 1)]
    s <- sum(v[row])
    if (w >= h) { cw <- s / h; yy <- y; for (i in row) { hh <- v[i] / cw; out[i, ] <- c(x, yy, cw, hh); yy <- yy + hh }; x <- x + cw; w <- w - cw }
    else { ch <- s / w; xx <- x; for (i in row) { ww <- v[i] / ch; out[i, ] <- c(xx, y, ww, ch); xx <- xx + ww }; y <- y + ch; h <- h - ch }
    idx <- setdiff(idx, row)
  }
  out
}

#' Part of a Whole
#'
#' A single split at one moment. `style = "bar"` (default): one stacked bar,
#' each part labelled inside; `"donut"`: a thin ring with the focus share in
#' the centre; `"waffle"`: a hundred squares; `"treemap"`: rectangles sized by
#' share. The focus part is orange, the rest on the slate ramp.
#'
#' @param data A data frame, one row per part.
#' @param k,value Column names (strings).
#' @param focus The part in orange; default the largest.
#' @param style `"bar"`, `"donut"`, `"waffle"` or `"treemap"`.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(k = c("A", "B", "C"), v = c(50, 30, 20))
#' p <- chanwe_whole(d, "k", "v")
chanwe_whole <- function(data, k, value, focus = NULL, style = c("bar", "donut", "waffle", "treemap"),
                         theme = theme_chanwe(grid = "none")) {
  style <- match.arg(style)
  d <- data[order(-data[[value]]), , drop = FALSE]
  d$.sh <- d[[value]] / sum(d[[value]]) * 100
  focus <- focus %||_% as.character(d[[k]])[[1]]
  lv <- c(focus, setdiff(as.character(d[[k]]), focus))
  d[[k]] <- factor(d[[k]], lv); d <- d[order(d[[k]]), ]
  ramp <- c(.cwc_slate(2), .cwc_slate(3), .cwc_slate(4), .cwc_slate(5), .cwc_col("surface-slate"))
  cols <- stats::setNames(c(.cwc_col("primary"), rep(ramp, length.out = length(lv) - 1)), lv)
  on_dark <- stats::setNames(c(TRUE, seq_along(lv[-1]) <= 2), lv)
  txt <- function(g) ifelse(on_dark[as.character(g)], .cwc_col("pure-white"), .cwc_col("ink"))
  lab <- function(g, s) paste(toupper(g), paste0(.cwa_num(s, 0), " %"))
  blank <- ggplot2::theme(axis.text = ggplot2::element_blank(), axis.text.x = ggplot2::element_blank(),
                          axis.text.y = ggplot2::element_blank(), panel.grid = ggplot2::element_blank())
  W <- .cwc_col("pure-white")
  if (style == "bar") {
    d$.top <- cumsum(d$.sh); d$.mid <- d$.top - d$.sh / 2
    return(ggplot2::ggplot(d) + ggplot2::geom_rect(ggplot2::aes(xmin = .data$.top - .data$.sh, xmax = .data$.top, ymin = 0, ymax = 1,
                                                               fill = .data[[k]]), colour = W, linewidth = 1, show.legend = FALSE) +
      # Parts under 12 % are too narrow for their name: it goes under the bar,
      # alternating two rows so neighbours do not collide.
      ggplot2::geom_text(data = d[d$.sh >= 12, ], ggplot2::aes(.data$.mid, .5, label = lab(.data[[k]], .data$.sh)),
                         colour = txt(d[d$.sh >= 12, k]), family = .cwc_mono, size = 2.1) +
      ggplot2::geom_text(data = transform(d[d$.sh < 12, ], .row = -.25 - .3 * ((seq_len(sum(d$.sh < 12)) - 1) %% 2)),
                         ggplot2::aes(.data$.mid, .data$.row, label = lab(.data[[k]], .data$.sh)),
                         colour = .cwc_quiet(), family = .cwc_mono, size = 2.1) +
      ggplot2::scale_fill_manual(values = cols) + ggplot2::scale_y_continuous(limits = c(-1.2, 2.2)) + theme + blank +
      ggplot2::labs(x = NULL, y = NULL))
  }
  if (style == "donut") {
    d$.top <- cumsum(d$.sh)
    return(ggplot2::ggplot(d) + ggplot2::geom_rect(ggplot2::aes(xmin = 3, xmax = 4, ymin = .data$.top - .data$.sh, ymax = .data$.top,
                                                               fill = .data[[k]]), colour = W, linewidth = 1, show.legend = FALSE) +
      ggplot2::annotate("text", x = 0, y = 0, label = paste0(.cwa_num(d$.sh[1], 0), " %"), family = "Schibsted Grotesk",
                        fontface = "bold", size = 9, colour = .cwc_col("ink")) +
      ggplot2::annotate("text", x = 0, y = 0, vjust = 3.3, label = toupper(lv[1]), family = .cwc_mono, size = 2.2, colour = .cwc_quiet()) +
      .cwc_label(ggplot2::aes(x = 4.55, y = .data$.top - .data$.sh / 2, label = lab(.data[[k]], .data$.sh))) +
      ggplot2::scale_fill_manual(values = cols) + ggplot2::coord_polar(theta = "y") + ggplot2::xlim(0, 4.9) + theme + blank +
      ggplot2::labs(x = NULL, y = NULL))
  }
  if (style == "waffle") {
    n <- round(d$.sh); n[1] <- n[1] + (100 - sum(n))
    g <- expand.grid(x = 1:10, y = 1:10); g$k <- factor(rep(lv, n), lv)
    return(ggplot2::ggplot(g, ggplot2::aes(.data$x, .data$y, fill = .data$k)) +
      ggplot2::geom_point(shape = 22, size = 6.2, colour = W, stroke = .4) +
      ggplot2::scale_fill_manual(values = cols, name = NULL) + ggplot2::coord_equal() + theme + blank + ggplot2::labs(x = NULL, y = NULL))
  }
  r <- .cwc_treemap(d$.sh, w = 1.6, h = 1)
  d$x0 <- r[, 1]; d$y0 <- r[, 2]; d$x1 <- r[, 1] + r[, 3]; d$y1 <- r[, 2] + r[, 4]
  ggplot2::ggplot(d) + ggplot2::geom_rect(ggplot2::aes(xmin = .data$x0, xmax = .data$x1, ymin = .data$y0, ymax = .data$y1, fill = .data[[k]]),
                                          colour = W, linewidth = 1.2, show.legend = FALSE) +
    ggplot2::geom_text(ggplot2::aes(.data$x0 + .02, .data$y1 - .03, label = toupper(.data[[k]])), hjust = 0, vjust = 1,
                       colour = txt(d[[k]]), family = .cwc_mono, size = 2.1) +
    ggplot2::geom_text(ggplot2::aes(.data$x0 + .02, .data$y1 - .09, label = paste0(.cwa_num(.data$.sh, 0), " %")), hjust = 0, vjust = 1,
                       colour = txt(d[[k]]), family = "Schibsted Grotesk", fontface = "bold", size = 4.2) +
    ggplot2::scale_fill_manual(values = cols) + ggplot2::coord_equal(expand = FALSE) + theme + blank + ggplot2::labs(x = NULL, y = NULL)
}

#' Forecast
#'
#' History and a projection with its uncertainty. `style = "fan"` (default):
#' the history in ink and the projection in orange inside nested pastel bands,
#' named at the end; `"zone"`: the projection period on the slate tint, marked,
#' the line continuing dotted over a shaded range.
#'
#' @param data A data frame with one row per period.
#' @param x,y Column names (strings).
#' @param from The first projected `x` (rows from it on are the projection).
#' @param spread Column name of the half-width of the 90 % range in the
#'   projection (the bands at 50 % and 75 % are its 0.33 and 0.66).
#' @param style `"fan"` or `"zone"`.
#' @param label The zone's label.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(t = 1:12, v = c(5:1, rep(1, 7)), s = c(rep(0, 6), 1:6 / 3))
#' p <- chanwe_forecast(d, "t", "v", from = 6, spread = "s")
chanwe_forecast <- function(data, x, y, from, spread, style = c("fan", "zone"), label = "Proyección",
                            theme = theme_chanwe()) {
  style <- match.arg(style)
  d <- data[order(data[[x]]), , drop = FALSE]
  hist <- d[d[[x]] <= from, , drop = FALSE]
  fut <- d[d[[x]] >= from, , drop = FALSE]
  P <- .cwc_col("primary"); INK <- .cwc_col("ink")
  p <- ggplot2::ggplot(d, ggplot2::aes(.data[[x]], .data[[y]]))
  if (style == "fan") {
    bands <- do.call(rbind, lapply(c(1, .66, .33), function(m) data.frame(x = fut[[x]], lo = fut[[y]] - fut[[spread]] * m,
                                                                          hi = fut[[y]] + fut[[spread]] * m, m = m)))
    alpha <- c(`1` = .08, `0.66` = .16, `0.33` = .28)
    for (m in c(1, .66, .33)) {
      b <- bands[bands$m == m, ]
      p <- p + ggplot2::geom_ribbon(data = b, ggplot2::aes(x = .data$x, ymin = .data$lo, ymax = .data$hi), inherit.aes = FALSE,
                                    fill = grDevices::adjustcolor(P, alpha[[as.character(m)]]))
    }
    last <- fut[nrow(fut), ]
    p <- p + ggplot2::geom_line(data = hist, colour = INK, linewidth = .65) + ggplot2::geom_line(data = fut, colour = P, linewidth = .7) +
      .cwc_label(data = data.frame(x = last[[x]], y = c(last[[y]] + last[[spread]], last[[y]] + last[[spread]] * .33), l = c("90 %", "50 %")),
                 ggplot2::aes(.data$x, .data$y, label = .data$l), hjust = -.2, inherit.aes = FALSE)
  } else {
    # The range is a shaded band, not dotted lines (Ale, 2026-11-19).
    p <- p + ggplot2::annotate("rect", xmin = from, xmax = max(d[[x]]), ymin = -Inf, ymax = Inf, fill = .cwc_col("surface-slate")) +
      ggplot2::geom_ribbon(data = fut, ggplot2::aes(ymin = .data[[y]] - .data[[spread]], ymax = .data[[y]] + .data[[spread]]),
                           fill = grDevices::adjustcolor(.cwc_slate(4), .35)) +
      ggplot2::annotate("text", x = from, y = Inf, vjust = 1.8, hjust = -.08, label = toupper(label), family = .cwc_mono, size = 2.1,
                        colour = .cwc_quiet()) +
      ggplot2::geom_line(data = hist, colour = P, linewidth = .7) +
      ggplot2::geom_line(data = fut, colour = P, linewidth = .7, linetype = "22")
  }
  xs <- if (inherits(d[[x]], "Date")) ggplot2::scale_x_date(labels = label_chanwe_month(), expand = ggplot2::expansion(c(.01, .1)))
        else ggplot2::scale_x_continuous(expand = ggplot2::expansion(c(.01, .1)))
  p + xs + ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::labs(x = NULL, y = NULL)
}

#' Level and Change
#'
#' A level per period and its change, never on a second axis. `style =
#' "change"` (default): the change as green and red lollipops from zero, the
#' level printed on each; `"panels"`: the level as an orange line on top and the
#' change as pastel bars underneath; `"strip"`: the level as slate bars (the
#' latest in orange) and the change as a row of signed figures under the axis.
#'
#' @param data A data frame with one row per period.
#' @param x,level Column names (strings); the change is computed (percent).
#' @param style `"change"`, `"panels"` or `"strip"`.
#' @param level_name,change_name The two measures' names, for the panels.
#' @param digits Decimals of the change.
#' @param theme The theme.
#' @return A ggplot.
#' @export
#' @examples
#' d <- data.frame(y = 2020:2025, v = c(700, 640, 760, 880, 870, 960))
#' p <- chanwe_level_change(d, "y", "v")
chanwe_level_change <- function(data, x, level, style = c("change", "panels", "strip"), level_name = "Nivel",
                                change_name = "Variación, %", digits = 1, theme = theme_chanwe(grid = "y")) {
  style <- match.arg(style)
  d <- data[order(data[[x]]), , drop = FALSE]
  d$.chg <- c(NA, diff(d[[level]]) / utils::head(d[[level]], -1) * 100)
  d$.x <- factor(d[[x]])
  G <- .cwc_col("kpi-green"); R <- .cwc_col("kpi-red"); W <- .cwc_col("pure-white")
  if (style == "change") {
    c1 <- d[!is.na(d$.chg), ]
    return(ggplot2::ggplot(c1, ggplot2::aes(.data$.x, .data$.chg)) +
      ggplot2::geom_hline(yintercept = 0, colour = .cwc_col("rule"), linewidth = .4) +
      ggplot2::geom_segment(ggplot2::aes(xend = .data$.x, y = 0, yend = .data$.chg, colour = .data$.chg > 0), linewidth = .6, show.legend = FALSE) +
      ggplot2::geom_point(ggplot2::aes(colour = .data$.chg > 0), size = 2.6, show.legend = FALSE) +
      ggplot2::geom_text(ggplot2::aes(y = .data$.chg, label = .cwa_num(.data[[level]], 0), vjust = ifelse(.data$.chg > 0, -1.1, 2)),
                         family = .cwc_mono, size = 2.1, colour = .cwc_quiet()) +
      ggplot2::scale_colour_manual(values = c(`TRUE` = G, `FALSE` = R)) +
      ggplot2::scale_y_continuous(expand = ggplot2::expansion(.15)) + theme + ggplot2::labs(x = NULL, y = NULL))
  }
  if (style == "panels") {
    two <- rbind(data.frame(x = d$.x, v = d[[level]], panel = level_name, kind = "lvl"),
                 data.frame(x = d$.x, v = d$.chg, panel = change_name, kind = ifelse(is.na(d$.chg), "na", ifelse(d$.chg > 0, "up", "down"))))
    two$panel <- factor(two$panel, c(level_name, change_name))
    return(ggplot2::ggplot(two, ggplot2::aes(.data$x, .data$v)) +
      ggplot2::geom_line(data = two[two$kind == "lvl", ], ggplot2::aes(group = 1), colour = .cwc_col("primary"), linewidth = .7) +
      ggplot2::geom_point(data = two[two$kind == "lvl", ], colour = .cwc_col("primary"), size = 1.4) +
      ggplot2::geom_col(data = two[two$kind %in% c("up", "down"), ], ggplot2::aes(fill = .data$kind), width = .55, show.legend = FALSE) +
      ggplot2::scale_fill_manual(values = c(up = .cwc_pastel("kpi-green", .35), down = .cwc_pastel("kpi-red", .35))) +
      ggplot2::facet_grid(rows = ggplot2::vars(.data$panel), scales = "free_y", switch = "y") + theme +
      ggplot2::theme(strip.text.y.left = ggplot2::element_text(family = .cwc_mono, size = 5.5, colour = .cwc_quiet(), angle = 0, hjust = 1),
                     strip.placement = "outside") + ggplot2::labs(x = NULL, y = NULL))
  }
  off <- -max(d[[level]], na.rm = TRUE) * .08
  ggplot2::ggplot(d, ggplot2::aes(.data$.x, .data[[level]])) +
    geom_chanwe_col(ggplot2::aes(fill = .data$.x == utils::tail(levels(d$.x), 1)), width = .58, show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = .cwc_col("primary"), `FALSE` = .cwc_slate(4))) +
    ggplot2::geom_text(ggplot2::aes(y = off, label = ifelse(is.na(.data$.chg), "", .cwc_signed(.data$.chg, digits)),
                                    colour = !is.na(.data$.chg) & .data$.chg > 0), family = .cwc_mono, size = 2.2, show.legend = FALSE) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = G, `FALSE` = R)) +
    ggplot2::coord_cartesian(clip = "off") + theme + ggplot2::labs(x = NULL, y = NULL)
}
