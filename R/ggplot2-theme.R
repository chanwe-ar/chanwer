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
#'       title = "Performance overview",
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

  reg <- if (requireNamespace("systemfonts", quietly = TRUE)) {
    systemfonts::registry_fonts()$family
  } else {
    character(0)
  }
  title_family <- if (".chanwe-title" %in% reg) ".chanwe-title" else "Archivo"
  title_face <- if (".chanwe-title" %in% reg) "plain" else "black"
  subtitle_family <- if (".chanwe-subtitle" %in% reg) {
    ".chanwe-subtitle"
  } else {
    "Satoshi"
  }
  subtitle_face <- if (".chanwe-subtitle" %in% reg) "plain" else "plain"

  mono_family <- if (
    requireNamespace("systemfonts", quietly = TRUE) &&
      "JetBrains Mono" %in%
        c(
          systemfonts::registry_fonts()$family,
          systemfonts::system_fonts()$family
        )
  ) {
    "JetBrains Mono"
  } else {
    "mono"
  }

  title_element <- ggplot2::element_text(
    family = title_family,
    color = colors[["typst-ink"]],
    face = title_face,
    size = base_text_size * 2,
    hjust = 0,
    lineheight = 1.10,
    margin = ggplot2::margin(b = 4)
  )
  subtitle_element <- ggplot2::element_text(
    family = subtitle_family,
    color = colors[["typst-fg-muted"]],
    face = subtitle_face,
    size = base_text_size * 1.25,
    hjust = 0,
    margin = ggplot2::margin(t = 4, b = 20)
  )

  if (requireNamespace("ggtext", quietly = TRUE)) {
    title_element <- ggtext::element_markdown(
      family = title_family,
      color = colors[["typst-ink"]],
      face = title_face,
      size = base_text_size * 20,
      hjust = 0,
      lineheight = 1.10,
      margin = ggplot2::margin(b = 4)
    )
    subtitle_element <- ggtext::element_markdown(
      family = subtitle_family,
      color = colors[["typst-fg-muted"]],
      face = subtitle_face,
      size = base_text_size * 0.88,
      hjust = 0,
      margin = ggplot2::margin(t = 4, b = 20),
      lineheight = 1.3
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
      plot.caption = if (requireNamespace("ggtext", quietly = TRUE)) {
        ggtext::element_markdown(
          family = mono_family,
          color = colors[["typst-fg-subtle"]],
          size = base_text_size * 0.85,
          hjust = 0,
          margin = ggplot2::margin(t = 4)
        )
      } else {
        ggplot2::element_text(
          family = mono_family,
          color = colors[["typst-fg-subtle"]],
          size = base_text_size * 0.85,
          hjust = 0,
          margin = ggplot2::margin(t = 14)
        )
      },
      axis.title = ggplot2::element_text(
        family = mono_family,
        color = colors[["typst-fg-subtle"]],
        face = "plain",
        size = base_text_size * 0.85
      ),
      axis.text = ggplot2::element_text(
        color = colors[["typst-fg-subtle"]],
        size = base_text_size * 0.70
      ),
      axis.title.x = ggplot2::element_text(
        hjust = 1,
        margin = ggplot2::margin(t = 8)
      ),
      axis.title.y = ggplot2::element_text(
        angle = 0,
        hjust = 0,
        vjust = 1.02,
        margin = ggplot2::margin(r = 8)
      ),
      axis.line = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(
        color = colors[["typst-neutral-200"]],
        linewidth = 0.3
      ),
      panel.grid.major = ggplot2::element_line(
        color = colors[["typst-neutral-200"]],
        linewidth = 0.3
      ),
      panel.grid.minor = ggplot2::element_blank(),
      plot.background = ggplot2::element_rect(
        fill = surface_fill,
        color = outer_border_color,
        linewidth = 0.3
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
#' Adds an optional orange mono-caps eyebrow line above the plot title.
#' Without an eyebrow, you can pass plain text directly to
#' `labs(title = ...)` — [theme_chanwe()] styles it automatically.
#'
#' @param text Title text.
#' @param eyebrow Optional eyebrow string shown above the title in orange mono
#'   caps, e.g. `"SECTION · PROFITABILITY"`.
#'
#' @return A string for use inside `labs(title = ...)`.
#' @export
#'
#' @examples
#' # Plain title — no helper needed, theme handles it:
#' # labs(title = "Revenue vs EBITDA margin")
#'
#' # With eyebrow:
#' chanwe_title("Revenue vs EBITDA margin", eyebrow = "SECTION · PROFITABILITY")
chanwe_title <- function(text, eyebrow = NULL) {
  if (is.null(eyebrow)) {
    return(text)
  }
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(paste0("· ", toupper(eyebrow), "\n", text))
  }
  colors <- chanwe_get_colors()
  paste0(
    "<span style='font-family:JetBrains Mono;font-size:8pt;font-weight:500;",
    "letter-spacing:0.18em;color:",
    colors[["typst-primary"]],
    ";'>",
    "· ",
    toupper(eyebrow),
    "</span><br>",
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
chanwe_subtitle <- function(text) {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(text)
  }
  # Explicitly set Fraunces Thin Italic via CSS so this helper renders in the
  # decorative serif treatment regardless of the theme element's family.
  paste0(
    "<span style='font-family:\"Fraunces 9pt\";font-style:italic;font-weight:100;'>",
    text,
    "</span>"
  )
}

#' ChanWe Caption Helper
#'
#' Returns a caption string with a full-width light-gray divider rule above it
#' and a `//` marker before the text, styled to match the axis title treatment.
#' Use inside `ggplot2::labs(caption = ...)` together with [theme_chanwe()].
#'
#' @param text Caption text.
#'
#' @return A markdown string for use inside `labs(caption = ...)`.
#' @export
#'
#' @examples
#' chanwe_caption("Q1 2026 · USD M and %.")
chanwe_caption <- function(text) {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(paste0("// ", text))
  }
  colors <- chanwe_get_colors()
  rule <- paste(rep("─", 160), collapse = "")
  paste0(
    "<span style='color:",
    colors[["typst-ink"]],
    ";font-size:4pt;'>",
    rule,
    "</span><br>",
    "<span style='font-family:JetBrains Mono;color:",
    colors[["typst-primary"]],
    ";'>// </span>",
    text
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
