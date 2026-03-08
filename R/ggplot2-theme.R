# ggplot2 helpers -----------------------------------------------------------

chanwe_discrete_pal <- function() {
  values <- unname(chanwe_get_chart())
  function(n) {
    rep(values, length.out = n)
  }
}

#' ChanWe ggplot2 Theme
#'
#' A clean editorial ggplot2 theme with ChanWe typography, neutral paper,
#' orange accents, minimal chrome, and compact rectangular geometry.
#' Use [chanwe_title()] and [chanwe_subtitle()] with this theme for the
#' standard ChanWe title treatment.
#'
#' @param base_text_size Base text size in points.
#' @param base_family Base font family.
#' @param base_lineheight Base text line-height multiplier.
#' @param legend_position Legend position passed to `theme(legend.position = )`.
#' @param background Background surface variant: `"beige"` (`#F7F7F7`) or
#'   `"white"` (`#FFFFFF`). Both use a light-gray border (`#F7F7F7`).
#'
#' @return A ggplot2 theme object.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'     ggplot2::geom_point(size = 3) +
#'     scale_color_chanwe_d() +
#'     ggplot2::labs(
#'       title = chanwe_title("Performance overview"),
#'       subtitle = chanwe_subtitle("Example subtitle")
#'     ) +
#'     theme_chanwe(
#'       base_text_size = 12,
#'       legend_position = "bottom",
#'       background = "beige"
#'     )
#' }
theme_chanwe <- function(
  base_text_size = 11.5,
  base_family = "DM Sans",
  base_lineheight = 1.60,
  legend_position = "bottom",
  background = c("beige", "white")
) {
  colors <- chanwe_get_colors()
  background <- match.arg(background)
  surface_fill <- switch(
    background,
    beige = colors[["brand-white"]],
    white = colors[["brand-pure-white"]]
  )
  outer_border_color <- switch(
    background,
    beige = colors[["brand-white"]],
    white = colors[["brand-beige-soft"]]
  )
  inner_border_color <- switch(
    background,
    beige = colors[["brand-white"]],
    white = NA_character_
  )
  panel_border_element <- if (identical(background, "white")) {
    ggplot2::element_blank()
  } else {
    ggplot2::element_rect(
      fill = NA,
      color = inner_border_color,
      linewidth = 0.6
    )
  }
  title_element <- ggplot2::element_text(
    color = colors[["brand-black"]],
    face = "bold",
    size = base_text_size * 1.25,
    hjust = 0,
    lineheight = 1.15,
    margin = ggplot2::margin(b = 2)
  )
  subtitle_element <- ggplot2::element_text(
    color = colors[["p13-gray-05"]],
    size = base_text_size * 0.82,
    hjust = 0,
    margin = ggplot2::margin(b = 18, l = 6)
  )

  if (requireNamespace("ggtext", quietly = TRUE)) {
    title_element <- ggtext::element_markdown(
      color = colors[["brand-black"]],
      face = "bold",
      size = base_text_size * 1.35,
      hjust = 0,
      lineheight = 1.15,
      margin = ggplot2::margin(b = 2)
    )
    subtitle_element <- ggtext::element_markdown(
      color = colors[["p13-gray-05"]],
      size = base_text_size * 0.82,
      hjust = 0,
      margin = ggplot2::margin(b = 18, l = 9),
      lineheight = 1.2
    )
  }

  theme_obj <- ggplot2::`%+replace%`(
    ggplot2::theme_minimal(
      base_size = base_text_size,
      base_family = base_family
    ),
    ggplot2::theme(
      text = ggplot2::element_text(
        color = colors[["p13-gray-05"]],
        lineheight = base_lineheight
      ),
      plot.title = title_element,
      plot.caption = ggplot2::element_text(
        color = colors[["p13-gray-06"]],
        size = base_text_size * 0.88,
        hjust = 1,
        margin = ggplot2::margin(t = 10)
      ),
      axis.title = ggplot2::element_text(
        color = colors[["p13-gray-04"]],
        face = "bold",
        size = base_text_size * 0.78
      ),
      axis.text = ggplot2::element_text(
        color = colors[["p13-gray-05"]],
        size = base_text_size * 0.64
      ),
      axis.title.x = ggplot2::element_text(
        hjust = 1,
        margin = ggplot2::margin(t = 10)
      ),
      axis.title.y = ggplot2::element_text(
        angle = 90,
        vjust = 1,
        hjust = 1,
        margin = ggplot2::margin(r = 10)
      ),
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(
        color = colors[["brand-silver"]],
        linewidth = 0.3
      ),
      panel.grid.major = ggplot2::element_line(
        color = colors[["brand-beige-soft"]],
        linewidth = 0.45
      ),
      panel.grid.minor = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(
        fill = surface_fill,
        color = outer_border_color,
        linewidth = 0.6
      ),
      panel.background = ggplot2::element_rect(
        fill = surface_fill,
        color = inner_border_color,
        linewidth = 0.6
      ),
      panel.border = panel_border_element,
      strip.background = ggplot2::element_rect(
        fill = surface_fill,
        color = inner_border_color,
        linewidth = 0.5
      ),
      strip.text = ggplot2::element_text(
        color = colors[["brand-black"]],
        face = "bold"
      ),
      legend.position = legend_position,
      legend.justification = "center",
      legend.box.just = "center",
      legend.title = ggplot2::element_text(
        color = colors[["brand-black"]],
        face = "bold",
        size = base_text_size * 0.70
      ),
      legend.text = ggplot2::element_text(
        color = colors[["p13-gray-05"]],
        size = base_text_size * 0.64
      ),
      legend.background = ggplot2::element_rect(
        fill = surface_fill,
        color = NA
      ),
      legend.key = ggplot2::element_rect(
        fill = surface_fill,
        color = NA
      ),
      legend.box.background = ggplot2::element_rect(
        fill = NA,
        color = NA
      ),
      legend.key.size = grid::unit(0.65, "lines"),
      panel.spacing = grid::unit(1.0, "lines"),
      plot.subtitle = subtitle_element,
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(22, 22, 18, 22)
    )
  )
  theme_obj
}

#' ChanWe Title Helper with Estrategia Marker
#'
#' Creates a title string with a small `Estrategia_Color1.png` image placed
#' before the title text. Use this inside `ggplot2::labs(title = ...)` together
#' with [theme_chanwe()]. The marker renders when `ggtext` is installed.
#'
#' @param text Title text.
#' @param marker_path Optional path to the marker image file.
#' @param marker_width_px Optional marker width in pixels. If `NULL` (default),
#'   width is derived from `marker_scale` and the source image width.
#' @param marker_scale Relative width multiplier applied to the source image
#'   width when `marker_width_px = NULL`. Use `0.01` for ~1% of image width.
#'
#' @return A title string for use inside `labs(title = ...)`.
#' @export
#'
#' @examples
#' chanwe_title("Performance Overview")
chanwe_title <- function(
  text,
  marker_path = NULL,
  marker_width_px = NULL,
  marker_scale = 0.02
) {
  chanwe_require_package("ggtext")

  if (is.null(marker_path)) {
    marker_path <- chanwe_logo_path("Estrategia_Color1.png")
    if (!nzchar(marker_path)) {
      stop(
        "chanwe_title(): bundled marker asset 'Estrategia_Color1.png' was not found. Ensure it is present under 'inst/assets' or the package is installed correctly.",
        call. = FALSE
      )
    }
  }
  marker_path <- normalizePath(marker_path, winslash = "/", mustWork = FALSE)
  if (!nzchar(marker_path) || !file.exists(marker_path)) {
    stop(
      sprintf(
        "chanwe_title(): marker_path does not exist: %s",
        marker_path
      ),
      call. = FALSE
    )
  }
  marker_src <- chanwe_logo_src(marker_path, embed = FALSE)
  if (!nzchar(marker_src)) {
    stop(
      sprintf(
        "chanwe_title(): unable to resolve marker source from path: %s",
        marker_path
      ),
      call. = FALSE
    )
  }
  if (is.null(marker_width_px)) {
    dims <- chanwe_png_dims(marker_path)
    if (!is.null(dims) && is.finite(marker_scale) && marker_scale > 0) {
      marker_width_px <- dims$width * marker_scale
    } else {
      marker_width_px <- 4
    }
  }
  marker_width_px <- max(3, as.numeric(marker_width_px))
  dims <- chanwe_png_dims(marker_path)
  marker_height_px <- if (!is.null(dims) && dims$width > 0) {
    max(3, marker_width_px * (dims$height / dims$width))
  } else {
    marker_width_px
  }

  paste0(
    "<img src='",
    marker_src,
    "' width='",
    format(marker_width_px, trim = TRUE, scientific = FALSE),
    "' height='",
    format(marker_height_px, trim = TRUE, scientific = FALSE),
    "' style='vertical-align:-0.1em;'/>",
    "&nbsp;&nbsp;&nbsp;",
    text,
    "&nbsp;&nbsp;&nbsp;"
  )
}

#' ChanWe Subtitle Helper with Subtle Separator Rule
#'
#' Creates a subtitle string with a short, subtle light-gray separator line on the
#' next line. The accent is rendered when used with `theme_chanwe()` and
#' the `ggtext` package is installed.
#'
#' @param text Subtitle text.
#' @param rule Character glyph sequence used for the accent rule.
#'
#' @return A markdown string for use inside `labs(subtitle = ...)`.
#' @export
#'
#' @examples
#' chanwe_subtitle("Quarterly performance")
chanwe_subtitle <- function(text, rule = "\u2500\u2500\u2500\u2500") {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(text)
  }

  if (identical(rule, "\u2500\u2500\u2500\u2500")) {
    return(paste0(
      text,
      "<br><span style='display:inline-block;width:26px;",
      "border-top:1.4px solid #F7F7F7;line-height:0;'>&nbsp;</span>"
    ))
  }

  paste0(
    text,
    "<br><span style='color:#F7F7F7;font-size:8pt;line-height:0.55;'>",
    rule,
    "</span>"
  )
}

#' ChanWe Discrete Color Scale
#'
#' Discrete ChanWe palette scale for color aesthetics.
#'
#' @param ... Additional arguments passed to [ggplot2::discrete_scale()].
#'
#' @return A ggplot2 scale object.
#' @export
scale_color_chanwe_d <- function(...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = chanwe_discrete_pal(),
    ...
  )
}

#' @rdname scale_color_chanwe_d
#' @export
scale_fill_chanwe_d <- function(...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = chanwe_discrete_pal(),
    ...
  )
}

#' ChanWe Continuous Color Scale
#'
#' Continuous ChanWe gradient scale for color aesthetics.
#'
#' @param colours A character vector of colors used in the gradient.
#' @param ... Additional arguments passed to [ggplot2::scale_color_gradientn()].
#'
#' @return A ggplot2 scale object.
#' @export
scale_color_chanwe_c <- function(
  colours = chanwe_get_colors()[c(
    "p13-orange-10",
    "p13-orange-05",
    "brand-orange"
  )],
  ...
) {
  ggplot2::scale_color_gradientn(colours = colours, ...)
}

#' @rdname scale_color_chanwe_c
#' @export
scale_fill_chanwe_c <- function(
  colours = chanwe_get_colors()[c(
    "p13-orange-10",
    "p13-orange-05",
    "brand-orange"
  )],
  ...
) {
  ggplot2::scale_fill_gradientn(colours = colours, ...)
}
