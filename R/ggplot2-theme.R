# ggplot2 helpers -----------------------------------------------------------

chanwe_discrete_pal <- function() {
  values <- unname(chanwe_get_chart())
  function(n) {
    rep(values, length.out = n)
  }
}

chanwe_logo_path <- function(filename = "Logo_Color1.png") {
  installed <- system.file("assets", filename, package = "chanwer")
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  candidates <- c(
    file.path("inst/assets", filename),
    file.path("assets", filename),
    file.path("_extensions/assets", filename),
    file.path("_extensions/chanwe-brand/assets", filename)
  )
  existing <- candidates[file.exists(candidates)]

  if (!length(existing)) {
    return("")
  }

  normalizePath(existing[[1]], winslash = "/", mustWork = FALSE)
}

chanwe_logo_src <- function(path) {
  if (!nzchar(path)) {
    return("")
  }

  if (requireNamespace("knitr", quietly = TRUE)) {
    return(knitr::image_uri(path))
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

#' ChanWe ggplot2 Theme
#'
#' A clean editorial ggplot2 theme with ChanWe typography, neutral paper,
#' orange accents, minimal chrome, and compact rectangular geometry.
#'
#' @param base_text_size Base text size in points.
#' @param base_family Base font family.
#' @param base_lineheight Base text line-height multiplier.
#' @param legend_position Legend position passed to `theme(legend.position = )`.
#' @param add_logo Logical. If `TRUE`, adds a small orange ChanWe mark in the
#'   top-right of the plot area.
#' @param logo_path Optional path to a logo image file. By default, the ChanWe
#'   `Logo_Color1.png` bundled in package assets is used.
#' @param logo_width_px Width of the logo in pixels.
#'
#' @return A ggplot2 theme object when `add_logo = FALSE`; otherwise a list of
#'   ggplot components (theme + logo tag components) when image rendering is
#'   available.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'     ggplot2::geom_point(size = 3) +
#'     ggplot2::labs(subtitle = chanwe_subtitle("Example subtitle")) +
#'     theme_chanwe(base_text_size = 12, legend_position = "bottom")
#' }
theme_chanwe <- function(base_text_size = 12.5,
                         base_family = "DM Sans",
                         base_lineheight = 1.62,
                         legend_position = "bottom",
                         add_logo = TRUE,
                         logo_path = NULL,
                         logo_width_px = 52) {
  colors <- chanwe_get_colors()
  subtitle_element <- ggplot2::element_text(
    color = colors[["p13-gray-05"]],
    size = base_text_size * 0.82,
    hjust = 0,
    margin = ggplot2::margin(b = 12)
  )

  if (requireNamespace("ggtext", quietly = TRUE)) {
    subtitle_element <- ggtext::element_markdown(
      color = colors[["p13-gray-05"]],
      size = base_text_size * 0.82,
      hjust = 0,
      margin = ggplot2::margin(b = 12),
      lineheight = 1.2
    )
  }

  legend_justification <- if (
    is.character(legend_position) &&
    legend_position %in% c("top", "bottom")
  ) {
    "left"
  } else {
    "center"
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
      plot.title = ggplot2::element_text(
        color = colors[["brand-black"]],
        face = "bold",
        size = base_text_size * 1.35,
        hjust = 0,
        lineheight = 1.15,
        margin = ggplot2::margin(b = 8)
      ),
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
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 10)),
      axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = 10)),
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
        fill = colors[["brand-white"]],
        color = NA
      ),
      panel.background = ggplot2::element_rect(
        fill = colors[["brand-white"]],
        color = NA
      ),
      strip.background = ggplot2::element_rect(
        fill = colors[["brand-beige"]],
        color = colors[["brand-beige-soft"]],
        linewidth = 0.5
      ),
      strip.text = ggplot2::element_text(
        color = colors[["brand-black"]],
        face = "bold"
      ),
      legend.position = legend_position,
      legend.justification = legend_justification,
      legend.title = ggplot2::element_text(
        color = colors[["brand-black"]],
        face = "bold",
        size = base_text_size * 0.78
      ),
      legend.text = ggplot2::element_text(
        color = colors[["p13-gray-05"]],
        size = base_text_size * 0.72
      ),
      legend.background = ggplot2::element_rect(
        fill = colors[["brand-white"]],
        color = NA
      ),
      legend.key = ggplot2::element_rect(
        fill = colors[["brand-white"]],
        color = NA
      ),
      legend.box.background = ggplot2::element_rect(
        fill = colors[["brand-white"]],
        color = NA
      ),
      panel.spacing = grid::unit(1.0, "lines"),
      plot.subtitle = subtitle_element,
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(22, 22, 18, 22)
    )
  )

  if (!isTRUE(add_logo)) {
    return(theme_obj)
  }

  if (is.null(logo_path)) {
    logo_path <- chanwe_logo_path()
  }
  logo_src <- chanwe_logo_src(logo_path)

  if (!requireNamespace("ggtext", quietly = TRUE) || !nzchar(logo_src)) {
    return(theme_obj)
  }

  tag_label <- paste0(
    "<img src='", logo_src, "' style='width:", as.integer(logo_width_px),
    "px;height:auto;'/>"
  )

  tag_element <- ggtext::element_markdown(
    family = base_family,
    size = base_text_size * 0.78,
    hjust = 1,
    vjust = 1
  )

  list(
    theme_obj,
    ggplot2::labs(tag = tag_label),
    ggplot2::theme(
      plot.tag.position = c(0.992, 0.992),
      plot.tag = tag_element
    )
  )
}

#' ChanWe Subtitle Helper with Orange Accent Rule
#'
#' Creates a subtitle string with a short, thick orange accent line on the
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
chanwe_subtitle <- function(text, rule = "\u2588\u2588\u2588") {
  paste0(
    text,
    "<br><span style='color:#E94B2B;font-size:125%;line-height:0.8;'>",
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
    ...) {
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
    ...) {
  ggplot2::scale_fill_gradientn(colours = colours, ...)
}
