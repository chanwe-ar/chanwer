# Series over time on a period axis (chanwer 3.6.0, 2026-11-27). Written for Radar Macro's report figures (Radar
# Task 243: every report chart is drawn by chanwer) and general: any long data frame of dated values. A day, month,
# quarter, half-year or year axis; lines, bars and areas in one chart; a second axis; stacking; a dotted forecast
# companion; events, reference levels and series breaks; numbers in Spanish as the web kit prints them.

# ── numbers ─────────────────────────────────────────────────────────────────

# The shortest decimal form of a non-negative double (the one JavaScript prints): 15 significant digits when they
# give the number back, else 16, else 17.
.cwn_shortest <- function(v) {
  for (d in 15:17) {
    s <- trimws(formatC(v, digits = d, format = "fg"))
    if (as.numeric(s) == v) break
  }
  s
}

# A decimal string rounded to `d` decimals, half away from zero (Intl's "halfExpand"): c(integer part, decimals).
.cwn_round <- function(s, d) {
  parts <- strsplit(s, ".", fixed = TRUE)[[1]]
  int <- parts[[1]]
  frac <- if (length(parts) > 1) parts[[2]] else ""
  if (nchar(frac) <= d) return(c(int, frac))
  up <- substr(frac, d + 1, d + 1) >= "5"
  digits <- as.integer(strsplit(paste0(int, substr(frac, 1, d)), "")[[1]])
  if (up) {
    i <- length(digits)
    repeat {
      if (i == 0) { digits <- c(1L, digits); break }
      if (digits[[i]] < 9L) { digits[[i]] <- digits[[i]] + 1L; break }
      digits[[i]] <- 0L
      i <- i - 1L
    }
  }
  all <- paste(digits, collapse = "")
  n_int <- nchar(all) - d
  c(substr(all, 1, n_int), if (d > 0) substr(all, n_int + 1, nchar(all)) else "")
}

.cwn_group <- function(int) {
  n <- nchar(int)
  if (n <= 3) return(int)
  first <- n %% 3
  chunks <- c(if (first > 0) substr(int, 1, first), substring(int, seq(first + 1, n, by = 3), seq(first + 3, n, by = 3)))
  paste(chunks, collapse = ".")
}

#' Numbers in Spanish
#'
#' Formats numbers the way Chanwe prints them, and exactly the way the web kit's formatter does
#' (`Intl.NumberFormat("es-AR", { maximumFractionDigits: 2 })`, `@chanwe-ar/ui/echart` `formatChartValue()`): a
#' decimal comma and a thousands dot (`1.234,5`), at most `max_digits` decimals with trailing zeros dropped (or
#' exactly `digits` decimals), rounded half away from zero on the number's shortest decimal form (`1,005` gives
#' `1,01`), a minus on a negative value even when it rounds to zero (`-0`, as the kit prints it), and a `suffix`
#' such as `" %"` (a space before the sign) or `" p.p."`.
#'
#' @param x A numeric vector.
#' @param digits Exactly this many decimals, or `NULL` (the default) for up to `max_digits`.
#' @param max_digits The most decimals when `digits` is `NULL`. Default 2, the kit's.
#' @param suffix Text after each number, e.g. `" %"`.
#' @param sign Print `+` before positive numbers.
#' @param missing What a missing or infinite value prints. Default `NA`.
#' @return A character vector.
#' @seealso [label_chanwe_number()] for scales.
#' @export
#' @examples
#' chanwe_format_number(c(1234.5, 33.44, -0.004, NA), suffix = " %")
#' chanwe_format_number(2.5, digits = 1, sign = TRUE, suffix = " p.p.")
chanwe_format_number <- function(x, digits = NULL, max_digits = 2, suffix = "", sign = FALSE, missing = NA_character_) {
  x <- as.numeric(x)
  d <- if (is.null(digits)) max_digits else digits
  vapply(x, function(v) {
    if (is.na(v) || !is.finite(v)) return(missing)
    neg <- v < 0 || (v == 0 && 1 / v < 0)
    r <- .cwn_round(.cwn_shortest(abs(v)), d)
    frac <- r[[2]]
    if (is.null(digits)) frac <- sub("0+$", "", frac) else frac <- formatC(frac, width = d, flag = "-")
    frac <- gsub(" ", "0", frac, fixed = TRUE)
    out <- .cwn_group(r[[1]])
    if (nzchar(frac)) out <- paste0(out, ",", frac)
    prefix <- if (neg) "-" else if (sign && v > 0) "+" else ""
    paste0(prefix, out, suffix)
  }, character(1), USE.NAMES = FALSE)
}

#' Spanish Number Labels for Scales
#'
#' A labeller for `scale_*_continuous(labels = )` that writes [chanwe_format_number()]: `1.234,5`, `25 %`.
#'
#' @inheritParams chanwe_format_number
#' @return A function of numbers returning labels.
#' @export
#' @examples
#' label_chanwe_number(suffix = " %")(c(0, 12.5, 1000))
label_chanwe_number <- function(digits = NULL, max_digits = 2, suffix = "", sign = FALSE) {
  force(digits); force(max_digits); force(suffix); force(sign)
  function(x) chanwe_format_number(x, digits = digits, max_digits = max_digits, suffix = suffix, sign = sign)
}

# ── periods ─────────────────────────────────────────────────────────────────

.cwp_frequencies <- c("M", "D", "Q", "S", "A")
.cwp_month_index <- function(x) as.integer(format(x, "%Y")) * 12L + as.integer(format(x, "%m")) - 1L
.cwp_from_index <- function(i) as.Date(sprintf("%04d-%02d-01", i %/% 12L, i %% 12L + 1L))
# The length of a period in days, for bar widths and padding.
.cwp_days <- function(frequency) c(D = 1, M = 30.4, Q = 91.3, S = 182.6, A = 365.25)[[frequency]]

#' The First Day of a Period
#'
#' Reads period labels as dates: a day (`2026-11-13`), a month (`2026-11`), a quarter (`2026-Q4`), a half-year
#' (`2026-S2`) or a year (`2026`), the way Radar Macro and its chart specs write them.
#'
#' @param period A character vector of periods.
#' @return A `Date` vector: each period's first day.
#' @export
#' @examples
#' chanwe_period_date(c("2026-11-13", "2026-11", "2026-Q4", "2026-S2", "2026"))
chanwe_period_date <- function(period) {
  p <- as.character(period)
  y <- substr(p, 1, 4)
  out <- rep(NA_character_, length(p))
  day <- grepl("^\\d{4}-\\d{2}-\\d{2}$", p)
  month <- grepl("^\\d{4}-\\d{2}$", p)
  quarter <- grepl("^\\d{4}-Q[1-4]$", p)
  half <- grepl("^\\d{4}-S[12]$", p)
  year <- grepl("^\\d{4}$", p)
  out[day] <- p[day]
  out[month] <- paste0(p[month], "-01")
  out[quarter] <- sprintf("%s-%02d-01", y[quarter], (as.integer(substr(p[quarter], 7, 7)) - 1L) * 3L + 1L)
  out[half] <- sprintf("%s-%02d-01", y[half], ifelse(substr(p[half], 7, 7) == "1", 1L, 7L))
  out[year] <- paste0(p[year], "-01-01")
  as.Date(out)
}

#' Breaks for a Period Axis
#'
#' Where a date axis of days, months, quarters, half-years or years carries its ticks: on the first day of a
#' period, at most `n` of them. A daily axis follows the web kit's rule (Radar's daily charts): a tick each month in
#' a window of up to a year, each quarter up to three years, each year beyond. The others take the smallest step of
#' whole periods (1, 2, 3 or 6 months; then whole years) that keeps `n` ticks or fewer, aligned on the calendar.
#'
#' @param frequency `"M"`, `"D"`, `"Q"`, `"S"` or `"A"`.
#' @param n The most ticks.
#' @return A function of the axis limits returning dates.
#' @export
#' @examples
#' breaks_chanwe_period("S")(as.Date(c("2021-07-01", "2026-01-01")))
breaks_chanwe_period <- function(frequency = c("M", "D", "Q", "S", "A"), n = 8) {
  frequency <- match.arg(frequency)
  force(n)
  function(limits) {
    limits <- as.Date(limits, origin = "1970-01-01")
    if (any(is.na(limits))) return(as.Date(character(0)))
    from <- .cwp_month_index(limits[[1]]) + (format(limits[[1]], "%d") != "01")
    to <- .cwp_month_index(limits[[2]])
    if (to < from) return(as.Date(character(0)))
    span <- to - from
    steps <- switch(frequency,
                    D = if (span <= 12) 1L else if (span <= 36) 3L else c(12L, 24L, 60L, 120L),
                    M = c(1L, 2L, 3L, 6L, 12L, 24L, 60L, 120L),
                    Q = c(3L, 6L, 12L, 24L, 60L, 120L),
                    S = c(6L, 12L, 24L, 60L, 120L),
                    A = c(12L, 24L, 60L, 120L, 240L))
    idx <- from:to
    for (step in steps) {
      keep <- if (step <= 12L) idx[idx %% step == 0L] else idx[idx %% 12L == 0L & (idx %/% 12L) %% (step %/% 12L) == 0L]
      if (length(keep) <= n || step == steps[[length(steps)]]) break
    }
    .cwp_from_index(keep)
  }
}

#' Labels for a Period Axis
#'
#' Labels the ticks of [breaks_chanwe_period()] in Spanish (or English): months as `jun-25`, quarters as `T2-25`
#' (`Q2-25`), half-years as `S1-25` (`H1-25`) and years as `2025`. Ticks a year or more apart read as years, whatever
#' the frequency.
#'
#' @inheritParams breaks_chanwe_period
#' @param lang `"es"` or `"en"`.
#' @return A function of dates returning labels.
#' @export
#' @examples
#' label_chanwe_period("Q")(as.Date(c("2025-04-01", "2025-07-01")))
label_chanwe_period <- function(frequency = c("M", "D", "Q", "S", "A"), lang = c("es", "en")) {
  frequency <- match.arg(frequency)
  lang <- match.arg(lang)
  month <- label_chanwe_month(lang)
  function(x) {
    out <- rep(NA_character_, length(x))
    ok <- !is.na(x)
    if (!any(ok)) return(out)
    v <- x[ok]
    gaps <- diff(sort(unique(.cwp_month_index(v))))
    yearly <- frequency == "A" || (length(gaps) > 0 && min(gaps) >= 12)
    yy <- format(v, "%y")
    m <- as.integer(format(v, "%m"))
    out[ok] <- if (yearly) format(v, "%Y") else switch(frequency,
      D = month(v), M = month(v),
      Q = paste0(if (lang == "es") "T" else "Q", (m - 1L) %/% 3L + 1L, "-", yy),
      S = paste0(if (lang == "es") "S" else "H", ifelse(m <= 6L, 1L, 2L), "-", yy))
    out
  }
}

#' A Period Axis
#'
#' A date scale for days, months, quarters, half-years or years: [breaks_chanwe_period()] and
#' [label_chanwe_period()] on [ggplot2::scale_x_date()].
#'
#' @inheritParams label_chanwe_period
#' @param limits The window, two dates, or `NULL` for the data's.
#' @param n The most ticks.
#' @param expand The axis' padding.
#' @param ... Passed to [ggplot2::scale_x_date()].
#' @return A ggplot2 scale.
#' @export
#' @examples
#' d <- data.frame(t = chanwe_period_date(paste0(2022:2026, "-S1")), v = c(40, 39, 42, 38, 32))
#' p <- ggplot2::ggplot(d, ggplot2::aes(t, v)) + ggplot2::geom_line() + scale_x_chanwe_period("S")
scale_x_chanwe_period <- function(frequency = c("M", "D", "Q", "S", "A"), limits = NULL, n = 8, lang = c("es", "en"),
                                  expand = ggplot2::expansion(mult = c(.01, .03)), ...) {
  frequency <- match.arg(frequency)
  lang <- match.arg(lang)
  # With a window the ticks fall inside it, not in the axis' padding.
  breaks <- breaks_chanwe_period(frequency, n)
  if (!is.null(limits)) breaks <- breaks(as.Date(limits))
  ggplot2::scale_x_date(breaks = breaks, labels = label_chanwe_period(frequency, lang),
                        limits = limits, expand = expand, ...)
}

# ── the annotation layer for time ──────────────────────────────────────────

#' Mark an Event on a Time Axis
#'
#' A dashed vertical rule in the body slate at a date, with its name as a mono label at the top: a devaluation, an
#' election, a change of regime.
#'
#' @param x The date (or x value).
#' @param label The event's name, or `NULL`.
#' @param size Text size (mm).
#' @return A list of ggplot layers.
#' @export
#' @examples
#' layers <- annotate_chanwe_event(as.Date("2023-12-13"), "Devaluación dic-23")
annotate_chanwe_event <- function(x, label = NULL, size = 2.1) {
  MU <- chanwe_get_colors()[["fg-muted"]]
  layers <- list(ggplot2::geom_vline(xintercept = x, colour = MU, linewidth = .3, linetype = "22"))
  if (!is.null(label) && nzchar(label)) {
    layers <- c(layers, list(ggplot2::annotate("text", x = x, y = Inf, label = toupper(label), hjust = -0.05, vjust = 1.6,
                                               family = .cwc_mono, size = size, colour = MU)))
  }
  layers
}

#' Mark a Reference Level
#'
#' A dashed horizontal rule at a value (a target, zero, a threshold), with its name as a mono label at the right.
#'
#' @param y The value.
#' @param label Its name, or `NULL`.
#' @param size Text size (mm).
#' @return A list of ggplot layers.
#' @export
#' @examples
#' layers <- annotate_chanwe_hline(0, "Sin cambio")
annotate_chanwe_hline <- function(y, label = NULL, size = 2.1) {
  COOL <- chanwe_get_colors()[["rule-cool"]]
  layers <- list(ggplot2::geom_hline(yintercept = y, colour = COOL, linewidth = .35, linetype = "22"))
  if (!is.null(label) && nzchar(label)) {
    layers <- c(layers, list(ggplot2::annotate("text", x = Inf, y = y, label = toupper(label), hjust = 1.02, vjust = -.6,
                                               family = .cwc_mono, size = size, colour = chanwe_get_colors()[["fg-muted"]])))
  }
  layers
}

#' Mark a Break in a Series
#'
#' A dotted vertical hairline where a series changes its method or coverage, named at the foot of the panel, so a
#' reader does not compare across it as if nothing changed.
#'
#' @param x The date (or x value) where the break starts.
#' @param label Its name. Default `"Ruptura"`.
#' @param size Text size (mm).
#' @return A list of ggplot layers.
#' @export
#' @examples
#' layers <- annotate_chanwe_break(as.Date("2024-12-01"), "Ruptura: monotributo social")
annotate_chanwe_break <- function(x, label = "Ruptura", size = 2.1) {
  COOL <- chanwe_get_colors()[["rule-cool"]]
  layers <- list(ggplot2::geom_vline(xintercept = x, colour = COOL, linewidth = .45, linetype = "11"))
  if (!is.null(label) && nzchar(label)) {
    layers <- c(layers, list(ggplot2::annotate("text", x = x, y = -Inf, label = toupper(label), hjust = -0.05, vjust = -.7,
                                               family = .cwc_mono, size = size, colour = chanwe_get_colors()[["fg-muted"]])))
  }
  layers
}

# ── the builder ─────────────────────────────────────────────────────────────

# The largest absolute height a side reaches: its values, and its stacked bars' sums by date.
.cwt_extent <- function(d, stacked) {
  if (!nrow(d)) return(NA_real_)
  v <- d$y[!is.na(d$y)]
  out <- if (length(v)) max(abs(v)) else 0
  if (stacked) {
    b <- d[d$mark == "bar" & !is.na(d$y), , drop = FALSE]
    if (nrow(b)) {
      pos <- tapply(pmax(b$y, 0), b$x, sum)
      neg <- tapply(pmin(b$y, 0), b$x, sum)
      out <- max(out, abs(pos), abs(neg))
    }
  }
  out
}

#' Series Over Time
#'
#' The Chanwe chart of dated series on a period axis (days, months, quarters, half-years or years): lines, bars and
#' areas in one chart, a second axis when two units must share it, stacked bars, a dotted forecast companion, events,
#' reference levels and series breaks. The focus series is orange and the rest sit on the slate ramp; the last value
#' of the focus series sits in the ink pill ([annotate_chanwe_main()]); names go in the legend (the figure frame's
#' pill) or at the end of each line. Numbers are Spanish ([label_chanwe_number()]).
#'
#' A second axis is aligned on zero: the right series are drawn scaled by one round factor (the ratio of the two
#' sides' largest absolute heights, rounded up to 1, 2, 2.5 or 5 times a power of ten) and the right axis reads them
#' back on the left axis' grid lines. The factor is the plot's `"chanwe_secondary"`
#' attribute (1 without a right side), so `y / factor` gives a right series' value back from the built plot.
#'
#' @param data A data frame in long form: one row per date and series.
#' @param x,y Column names (strings): the date (a `Date`, each period's first day; see [chanwe_period_date()]) and
#'   the value. Missing values break the line.
#' @param group Column name of the series, or `NULL` for one series. A factor's levels give the order.
#' @param focus The series in orange; default the first.
#' @param frequency The period: `"M"`, `"D"`, `"Q"`, `"S"` or `"A"` (axis ticks, labels and bar widths).
#' @param mark `"line"`, `"bar"` or `"area"`: one for all, or a vector named by series.
#' @param side `"left"` or `"right"`: one for all, or a vector named by series.
#' @param stacked Stack the bars (and the areas) of each side, the first series at the base.
#' @param forecast Column name of a logical: `TRUE` rows are a projection, drawn as a dotted companion of the same
#'   colour from the last observed point. `NULL` for none.
#' @param points Mark every point of the lines. Default: for half-years, whose few points must each be seen.
#' @param events A data frame with `x` (dates) and `label`: [annotate_chanwe_event()] for each.
#' @param references A data frame with `y`, `label` and optionally `side`: [annotate_chanwe_hline()] for each.
#' @param breaks A data frame with `x` and `label`: [annotate_chanwe_break()] for each.
#' @param labels `"legend"` (the names in a legend; the figure frame draws it as a pill), `"direct"` (each line named
#'   at its end with its last value) or `"none"`.
#' @param main Mark the focus series' last value with [annotate_chanwe_main()]. Default `TRUE`.
#' @param main_label That value's text; default `number_right` or `number` of it.
#' @param number,number_right The labellers of the left and right axes (and of the values printed on the chart).
#' @param limits The window, two dates; default the data's. The axis shows it (a bar at either end is drawn whole)
#'   and its ticks fall inside it.
#' @param lang `"es"` or `"en"`, for the period labels.
#' @param theme The theme; default [theme_chanwe()] without its pane, for [chanwe_figure()].
#' @return A ggplot.
#' @seealso [chanwe_lines()] for several series without a period axis, [chanwe_forecast()] for a projection with its
#'   range, [chanwe_figure()] for the frame.
#' @export
#' @examples
#' d <- data.frame(t = rep(chanwe_period_date(sprintf("2025-%02d", 1:12)), 2),
#'                 v = c(cumsum(rep(2.1, 12)), rep(c(-1, 2), 6)), s = rep(c("IPC", "EMAE"), each = 12))
#' p <- chanwe_timeseries(d, "t", "v", "s", mark = c(EMAE = "bar"), side = c(EMAE = "right"),
#'                        number = label_chanwe_number(suffix = " %"))
chanwe_timeseries <- function(data, x, y, group = NULL, focus = NULL, frequency = c("M", "D", "Q", "S", "A"),
                              mark = "line", side = "left", stacked = FALSE, forecast = NULL, points = NULL,
                              events = NULL, references = NULL, breaks = NULL, labels = c("legend", "direct", "none"),
                              main = TRUE, main_label = NULL, number = label_chanwe_number(), number_right = number,
                              limits = NULL, lang = c("es", "en"), theme = theme_chanwe(pane = FALSE)) {
  frequency <- match.arg(frequency)
  labels <- match.arg(labels)
  lang <- match.arg(lang)
  g <- if (is.null(group)) rep("Serie", nrow(data)) else data[[group]]
  lv <- if (is.factor(g)) levels(droplevels(g)) else unique(as.character(g))
  d <- data.frame(x = as.Date(data[[x]]), y = as.numeric(data[[y]]), g = factor(as.character(g), lv),
                  f = if (is.null(forecast)) FALSE else as.logical(data[[forecast]]))
  d$f[is.na(d$f)] <- FALSE
  per <- function(v, default, allowed) {
    out <- if (is.null(names(v))) stats::setNames(rep_len(v, length(lv)), lv) else {
      o <- stats::setNames(rep(default, length(lv)), lv)
      hit <- intersect(names(v), lv)
      o[hit] <- v[hit]
      o
    }
    bad <- setdiff(out, allowed)
    if (length(bad)) stop(sprintf("chanwe_timeseries(): %s is not one of %s", bad[[1]], paste(allowed, collapse = ", ")), call. = FALSE)
    out
  }
  marks <- per(mark, "line", c("line", "bar", "area"))
  sides <- per(side, "left", c("left", "right"))
  if (all(sides == "right")) sides[] <- "left"
  focus <- .cwc_focus(d$g, focus)
  cols <- chanwe_focus_colors(lv, focus)
  d$mark <- unname(marks[as.character(d$g)])
  d$side <- unname(sides[as.character(d$g)])

  # The right side is drawn scaled by k, zero on zero.
  k <- 1
  if (any(sides == "right")) {
    k <- .cwt_extent(d[d$side == "left", , drop = FALSE], stacked) / .cwt_extent(d[d$side == "right", , drop = FALSE], stacked)
    if (!is.finite(k) || k <= 0) k <- 1
    # A round factor (1, 2, 2.5 or 5 times a power of ten, the next one up), so the right axis' ticks, derived from
    # the left's, are round numbers on the same grid lines.
    e <- 10^floor(log10(k))
    k <- e * c(1, 2, 2.5, 5, 10)[which(c(1, 2, 2.5, 5, 10) * e >= k - 1e-9)[[1]]]
  }
  d$yp <- ifelse(d$side == "right", d$y * k, d$y)
  fmt <- function(v, s) if (identical(s, "right")) number_right(v) else number(v)

  days <- .cwp_days(frequency)
  width <- days * .62
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$x, .data$yp))

  # Behind the data: reference levels, breaks and events.
  for (i in seq_len(NROW(references))) {
    r <- references[i, , drop = FALSE]
    yy <- r$y * (if (!is.null(r$side) && identical(as.character(r$side), "right")) k else 1)
    p <- p + annotate_chanwe_hline(yy, if (is.null(r$label)) NULL else as.character(r$label))
  }
  for (i in seq_len(NROW(breaks))) p <- p + annotate_chanwe_break(as.Date(breaks$x[[i]]), as.character(breaks$label[[i]]))
  for (i in seq_len(NROW(events))) p <- p + annotate_chanwe_event(as.Date(events$x[[i]]), as.character(events$label[[i]]))

  # Areas: the line over a gradient of its own colour that fades to the axis (as chanwe_area()).
  for (s in lv[marks[lv] == "area"]) {
    a <- d[d$g == s & !d$f & !is.na(d$yp), , drop = FALSE]
    if (!nrow(a)) next
    grad <- grid::linearGradient(colours = c(grDevices::adjustcolor(cols[[s]], .26), grDevices::adjustcolor(cols[[s]], 0)),
                                 x1 = 0, y1 = 1, x2 = 0, y2 = 0)
    p <- p + ggplot2::geom_ribbon(data = a, ggplot2::aes(x = .data$x, ymin = 0, ymax = .data$yp), fill = grad,
                                  inherit.aes = FALSE, name = paste0("chanwe_area_", match(s, lv)))
  }

  # Bars, one layer per side: stacked from the first series up, side by side, or one series with rounded ends.
  for (sd in c("left", "right")) {
    b <- d[d$mark == "bar" & d$side == sd & !is.na(d$yp), , drop = FALSE]
    if (!nrow(b)) next
    nb <- length(unique(b$g))
    name <- paste0("chanwe_bars_", sd)
    p <- p + if (stacked && nb > 1) {
      ggplot2::geom_col(data = b, ggplot2::aes(fill = .data$g), width = width, colour = chanwe_get_colors()[["pure-white"]],
                        linewidth = .15, position = ggplot2::position_stack(reverse = TRUE), name = name)
    } else if (nb > 1) {
      ggplot2::geom_col(data = b, ggplot2::aes(fill = .data$g), width = width, position = ggplot2::position_dodge(width = width),
                        name = name)
    } else {
      geom_chanwe_col(data = b, ggplot2::aes(fill = .data$g), width = width, name = name)
    }
  }

  # Lines (and the lines over areas); a missing value breaks them.
  l <- d[d$mark %in% c("line", "area") & !d$f, , drop = FALSE]
  if (nrow(l)) {
    p <- p + ggplot2::geom_line(data = l, ggplot2::aes(colour = .data$g, group = .data$g), linewidth = .65,
                                lineend = "round", na.rm = TRUE, name = "chanwe_lines")
  }
  # The forecast: a dotted companion of the same colour, from the last observed point.
  fc <- d[d$mark %in% c("line", "area") & d$f & !is.na(d$yp), , drop = FALSE]
  if (nrow(fc)) {
    joined <- do.call(rbind, lapply(split(fc, fc$g, drop = TRUE), function(s) {
      obs <- l[l$g == s$g[[1]] & !is.na(l$yp) & l$x <= min(s$x), , drop = FALSE]
      rbind(if (nrow(obs)) obs[which.max(obs$x), , drop = FALSE], s)
    }))
    p <- p + ggplot2::geom_line(data = joined, ggplot2::aes(colour = .data$g, group = .data$g), linewidth = .65,
                                linetype = "22", lineend = "round", na.rm = TRUE, name = "chanwe_forecast")
  }
  if (is.null(points)) points <- frequency == "S"
  if (isTRUE(points) && nrow(l)) {
    p <- p + ggplot2::geom_point(data = l[!is.na(l$yp), , drop = FALSE], ggplot2::aes(colour = .data$g), size = 1.5,
                                 name = "chanwe_points")
  }

  # The last value of the focus series, in the ink pill.
  right_pad <- .03
  if (isTRUE(main)) {
    fs <- d[d$g == focus & !is.na(d$yp), , drop = FALSE]
    if (nrow(fs)) {
      last <- fs[which.max(fs$x), , drop = FALSE]
      lbl <- main_label %||_% fmt(last$y, last$side)
      p <- p + annotate_chanwe_main(last$x, last$yp, label = lbl)
      right_pad <- .12
    }
  }
  if (labels == "direct" && nrow(l)) {
    ends <- do.call(rbind, lapply(split(l[!is.na(l$yp), , drop = FALSE], l$g[!is.na(l$yp)], drop = TRUE),
                                  function(s) s[which.max(s$x), , drop = FALSE]))
    if (isTRUE(main)) ends <- ends[ends$g != focus, , drop = FALSE]
    if (nrow(ends)) {
      ends$label <- paste0(toupper(as.character(ends$g)), "  ", vapply(seq_len(nrow(ends)), function(i) fmt(ends$y[[i]], ends$side[[i]]), ""))
      ends$ly <- .cwa_spread(ends$yp, .06 * diff(range(d$yp, na.rm = TRUE)))
      p <- p + ggplot2::geom_point(data = ends, ggplot2::aes(colour = .data$g), size = 1.2, name = "chanwe_ends") +
        ggplot2::geom_text(data = ends, ggplot2::aes(y = .data$ly, label = .data$label), hjust = 0, nudge_x = days * 1.5,
                           family = .cwc_mono, size = 2.4, colour = .cwc_quiet())
      right_pad <- .24
    }
  }

  # An axis' zero, read back through the second axis' inverse, can come out as -1e-18: it prints as zero.
  snap <- function(f) function(v) f(ifelse(!is.na(v) & abs(v) < 1e-9 * max(1, abs(v), na.rm = TRUE), 0, v))
  sec <- if (any(sides == "right")) ggplot2::sec_axis(transform = ~ . / k, breaks = ggplot2::derive(), labels = snap(number_right)) else ggplot2::waiver()
  window <- if (is.null(limits)) range(d$x, na.rm = TRUE) else as.Date(limits)
  p <- p +
    ggplot2::scale_colour_manual(values = cols, breaks = lv, aesthetics = c("colour", "fill"), name = NULL,
                                 guide = if (labels == "legend") "legend" else "none") +
    ggplot2::scale_x_date(breaks = breaks_chanwe_period(frequency)(window), labels = label_chanwe_period(frequency, lang),
                          expand = ggplot2::expansion(mult = c(.01, right_pad), add = days * .5)) +
    ggplot2::scale_y_continuous(labels = snap(number), sec.axis = sec, expand = ggplot2::expansion(mult = c(.05, .08))) +
    ggplot2::coord_cartesian(xlim = window, clip = "off") +
    theme + ggplot2::theme(legend.position = if (labels == "legend") "top" else "none") +
    ggplot2::labs(x = NULL, y = NULL)
  if (any(marks == "bar")) p <- p + ggplot2::expand_limits(y = 0)
  attr(p, "chanwe_secondary") <- k
  attr(p, "chanwe_colours") <- cols
  p
}
