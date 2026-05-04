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
#' standard ChanWe title treatment: Archivo Bold heading with an orange `//`
#' marker, Fraunces 9pt ExtraLight Italic subtitle.
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
  base_family = "Satoshi",
  base_lineheight = 1.60,
  legend_position = "bottom",
  background = c("beige", "white")
) {
  chanwe_load_fonts()

  colors <- chanwe_get_colors()
  background <- match.arg(background)
  surface_fill <- switch(
    background,
    beige = colors[["typst-neutral-100"]],
    white = colors[["typst-white"]]
  )
  outer_border_color <- switch(
    background,
    beige = colors[["typst-neutral-200"]],
    white = colors[["typst-neutral-200"]]
  )
  panel_border_element <- ggplot2::element_blank()

  registered <- requireNamespace("systemfonts", quietly = TRUE) &&
    ".chanwe-subtitle" %in% systemfonts::registry_fonts()$family
  subtitle_family <- if (registered) ".chanwe-subtitle" else "Fraunces 9pt"
  subtitle_face   <- if (registered) "plain" else "italic"

  title_element <- ggplot2::element_text(
    family = "Archivo",
    color = colors[["typst-ink"]],
    face = "bold",
    size = base_text_size * 1.25,
    hjust = 0,
    lineheight = 1.15,
    margin = ggplot2::margin(b = 2)
  )
  subtitle_element <- ggplot2::element_text(
    family = subtitle_family,
    color = colors[["typst-fg-muted"]],
    face = subtitle_face,
    size = base_text_size * 0.70,
    hjust = 0,
    margin = ggplot2::margin(t = 8, b = 18, l = 30)
  )

  if (requireNamespace("ggtext", quietly = TRUE)) {
    title_element <- ggtext::element_markdown(
      family = "Archivo",
      color = colors[["typst-ink"]],
      face = "bold",
      size = base_text_size * 1.35,
      hjust = 0,
      lineheight = 1.15,
      margin = ggplot2::margin(b = 2)
    )
    subtitle_element <- ggtext::element_markdown(
      family = subtitle_family,
      color = colors[["typst-fg-muted"]],
      face = subtitle_face,
      size = base_text_size * 0.70,
      hjust = 0,
      margin = ggplot2::margin(t = 2, b = 18, l = 13),
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
        color = colors[["typst-fg-muted"]],
        lineheight = base_lineheight
      ),
      plot.title = title_element,
      plot.caption = ggplot2::element_text(
        color = colors[["typst-fg-subtle"]],
        size = base_text_size * 0.64,
        hjust = 1,
        margin = ggplot2::margin(t = 10)
      ),
      axis.title = ggplot2::element_text(
        color = colors[["typst-fg"]],
        face = "bold",
        size = base_text_size * 0.78
      ),
      axis.text = ggplot2::element_text(
        color = colors[["typst-fg-muted"]],
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
        color = colors[["typst-neutral-300"]],
        linewidth = 0.3
      ),
      panel.grid.major = ggplot2::element_line(
        color = colors[["typst-neutral-300"]],
        linewidth = 0.45
      ),
      panel.grid.minor = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(
        fill = surface_fill,
        color = outer_border_color,
        linewidth = 0.4
      ),
      panel.background = ggplot2::element_rect(
        fill = surface_fill,
        color = NA
      ),
      panel.border = panel_border_element,
      strip.background = ggplot2::element_rect(
        fill = surface_fill,
        color = NA
      ),
      strip.text = ggplot2::element_text(
        color = colors[["typst-ink"]],
        face = "bold"
      ),
      legend.position = legend_position,
      legend.justification = "center",
      legend.box.just = "center",
      legend.title = ggplot2::element_text(
        color = colors[["typst-ink"]],
        face = "bold",
        size = base_text_size * 0.70
      ),
      legend.text = ggplot2::element_text(
        color = colors[["typst-fg-muted"]],
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

#' ChanWe Title Helper
#'
#' Creates a title string prefixed with a `//` glyph in the ChanWe primary
#' orange at weight 100. Use inside `ggplot2::labs(title = ...)` together with
#' [theme_chanwe()]. The styled marker renders when `ggtext` is installed;
#' falls back to plain `// text` otherwise.
#'
#' @param text Title text.
#'
#' @return A title string for use inside `labs(title = ...)`.
#' @export
#'
#' @examples
#' chanwe_title("Performance Overview")
chanwe_title <- function(text) {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(paste0("// ", text))
  }
  colors <- chanwe_get_colors()
  paste0(
    "<span style='color:", colors[["typst-primary"]], ";font-weight:100;'>//</span>",
    "&ensp;&ensp;&ensp;",
    text
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
    "typst-primary"
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
    "typst-primary"
  )],
  ...
) {
  ggplot2::scale_fill_gradientn(colours = colours, ...)
}
