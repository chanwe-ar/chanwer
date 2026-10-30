# v2 bars and legend keys ----------------------------------------------------
#
# brand-v2 Q3: bars end in 3-4px rounded corners (tokens.json
# `plot.bar-radius`), legend keys are pills. Both are drawn with grid alone,
# so chanwer takes no extra dependency (ggchicklet is not on CRAN and rounds
# every corner, the baseline included).

# Default bar radius in pt: `plot.bar-radius` px at the CSS 0.75 pt/px.
.cw_bar_radius_pt <- function() {
  chanwe_tokens$plot$`bar-radius` * 0.75
}

#' Pill Legend Key
#'
#' A legend key glyph drawn as a pill (a rounded bar with fully round ends),
#' the v2 legend key. [geom_chanwe_col()] and [geom_chanwe_bar()] use it by
#' default; give it to any other layer with `key_glyph = "chanwe_pill"` (with
#' chanwer attached) or `key_glyph = draw_key_chanwe_pill`.
#'
#' The pill takes the layer's `fill`, or its `colour` when the layer has no
#' fill (lines, points), so a line chart's legend reads as coloured pills too.
#'
#' @param data,params,size Passed by ggplot2's legend machinery.
#'
#' @return A grid grob.
#' @export
#'
#' @examples
#' df <- data.frame(x = rep(1:5, 2), y = c(1:5, 5:1), g = rep(c("a", "b"), each = 5))
#' p <- ggplot2::ggplot(df, ggplot2::aes(x, y, colour = g)) +
#'   ggplot2::geom_line(key_glyph = draw_key_chanwe_pill) +
#'   theme_chanwe()
draw_key_chanwe_pill <- function(data, params, size) {
  fill <- data$fill
  if (is.null(fill) || all(is.na(fill))) {
    fill <- data$colour %||_% .cw_tk("ink-fg")
  }
  alpha <- data$alpha %||_% NA
  grid::roundrectGrob(
    width = grid::unit(1, "npc"),
    height = grid::unit(1, "npc"),
    r = grid::unit(0.5, "snpc"),
    gp = grid::gpar(
      col = NA,
      fill = ggplot2::fill_alpha(fill, alpha)
    )
  )
}

# Corner points of a rectangle whose corners (bottom-left, bottom-right,
# top-right, top-left) carry their own radius, as x/y vectors in pt.
.cw_round_rect_xy <- function(x0, y0, x1, y1, r, n = 8L) {
  w <- x1 - x0
  h <- y1 - y0
  r <- pmin(pmax(r, 0), w / 2, h / 2)
  arc <- function(cx, cy, rad, from, to) {
    if (rad <= 0) {
      return(list(x = cx, y = cy))
    }
    a <- seq(from, to, length.out = n)
    list(x = cx + rad * cos(a), y = cy + rad * sin(a))
  }
  bl <- arc(x0 + r[1], y0 + r[1], r[1], pi, 1.5 * pi)
  br <- arc(x1 - r[2], y0 + r[2], r[2], 1.5 * pi, 2 * pi)
  tr <- arc(x1 - r[3], y1 - r[3], r[3], 0, 0.5 * pi)
  tl <- arc(x0 + r[4], y1 - r[4], r[4], 0.5 * pi, pi)
  list(
    x = c(bl$x, br$x, tr$x, tl$x),
    y = c(bl$y, br$y, tr$y, tl$y)
  )
}

#' @method makeContent cw_round_bars
#' @export
makeContent.cw_round_bars <- function(x) {
  to_pt_x <- function(v) grid::convertX(grid::unit(v, "native"), "pt", valueOnly = TRUE)
  to_pt_y <- function(v) grid::convertY(grid::unit(v, "native"), "pt", valueOnly = TRUE)
  x0 <- to_pt_x(pmin(x$xmin, x$xmax))
  x1 <- to_pt_x(pmax(x$xmin, x$xmax))
  y0 <- to_pt_y(pmin(x$ymin, x$ymax))
  y1 <- to_pt_y(pmax(x$ymin, x$ymax))
  xs <- list()
  ys <- list()
  for (i in seq_along(x0)) {
    pts <- .cw_round_rect_xy(x0[i], y0[i], x1[i], y1[i], x$radii[i, ])
    xs[[i]] <- pts$x
    ys[[i]] <- pts$y
  }
  ids <- rep(seq_along(xs), lengths(xs))
  grid::setChildren(x, grid::gList(grid::polygonGrob(
    x = grid::unit(unlist(xs), "pt"),
    y = grid::unit(unlist(ys), "pt"),
    id = ids,
    gp = x$bar_gp
  )))
}

# Per-bar corner radii (bl, br, tr, tl): only the end away from the baseline
# is round, and in a stack only the outermost segment, so stacked bars read
# as one rounded bar.
.cw_bar_radii <- function(data, coord, radius) {
  flipped <- isTRUE(data$flipped_aes[1])
  d <- ggplot2::flip_data(data, flipped)
  end_max <- (d$ymin + d$ymax) >= 0
  key <- paste(d$PANEL, signif(d$xmin, 9), signif(d$xmax, 9), end_max)
  outer <- ifelse(
    end_max,
    d$ymax >= stats::ave(d$ymax, key, FUN = max),
    d$ymin <= stats::ave(d$ymin, key, FUN = min)
  )
  horizontal <- xor(flipped, inherits(coord, "CoordFlip"))
  radii <- matrix(0, nrow = nrow(d), ncol = 4L)
  for (i in which(outer)) {
    radii[i, ] <- if (!horizontal) {
      if (end_max[i]) c(0, 0, radius, radius) else c(radius, radius, 0, 0)
    } else {
      if (end_max[i]) c(0, radius, radius, 0) else c(radius, 0, 0, radius)
    }
  }
  radii
}

#' @rdname geom_chanwe_col
#' @format NULL
#' @usage NULL
#' @export
GeomChanweCol <- ggplot2::ggproto(
  "GeomChanweCol", ggplot2::GeomCol,
  draw_key = draw_key_chanwe_pill,
  draw_panel = function(self, data, panel_params, coord, lineend = "butt",
                        linejoin = "mitre", radius = NULL) {
    radius <- radius %||_% .cw_bar_radius_pt()
    if (!coord$is_linear() || radius <= 0 || !nrow(data)) {
      return(ggplot2::ggproto_parent(ggplot2::GeomCol, self)$draw_panel(
        data, panel_params, coord, lineend = lineend, linejoin = linejoin
      ))
    }
    if (is.null(data$linewidth)) data$linewidth <- 0
    radii <- .cw_bar_radii(data, coord, radius)
    coords <- coord$transform(data, panel_params)
    grid::gTree(
      xmin = coords$xmin, xmax = coords$xmax,
      ymin = coords$ymin, ymax = coords$ymax,
      radii = radii,
      bar_gp = grid::gpar(
        col = coords$colour,
        fill = ggplot2::fill_alpha(coords$fill, coords$alpha),
        lwd = coords$linewidth * ggplot2::.pt,
        lty = coords$linetype,
        linejoin = linejoin,
        lineend = lineend
      ),
      name = "geom_chanwe_col",
      cl = "cw_round_bars"
    )
  }
)

#' @rdname geom_chanwe_col
#' @format NULL
#' @usage NULL
#' @export
GeomChanweBar <- ggplot2::ggproto("GeomChanweBar", GeomChanweCol)

#' Rounded Bars (v2)
#'
#' `geom_col()` and `geom_bar()` with the v2 bar shape: the end away from the
#' baseline is rounded by `plot.bar-radius` (3px, drawn as 2.25pt), the base
#' stays square, and in a stack only the outermost segment is rounded so the
#' stack reads as one bar. Horizontal bars (`orientation = "y"` or
#' `coord_flip()`) round their right end, negative bars the end below zero.
#' Their legend keys are pills ([draw_key_chanwe_pill()]).
#'
#' Non-linear coordinates (`coord_polar()`, maps) fall back to square bars.
#'
#' @param mapping,data,stat,position,...,just,na.rm,show.legend,inherit.aes
#'   As in [ggplot2::geom_col()] / [ggplot2::geom_bar()].
#' @param radius Corner radius in points. Default `NULL`: the
#'   `plot.bar-radius` token (3px = 2.25pt). `0` draws square bars.
#'
#' @return A ggplot2 layer.
#' @export
#'
#' @examples
#' avg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#' p <- ggplot2::ggplot(avg, ggplot2::aes(factor(cyl), mpg)) +
#'   geom_chanwe_col(width = 0.6, fill = chanwe_palette("focus")[[1]]) +
#'   theme_chanwe()
geom_chanwe_col <- function(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "stack",
  ...,
  just = 0.5,
  radius = NULL,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    mapping = mapping, data = data, geom = GeomChanweCol, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, just = just, radius = radius, ...)
  )
}

#' @rdname geom_chanwe_col
#' @export
geom_chanwe_bar <- function(
  mapping = NULL,
  data = NULL,
  stat = "count",
  position = "stack",
  ...,
  just = 0.5,
  radius = NULL,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    mapping = mapping, data = data, geom = GeomChanweBar, stat = stat,
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(na.rm = na.rm, just = just, radius = radius, ...)
  )
}
