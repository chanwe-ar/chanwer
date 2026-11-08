# The editorial layer (chanwer 3.2.0): annotations that make a chart argue,
# from the independent review of 2026-11-08. Each returns a list of ggplot
# layers, so it adds with `+`.

.cwa_num <- function(v, digits = 1) formatC(v, format = "f", digits = digits, decimal.mark = ",")

#' Mark the Main Series, Bar or Point
#'
#' The `main` option of the Chanwe chart grammar: the mark that matters gets
#' the accent, a halo and its value in an ink pill (or plain orange text with
#' `chip = FALSE`). Use it on the last point of the main line, on the main bar
#' of a ranking, on the main point of a scatter.
#'
#' @param x,y Where the mark is (data coordinates).
#' @param label The value to show. `NULL` shows nothing but the halo.
#' @param chip `TRUE` for the ink pill, `FALSE` for plain orange mono text.
#' @param hjust,vjust Where the label sits relative to the mark.
#' @param size The label's text size (mm, as in [ggplot2::geom_text()]).
#' @return A list of ggplot layers.
#' @export
#' @examples
#' last <- tail(economics, 1)
#' ggplot2::ggplot(economics, ggplot2::aes(date, unemploy)) +
#'   ggplot2::geom_line() +
#'   annotate_chanwe_main(last$date, last$unemploy, label = format(last$unemploy, big.mark = "."))
annotate_chanwe_main <- function(x, y, label = NULL, chip = TRUE, hjust = -0.2, vjust = 0.5, size = 2.6) {
  P <- chanwe_get_colors()[["primary"]]; INK <- chanwe_get_colors()[["ink"]]
  d <- data.frame(x = x, y = y)
  layers <- list(
    ggplot2::geom_point(data = d, ggplot2::aes(x, y), inherit.aes = FALSE, colour = P, size = 3.4, alpha = .18),
    ggplot2::geom_point(data = d, ggplot2::aes(x, y), inherit.aes = FALSE, colour = P, size = 1.4)
  )
  if (!is.null(label)) {
    d$label <- label
    layers <- c(layers, list(if (chip) {
      ggplot2::geom_label(data = d, ggplot2::aes(x, y, label = label), inherit.aes = FALSE,
                          family = "JetBrains Mono", size = size, fill = INK, colour = "white", hjust = hjust, vjust = vjust,
                          label.r = grid::unit(4, "pt"), label.padding = grid::unit(2.3, "pt"))
    } else {
      ggplot2::geom_text(data = d, ggplot2::aes(x, y, label = label), inherit.aes = FALSE,
                         family = "JetBrains Mono", size = size, colour = P, hjust = hjust, vjust = vjust)
    }))
  }
  layers
}

#' Label Series at Their End
#'
#' Direct labels: each series named, with its last value, at the end of its
#' line and in its colour, so the chart needs no legend.
#'
#' @param data The data the lines are drawn from.
#' @param x,y,group Column names (strings).
#' @param values Show the last value after the name. Default `TRUE`.
#' @param nudge How far past the last point, in x units (days for dates).
#' @param size Text size (mm).
#' @param upper Names in capitals, as mono labels. Default `TRUE`.
#' @return A list of ggplot layers. Widen the x scale's right expansion
#'   (about 0.2) so the labels fit.
#' @export
annotate_chanwe_ends <- function(data, x, y, group, values = TRUE, nudge = NULL, size = 2.6, upper = TRUE) {
  ends <- do.call(rbind, lapply(split(data, data[[group]]), function(g) g[which.max(g[[x]]), , drop = FALSE]))
  nm <- as.character(ends[[group]]); if (upper) nm <- toupper(nm)
  ends$.label <- if (values) paste0(nm, "  ", .cwa_num(ends[[y]])) else nm
  if (is.null(nudge)) nudge <- if (inherits(data[[x]], "Date")) 14 else diff(range(data[[x]])) * .02
  list(
    ggplot2::geom_point(data = ends, ggplot2::aes(.data[[x]], .data[[y]], colour = .data[[group]]), inherit.aes = FALSE, size = 1.2),
    ggplot2::geom_text(data = ends, ggplot2::aes(.data[[x]], .data[[y]], colour = .data[[group]], label = .data$.label),
                       inherit.aes = FALSE, hjust = 0, nudge_x = nudge, family = "JetBrains Mono", size = size)
  )
}

#' Shade the Gap Between Two Series
#'
#' Fills the space between two lines with the slate tint and names it, so the
#' chart shows the relationship the reader is meant to see (the gap between
#' gross and net reserves, between a target and the actual).
#'
#' @param data A data frame with one row per x.
#' @param x,ymin,ymax Column names (strings).
#' @param label The gap's name. The value at the last x is appended.
#' @param at Where to place the label: an x value. Default: two thirds along.
#' @param size Text size (mm).
#' @return A list of ggplot layers. Add it before the lines.
#' @export
annotate_chanwe_gap <- function(data, x, ymin, ymax, label = "Brecha", at = NULL, size = 2.3) {
  tint <- chanwe_get_colors()[["surface-slate"]]
  mu <- chanwe_get_colors()[["fg-muted"]]
  n <- nrow(data)
  i <- if (is.null(at)) max(1, round(n * 2 / 3)) else which.min(abs(as.numeric(data[[x]]) - as.numeric(at)))
  last_gap <- data[[ymax]][n] - data[[ymin]][n]
  lab <- data.frame(x = data[[x]][i], y = (data[[ymin]][i] + data[[ymax]][i]) / 2,
                    label = toupper(paste(label, .cwa_num(last_gap))))
  list(
    ggplot2::geom_ribbon(data = data, ggplot2::aes(.data[[x]], ymin = .data[[ymin]], ymax = .data[[ymax]]),
                         inherit.aes = FALSE, fill = tint),
    ggplot2::geom_text(data = lab, ggplot2::aes(x, y, label = label), inherit.aes = FALSE,
                       family = "JetBrains Mono", size = size, colour = mu)
  )
}

#' Annotate a Point with a Note
#'
#' One sentence in the editorial italic (Cormorant Garamond), joined to the
#' data point by a hairline leader. One or two per chart.
#'
#' @param x,y The point.
#' @param label The note (`"Acuerdo FMI, abr-25"`).
#' @param dx,dy Where the note sits, as an offset from the point in data units
#'   (days for dates).
#' @param size Text size (mm).
#' @return A list of ggplot layers.
#' @export
annotate_chanwe_note <- function(x, y, label, dx, dy, size = 3.6) {
  INK <- chanwe_get_colors()[["ink"]]; MU <- chanwe_get_colors()[["fg-muted"]]
  hj <- if (as.numeric(dx) < 0) 1 else 0
  list(
    ggplot2::annotate("segment", x = x, xend = x + dx, y = y, yend = y + dy, colour = INK, linewidth = .2),
    ggplot2::annotate("point", x = x, y = y, size = .9, colour = INK),
    ggplot2::annotate("text", x = x + dx * 1.04, y = y + dy * 1.05, label = label, hjust = hj,
                      family = "Cormorant Garamond", fontface = "italic", size = size, colour = MU)
  )
}

#' Mark a Reference Value on a Ranking
#'
#' For horizontal bars: a dashed guide behind the bars at a reference value
#' (the regional median, the average), with an orange marker and its label
#' above the first bar.
#'
#' @param value The reference value.
#' @param label Its name (`"Mediana"`). The value is appended.
#' @param n_bars The number of bars (the marker sits above the top one).
#' @param size Text size (mm).
#' @return A list of ggplot layers. Add it before the bars, and give the y
#'   scale room at the top: `scale_y_discrete(expand = expansion(add = c(.6, 1)))`.
#' @export
annotate_chanwe_reference <- function(value, label = "Mediana", n_bars, size = 2.3) {
  P <- chanwe_get_colors()[["primary"]]; COOL <- chanwe_get_colors()[["rule-cool"]]
  list(
    ggplot2::geom_vline(xintercept = value, colour = COOL, linewidth = .25, linetype = "22"),
    ggplot2::annotate("segment", x = value, xend = value, y = n_bars + .42, yend = n_bars + .82, colour = P, linewidth = .6),
    ggplot2::annotate("text", x = value, y = n_bars + .66, label = paste0("  ", toupper(label), " ", .cwa_num(value)),
                      hjust = 0, family = "JetBrains Mono", size = size, colour = P)
  )
}

#' Month Labels in Spanish (or English)
#'
#' A labeller for `scale_x_date(labels = )`: `ene-24`, `jun-25`; or just the
#' month (`ene`) with `year = FALSE`. Charts in a Spanish document use it.
#'
#' @param lang `"es"` or `"en"`.
#' @param year Append the two-digit year. Default `TRUE`.
#' @return A function of dates returning labels.
#' @export
#' @examples
#' label_chanwe_month()(as.Date(c("2024-06-01", "2025-12-01")))
label_chanwe_month <- function(lang = c("es", "en"), year = TRUE) {
  lang <- match.arg(lang)
  m <- if (lang == "es") c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
       else c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec")
  function(x) {
    out <- m[as.integer(format(x, "%m"))]
    if (year) out <- paste0(out, "-", format(x, "%y"))
    out[is.na(x)] <- NA
    out
  }
}
