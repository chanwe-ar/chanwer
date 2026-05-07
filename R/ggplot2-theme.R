# ggplot2 helpers -----------------------------------------------------------

chanwe_discrete_pal <- function() {
  values <- unname(chanwe_get_chart())
  function(n) {
    rep(values, length.out = n)
  }
}

#' ChanWe ggplot2 Theme
#'
#' A clean editorial ggplot2 theme with ChanWe typography, neutral surfaces,
#' orange accents, and minimal chrome. Pairs with [chanwe_title()],
#' [chanwe_subtitle()], and [chanwe_caption()] for the full ChanWe title
#' treatment, and with [scale_color_chanwe_d()] / [scale_fill_chanwe_d()] for
#' brand-consistent color palettes.
#'
#' ## Typography
#' | Element | Font | Weight |
#' |---------|------|--------|
#' | Title (with eyebrow) | Archivo SemiBold | 600 |
#' | Subtitle | Satoshi | 400 |
#' | Axis text | Satoshi | 400 |
#' | Axis titles | JetBrains Mono Thin | 100 |
#' | Facet strip labels | JetBrains Mono Thin | 100 |
#' | Legend text / title | JetBrains Mono | 400 |
#' | Caption | JetBrains Mono | 400 |
#'
#' Call [chanwe_load_fonts()] once per session to register the custom font
#' families. `theme_chanwe()` calls it automatically.
#'
#' ## Background variants
#' | Name | Hex | Major grid | Minor grid |
#' |------|-----|------------|------------|
#' | `"white"` | `#FFFFFF` | `#F0F0F0` | `#F4F4F4` |
#' | `"gray"` | `#F5F5F5` | `#E8E8E8` | `#EBEBEB` |
#' | `"beige"` | `#ECE5D8` | `#E0D6CA` | `#E6DDD2` |
#'
#' @param base_text_size Base text size in points. Default `6.5`.
#' @param base_family Base font family for body text. Default `"Satoshi"`.
#' @param base_lineheight Base line-height multiplier. Default `1.60`.
#' @param legend_position Legend position string passed to
#'   `theme(legend.position = )`. Default `"bottom"`.
#' @param bg_color Background color for the plot surface. Accepts a hex string
#'   or one of `"white"` (default), `"gray"`, `"beige"`.
#' @param plot_padding Uniform outer margin in pts applied to all four sides of
#'   the plot (title, caption, and panel included). Default `2`.
#'   Pass a single number, e.g. `plot_padding = 18`.
#'
#' @return A ggplot2 theme object. Add to any ggplot with `+ theme_chanwe()`.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'
#'   ## Basic scatter — white background, bottom legend
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'     ggplot2::geom_point(size = 3) +
#'     scale_color_chanwe_d() +
#'     ggplot2::labs(
#'       title = chanwe_title("Fuel efficiency by weight"),
#'       subtitle = "Highway mpg vs vehicle weight",
#'       caption = chanwe_caption("Source: Motor Trend, 1974")
#'     ) +
#'     theme_chanwe()
#'
#'   ## With eyebrow, beige background, no legend
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'     ggplot2::geom_point(size = 3) +
#'     scale_color_chanwe_d() +
#'     ggplot2::labs(
#'       title = chanwe_title("Fuel efficiency", eyebrow = "SECTION · FLEET"),
#'       subtitle = "Highway mpg vs vehicle weight",
#'       caption = chanwe_caption("Source: Motor Trend, 1974")
#'     ) +
#'     theme_chanwe(bg_color = "beige", legend_position = "none")
#'
#'   ## Bar chart — gray background, fill scale
#'   avg_mpg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#'   ggplot2::ggplot(avg_mpg, ggplot2::aes(factor(cyl), mpg, fill = factor(cyl))) +
#'     ggplot2::geom_col(width = 0.6) +
#'     scale_fill_chanwe_d() +
#'     ggplot2::labs(
#'       title = chanwe_title("Average MPG by cylinder count"),
#'       caption = chanwe_caption("Source: mtcars")
#'     ) +
#'     theme_chanwe(bg_color = "gray", legend_position = "none")
#'
#'   ## Faceted line chart
#'   ggplot2::ggplot(ggplot2::economics_long,
#'     ggplot2::aes(date, value01, color = variable)) +
#'     ggplot2::geom_line(linewidth = 0.6) +
#'     ggplot2::facet_wrap(~variable, scales = "free_y", ncol = 2) +
#'     scale_color_chanwe_d() +
#'     ggplot2::labs(
#'       title = chanwe_title("US economic indicators", eyebrow = "MACRO"),
#'       caption = chanwe_caption("Source: ggplot2::economics_long")
#'     ) +
#'     theme_chanwe(legend_position = "none")
#' }
theme_chanwe <- function(
  base_text_size = 6.5,
  base_family = "Satoshi",
  base_lineheight = 1.60,
  legend_position = "bottom",
  bg_color = "white",
  plot_padding = 2,
  plot_borders = TRUE
) {
  chanwe_load_fonts()

  bg_color <- chanwe_resolve_bg(bg_color)
  colors <- chanwe_get_colors()
  surface_fill <- bg_color
  outer_border_color <- colors[["typst-neutral-200"]]
  grid_color <- switch(
    bg_color,
    "#FFFFFF" = "#F0F0F0",
    "#ECE5D8" = "#E0D6CA",
    colors[["typst-neutral-200"]]
  )
  grid_color_minor <- switch(
    bg_color,
    "#FFFFFF" = "#F4F4F4",
    "#ECE5D8" = "#E6DDD2",
    "#EBEBEB"
  )
  panel_border_element <- ggplot2::element_blank()

  reg <- if (requireNamespace("systemfonts", quietly = TRUE)) {
    systemfonts::registry_fonts()$family
  } else {
    character(0)
  }
  title_family <- "Archivo"
  title_face <- "plain"
  subtitle_family <- "Satoshi"
  subtitle_face <- "plain"

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
  mono_thin_family <- if (
    requireNamespace("systemfonts", quietly = TRUE) &&
      "JetBrains Mono Thin" %in% systemfonts::registry_fonts()$family
  ) {
    "JetBrains Mono Thin"
  } else {
    mono_family
  }

  title_element <- ggplot2::element_text(
    family = title_family,
    color = colors[["typst-ink"]],
    face = title_face,
    size = base_text_size * 1.9,
    hjust = 0,
    lineheight = 1.10,
    margin = ggplot2::margin(b = 1)
  )
  subtitle_element <- ggplot2::element_text(
    family = subtitle_family,
    color = colors[["typst-fg-muted"]],
    face = "plain",
    size = base_text_size * 1,
    hjust = 0,
    margin = ggplot2::margin(t = 3, b = 20)
  )

  if (requireNamespace("ggtext", quietly = TRUE)) {
    title_element <- ggtext::element_markdown(
      family = title_family,
      color = colors[["typst-ink"]],
      face = title_face,
      size = base_text_size * 1.9,
      hjust = 0,
      lineheight = 1,
      margin = ggplot2::margin(b = 1)
    )
    subtitle_element <- ggtext::element_textbox_simple(
      family = subtitle_family,
      color = colors[["typst-fg-muted"]],
      face = "plain",
      size = base_text_size * 1,
      hjust = 0,
      halign = 0,
      lineheight = 1.3,
      width = grid::unit(1, "npc"),
      margin = ggplot2::margin(t = 3, b = if (plot_borders) 14 else 20),
      padding = ggplot2::margin(t = 0, r = 0, b = if (plot_borders) 6 else 0, l = 0),
      box.colour = if (plot_borders) c(NA, NA, colors[["typst-ink"]], NA) else NULL,
      linewidth = 0.3,
      fill = NA
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
        ggtext::element_textbox_simple(
          family = mono_family,
          color = colors[["typst-fg-muted"]],
          size = base_text_size * 0.8,
          hjust = 0,
          halign = 0,
          width = grid::unit(1, "npc"),
          margin = ggplot2::margin(t = 10),
          padding = ggplot2::margin(t = 8, r = 0, b = if (plot_borders) 6 else 0, l = 0),
          box.colour = if (plot_borders) {
            c(colors[["typst-ink"]], NA, colors[["typst-ink"]], NA)
          } else {
            c(colors[["typst-ink"]], NA, NA, NA)
          },
          linewidth = 0.3,
          fill = NA
        )
      } else {
        ggplot2::element_text(
          family = mono_family,
          color = colors[["typst-fg-muted"]],
          size = base_text_size * 0.8,
          hjust = 0,
          margin = ggplot2::margin(t = 14)
        )
      },
      axis.title = ggplot2::element_text(
        family = mono_thin_family,
        color = colors[["typst-ink"]],
        face = "plain",
        size = base_text_size * 0.75
      ),
      axis.text = ggplot2::element_text(
        color = colors[["typst-ink"]],
        size = base_text_size * 0.75
      ),
      axis.title.x = ggplot2::element_text(
        hjust = 1,
        margin = ggplot2::margin(t = 10)
      ),
      axis.title.y = ggplot2::element_text(
        angle = 90,
        hjust = 1,
        vjust = 0.5,
        margin = ggplot2::margin(0, 8, 0, 0)
      ),
      axis.line = ggplot2::element_line(
        color = 'white',
        linewidth = 0.15
      ),
      axis.ticks = ggplot2::element_line(
        color = grid_color,
        linewidth = 0.3
      ),
      panel.grid.major = ggplot2::element_line(
        color = grid_color,
        linewidth = 0.15
      ),
      panel.grid.minor = ggplot2::element_line(
        color = grid_color_minor,
        linewidth = 0.1
      ),
      plot.background = ggplot2::element_rect(fill = surface_fill, color = NA),
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
        family = mono_thin_family,
        color = colors[["typst-ink"]],
        face = "plain",
        size = base_text_size * 1,
        margin = ggplot2::margin(b = 6)
      ),
      legend.position = legend_position,
      legend.justification = "center",
      legend.box.just = "center",
      legend.title = ggplot2::element_text(
        family = mono_family,
        color = colors[["typst-fg-muted"]],
        face = "plain",
        size = base_text_size * 0.8
      ),
      legend.text = ggplot2::element_text(
        family = mono_family,
        color = colors[["typst-ink"]],
        size = base_text_size * 0.8
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
      legend.key.size = grid::unit(0.85, "lines"),
      panel.spacing = grid::unit(1.0, "lines"),
      plot.subtitle = subtitle_element,
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.margin = ggplot2::margin(
        plot_padding,
        plot_padding,
        plot_padding,
        plot_padding
      )
    )
  )
  theme_obj
}

#' ChanWe Title Helper
#'
#' Produces a title string for `labs(title = ...)` styled by [theme_chanwe()].
#' Without an eyebrow you can pass plain text directly — this helper is only
#' needed when you want the orange mono-caps eyebrow line above the title.
#'
#' The eyebrow renders as a small-caps JetBrains Mono label in the brand orange
#' (`#FB3D0E`), prefixed by `──`. Requires the `ggtext` package for HTML
#' rendering; falls back to plain `──  EYEBROW\nTitle` when unavailable.
#'
#' @param text Main title string. Rendered in Archivo Black by [theme_chanwe()].
#' @param eyebrow Optional short label above the title, e.g.
#'   `"SECTION · PROFITABILITY"`. Displayed in orange mono caps.
#'
#' @return A character string for `labs(title = ...)`.
#' @export
#'
#' @examples
#' ## Plain title — pass directly, no helper needed:
#' # ggplot2::labs(title = "Revenue vs EBITDA margin")
#'
#' ## Title with section eyebrow:
#' chanwe_title("Revenue vs EBITDA margin", eyebrow = "SECTION · PROFITABILITY")
#'
#' ## Use in a full plot:
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     ggplot2::geom_point() +
#'     ggplot2::labs(title = chanwe_title("Fleet overview", eyebrow = "TLDR;")) +
#'     theme_chanwe()
#' }
chanwe_title <- function(text, eyebrow = NULL) {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    if (is.null(eyebrow)) {
      return(text)
    }
    return(paste0("── ", toupper(eyebrow), "\n", text))
  }
  if (is.null(eyebrow)) {
    return(text)
  }
  chanwe_load_fonts()
  colors <- chanwe_get_colors()
  reg <- if (requireNamespace("systemfonts", quietly = TRUE)) {
    systemfonts::registry_fonts()$family
  } else {
    character(0)
  }
  tf <- if ("Archivo SemiBold" %in% reg) {
    "\"Archivo SemiBold\""
  } else if ("Archivo ExtraBold" %in% reg) {
    "\"Archivo ExtraBold\""
  } else {
    "Archivo"
  }
  paste0(
    "<span style='font-family:\"JetBrains Mono\";font-size:6pt;font-weight:normal;color:",
    colors[["typst-primary"]],
    ";'>── ",
    toupper(eyebrow),
    "</span><br><span style='font-size:9pt;color:transparent;'>·</span><br>",
    "<span style='font-family:",
    tf,
    ",sans-serif;letter-spacing:0em;'>",
    text,
    "</span>"
  )
}

#' ChanWe Subtitle Helper
#'
#' Returns the subtitle string as-is for use in `labs(subtitle = ...)`.
#' [theme_chanwe()] styles it automatically in Archivo ExtraLight (200), so
#' no wrapper is needed — this function exists as a discoverable entry point
#' and may gain formatting options in future versions.
#'
#' @param text Subtitle text.
#'
#' @return The input string unchanged.
#' @export
#'
#' @examples
#' ## Pass directly — theme handles the font:
#' # ggplot2::labs(subtitle = "Quarterly performance")
#'
#' ## Or via the helper (equivalent):
#' chanwe_subtitle("Quarterly performance")
chanwe_subtitle <- function(text) {
  text
}

#' ChanWe Caption Helper
#'
#' Prepends an orange `//` marker to the caption text, rendered in JetBrains
#' Mono by [theme_chanwe()]. Use inside `labs(caption = ...)`.
#'
#' Requires the `ggtext` package for HTML rendering; falls back to plain
#' `"// text"` when unavailable.
#'
#' @param text Caption text, e.g. source line or data note.
#'
#' @return A character string for `labs(caption = ...)`.
#' @export
#'
#' @examples
#' chanwe_caption("Q1 2026 · USD M and %.")
#' chanwe_caption("Source: Motor Trend, 1974 · mtcars dataset")
#'
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     ggplot2::geom_point() +
#'     ggplot2::labs(caption = chanwe_caption("Source: mtcars")) +
#'     theme_chanwe()
#' }
chanwe_caption <- function(text) {
  if (!requireNamespace("ggtext", quietly = TRUE)) {
    return(paste0("// ", text))
  }
  colors <- chanwe_get_colors()
  paste0(
    "<span style='font-family:JetBrains Mono;color:",
    colors[["typst-primary"]],
    ";'>// &ensp;</span>",
    text
  )
}

#' ChanWe Discrete Color Scales
#'
#' Apply the ChanWe categorical palette to `color` or `fill` aesthetics.
#' Colors cycle through the brand chart palette when there are more categories
#' than palette entries.
#'
#' `scale_color_chanwe_d()` maps to the `colour` aesthetic (points, lines,
#' text). `scale_fill_chanwe_d()` maps to the `fill` aesthetic (bars, areas,
#' ribbons).
#'
#' @param ... Additional arguments passed to [ggplot2::discrete_scale()],
#'   e.g. `name`, `labels`, `guide`, `drop`.
#'
#' @return A ggplot2 scale object.
#' @export
#'
#' @examples
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'
#'   ## Points colored by group
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'     ggplot2::geom_point(size = 3) +
#'     scale_color_chanwe_d() +
#'     theme_chanwe()
#'
#'   ## Bars filled by group
#'   avg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#'   ggplot2::ggplot(avg, ggplot2::aes(factor(cyl), mpg, fill = factor(cyl))) +
#'     ggplot2::geom_col() +
#'     scale_fill_chanwe_d() +
#'     theme_chanwe(legend_position = "none")
#' }
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
