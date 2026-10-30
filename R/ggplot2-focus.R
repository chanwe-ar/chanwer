# The v2 colour rule (brand-v2 Q3, C1) ---------------------------------------
#
# Orange is the one signal: the series that matters takes `plot.focus` and
# every other series sits on the `plot.slate` ramp. The categorical palette
# (`plot.categorical`, scale_*_chanwe_d()) is for charts with no focus.

# Slate shades for `k` context series, dark -> light. One series takes the
# middle of the ramp; two to four spread from the second shade to the
# lightest, so none is as dark as the ink-light end and none competes with
# the focus; five or more interpolate across the whole ramp.
.cw_slate_for <- function(k) {
  slate <- chanwe_tokens$plot$slate
  if (k <= 0L) {
    return(character(0))
  }
  if (k == 1L) {
    return(slate[[3L]])
  }
  if (k <= 4L) {
    return(slate[round(seq(2, length(slate), length.out = k))])
  }
  toupper(grDevices::colorRampPalette(slate)(k))
}

#' Focus Colours (v2)
#'
#' Colours for a set of series under the v2 rule: the `focus` level(s) in
#' the focus orange (`plot.focus`, `#FD3810`), every other level on the
#' slate ramp (`plot.slate`), in the order the levels are given. Use it to
#' colour series by hand (highcharter, base graphics, `scale_*_manual()`);
#' [scale_color_chanwe_focus()] does the same inside ggplot2.
#'
#' @param levels Character vector of series names (or a factor, whose levels
#'   are used).
#' @param focus The level that matters. One is the rule; several are
#'   allowed (each takes the orange) but warn.
#' @param others Colours for the other levels instead of the slate ramp
#'   (recycled). Default `NULL`.
#'
#' @return A named character vector of hex colours, one per level.
#' @export
#'
#' @examples
#' chanwe_focus_colors(c("Argentina", "Brasil", "Chile"), focus = "Argentina")
chanwe_focus_colors <- function(levels, focus, others = NULL) {
  if (is.factor(levels)) {
    levels <- levels(levels)
  }
  levels <- unique(as.character(levels))
  focus <- as.character(focus)
  missing <- setdiff(focus, levels)
  if (length(missing)) {
    warning(
      sprintf(
        "`focus` %s not among the series: %s.",
        if (length(missing) == 1L) "is" else "are",
        paste(sprintf("\"%s\"", missing), collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (length(intersect(focus, levels)) > 1L) {
    warning(
      "More than one focus series: orange is meant to mark the one that matters.",
      call. = FALSE
    )
  }
  is_focus <- levels %in% focus
  rest <- if (is.null(others)) {
    .cw_slate_for(sum(!is_focus))
  } else {
    rep_len(others, sum(!is_focus))
  }
  out <- character(length(levels))
  out[is_focus] <- chanwe_tokens$plot$focus
  out[!is_focus] <- rest
  stats::setNames(out, levels)
}

# A discrete scale that knows its limits when it maps, so the focus level
# gets the orange wherever it falls in the level order.
ScaleDiscreteChanweFocus <- ggplot2::ggproto(
  "ScaleDiscreteChanweFocus", ggplot2::ScaleDiscrete,
  focus = NULL,
  others = NULL,
  map = function(self, x, limits = self$get_limits()) {
    limits <- as.character(limits[!is.na(limits)])
    if (!length(limits)) {
      return(rep(self$na.value, length(x)))
    }
    pal <- suppressWarnings(chanwe_focus_colors(limits, self$focus, self$others))
    out <- unname(pal[match(as.character(x), limits)])
    out[is.na(out)] <- self$na.value
    out
  }
)

.cw_focus_scale <- function(aesthetics, focus, others, na.value, ...) {
  if (missing(focus) || !length(focus)) {
    stop("`focus` names the series that matters.", call. = FALSE)
  }
  sc <- ggplot2::discrete_scale(
    aesthetics = aesthetics,
    palette = function(n) .cw_slate_for(n),
    na.value = na.value,
    super = ScaleDiscreteChanweFocus,
    ...
  )
  sc$focus <- as.character(focus)
  sc$others <- others
  sc
}

#' Focus Colour Scales (v2)
#'
#' The v2 colour rule for ggplot2: the series named in `focus` is orange
#' (`plot.focus`), every other series sits on the slate ramp (`plot.slate`).
#' Use it whenever a chart has a series that matters (the client against its
#' peers, this year against the past); keep [scale_color_chanwe_d()] (the
#' categorical palette) for charts with no focus series.
#'
#' The focus level takes the orange wherever it falls in the level order, and
#' the slate shades follow the order of the other levels.
#'
#' @param focus The level (series) that matters.
#' @param others Optional colours for the other levels, instead of the
#'   slate ramp.
#' @param na.value Colour for missing values. Default the lightest slate.
#' @param ... Passed to [ggplot2::discrete_scale()] (`name`, `labels`,
#'   `breaks`, `guide`, ...).
#'
#' @return A ggplot2 scale.
#' @seealso [chanwe_focus_colors()] for the same colours outside ggplot2.
#' @export
#'
#' @examples
#' df <- data.frame(
#'   year = rep(2020:2025, 3),
#'   value = c(1, 2, 3, 4, 5, 6, 2, 2, 3, 3, 4, 4, 3, 3, 2, 3, 3, 4),
#'   country = rep(c("Argentina", "Brasil", "Chile"), each = 6)
#' )
#' p <- ggplot2::ggplot(df, ggplot2::aes(year, value, colour = country)) +
#'   ggplot2::geom_line(key_glyph = draw_key_chanwe_pill) +
#'   scale_color_chanwe_focus("Argentina") +
#'   theme_chanwe()
scale_color_chanwe_focus <- function(
  focus,
  others = NULL,
  na.value = chanwe_tokens$plot$slate[[length(chanwe_tokens$plot$slate)]],
  ...
) {
  .cw_focus_scale("colour", focus, others, na.value, ...)
}

#' @rdname scale_color_chanwe_focus
#' @export
scale_fill_chanwe_focus <- function(
  focus,
  others = NULL,
  na.value = chanwe_tokens$plot$slate[[length(chanwe_tokens$plot$slate)]],
  ...
) {
  .cw_focus_scale("fill", focus, others, na.value, ...)
}
