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
#' | `"white-ivory"` | `#FAF9F7` | `#ECEAE6` | `#F1F0ED` |
#' | `"white"` | `#FFFFFF` | `#E8E8E8` | `#EEEEEE` |
#' | `"gray"` | `#F2F2F2` | `#E0E0E0` | `#EAEAEA` |
#' | `"beige"` | `#F5F1EB` | `#D8D1C7` | `#E3DDD5` |
#'
#' @param base_text_size Base text size in points. Default `6.5`.
#' @param base_family Base font family for body text. Default `"Satoshi"`.
#' @param base_lineheight Base line-height multiplier. Default `1.60`.
#' @param legend_position Legend position string passed to
#'   `theme(legend.position = )`. Default `"bottom"`.
#' @param bg_color Background color for the plot surface. Accepts a hex string
#'   or one of `"white-ivory"` (default), `"white"`, `"gray"`, `"beige"`.
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
  bg_color = "white-ivory",
  plot_padding = 10,
  plot_borders = "none"
) {
  chanwe_load_fonts()
  options(chanwer.plot_borders = plot_borders)

  bg_color <- chanwe_resolve_bg(bg_color)
  colors <- chanwe_get_colors()
  surface_fill <- bg_color
  outer_border_color <- colors[["typst-neutral-200"]]
  grid_color <- switch(
    bg_color,
    "#FAF9F7" = "#ECEAE6",
    "#FFFFFF" = "#E8E8E8",
    "#F5F1EB" = "#D8D1C7",
    "#E0E0E0"
  )
  grid_color_minor <- switch(
    bg_color,
    "#FAF9F7" = "#F1F0ED",
    "#FFFFFF" = "#EEEEEE",
    "#F5F1EB" = "#E3DDD5",
    "#EAEAEA"
  )
  panel_border_element <- ggplot2::element_blank()

  reg <- if (requireNamespace("systemfonts", quietly = TRUE)) {
    systemfonts::registry_fonts()$family
  } else {
    character(0)
  }
  title_family <- if ("Archivo SemiBold" %in% reg) {
    "Archivo SemiBold"
  } else {
    "Archivo"
  }
  title_face <- if (title_family == "Archivo SemiBold") "plain" else "bold"
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

  title_element <- new_element_chanwe_title(
    family = title_family,
    face = title_face,
    size = base_text_size * 1.9,
    colour = colors[["typst-ink"]],
    eyebrow_family = mono_family,
    eyebrow_size = base_text_size * 0.70,
    eyebrow_colour = colors[["typst-primary"]],
    ink_colour = colors[["typst-ink"]]
  )
  subtitle_element <- new_element_chanwe_subtitle(
    family = subtitle_family,
    size = base_text_size * 1.0,
    colour = '#656460',
    ink_colour = colors[["typst-ink"]],
    mono_family = mono_family
  )

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
      plot.caption = new_element_chanwe_caption(
        family = mono_family,
        size = base_text_size * 0.8,
        colour = colors[["typst-fg-muted"]],
        primary_colour = colors[["typst-primary"]],
        ink_colour = colors[["typst-ink"]]
      ),
      axis.title = ggplot2::element_text(
        family = mono_thin_family,
        color = colors[["typst-ink"]],
        face = "plain",
        size = base_text_size * 0.60
      ),
      axis.text = ggplot2::element_text(
        color = colors[["typst-ink"]],
        size = base_text_size * 0.60
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
        color = grid_color,
        linewidth = 0.15
      ),
      axis.line.x = ggplot2::element_blank(),
      axis.line.y = ggplot2::element_blank(),
      axis.ticks = ggplot2::element_line(
        color = grid_color,
        linewidth = 0.07
      ),
      panel.grid.major = ggplot2::element_line(
        color = grid_color,
        linewidth = 0.04
      ),
      panel.grid.minor = ggplot2::element_line(
        color = grid_color_minor,
        linewidth = 0.02
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
  if (is.null(eyebrow)) {
    return(text)
  }
  paste(eyebrow, text, sep = .CW_SEP)
}

#' ChanWe KPI Panel Encoder
#'
#' Encodes KPI data for use with the `kpi` argument of [chanwe_subtitle()].
#' The KPI panel renders between the subtitle separator line and the chart as a
#' scoreboard row: a large hero value on the left and up to three period-change
#' metrics on the right (with automatic ▲/▼ color indicators).
#'
#' @param num Hero value string shown in large type, e.g. `"45,91"`.
#' @param label Unit label shown beside the hero value, e.g. `"USD MM"`.
#' @param period Date or period string shown below the label,
#'   e.g. `"05·MAY·2026"`.
#' @param mtc1_num,mtc2_num,mtc3_num Formatted metric value strings,
#'   e.g. `"0,19%"`. Pass `NULL` to omit a metric.
#' @param mtc1_label,mtc2_label,mtc3_label Short column header for each
#'   metric, e.g. `"WoW"`, `"MoM"`, `"YoY"`.
#' @param mtc1_direction,mtc2_direction,mtc3_direction Direction indicator:
#'   `"+"` renders ▲ in green, `"-"` renders ▼ in red, anything else is
#'   neutral.
#'
#' @return An encoded string for use in [chanwe_subtitle()] `kpi` argument.
#' @export
#'
#' @examples
#' chanwe_kpi(
#'   num = "45,91", label = "USD MM", period = "05·MAY·2026",
#'   mtc1_num = "0,19%",  mtc1_label = "WoW", mtc1_direction = "+",
#'   mtc2_num = "3,29%",  mtc2_label = "MoM", mtc2_direction = "+",
#'   mtc3_num = "17,78%", mtc3_label = "YoY", mtc3_direction = "+"
#' )
#'
#' ## Use in a full plot:
#' if (requireNamespace("ggplot2", quietly = TRUE)) {
#'   ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'     ggplot2::geom_line() +
#'     ggplot2::labs(
#'       title    = chanwe_title("Fleet overview", eyebrow = "MOTOR TREND"),
#'       subtitle = chanwe_subtitle(
#'         "Highway mpg vs vehicle weight",
#'         kpi = chanwe_kpi(
#'           num = "21,0", label = "MPG", period = "1974",
#'           mtc1_num = "2,1%",  mtc1_label = "WoW", mtc1_direction = "+",
#'           mtc2_num = "0,5%",  mtc2_label = "MoM", mtc2_direction = "-",
#'           mtc3_num = "4,3%",  mtc3_label = "YoY", mtc3_direction = "+"
#'         )
#'       ),
#'       caption = chanwe_caption("Source: mtcars")
#'     ) +
#'     theme_chanwe()
#' }
chanwe_kpi <- function(
  num,
  label     = "",
  period    = "",
  mtc1_num  = NULL, mtc1_label = NULL, mtc1_direction = "+",
  mtc2_num  = NULL, mtc2_label = NULL, mtc2_direction = "+",
  mtc3_num  = NULL, mtc3_label = NULL, mtc3_direction = "+"
) {
  raw_metrics <- list(
    list(num = mtc1_num, label = mtc1_label, direction = mtc1_direction),
    list(num = mtc2_num, label = mtc2_label, direction = mtc2_direction),
    list(num = mtc3_num, label = mtc3_label, direction = mtc3_direction)
  )
  metric_fields <- character(0)
  for (m in raw_metrics) {
    if (!is.null(m$num) && !is.null(m$label)) {
      dir <- if (identical(m$direction, "+")) 1L else if (identical(m$direction, "-")) -1L else 0L
      metric_fields <- c(metric_fields, m$label, as.character(m$num), as.character(dir))
    }
  }
  paste(c(as.character(num), label, period, metric_fields), collapse = .CW_KPI_SEP)
}

#' ChanWe Subtitle Helper
#'
#' Produces a subtitle string for `labs(subtitle = ...)` styled by
#' [theme_chanwe()]. Without a note or kpi you can pass plain text directly —
#' this helper is only needed when you want a smaller italic note line below
#' the main subtitle, or a KPI scoreboard panel (see [chanwe_kpi()]).
#'
#' @param text Main subtitle string.
#' @param note Optional smaller italic line below the subtitle, e.g. a
#'   methodological caveat. Ignored when `kpi` is supplied.
#' @param kpi Optional KPI panel encoded with [chanwe_kpi()]. When provided,
#'   a scoreboard row with a hero value and period-change metrics is rendered
#'   between the subtitle separator and the chart.
#'
#' @return A character string for `labs(subtitle = ...)`.
#' @export
#'
#' @examples
#' ## Plain subtitle — pass directly, no helper needed:
#' # ggplot2::labs(subtitle = "Faceted by transmission type")
#'
#' ## Subtitle with a note:
#' chanwe_subtitle(
#'   "Faceted by transmission type",
#'   note = "Max peel measured when foil breaks, otherwise average peel"
#' )
#'
#' ## Subtitle with KPI scoreboard:
#' chanwe_subtitle(
#'   "Evolución de reservas internacionales brutas (USD MM).",
#'   kpi = chanwe_kpi(
#'     num = "45,91", label = "USD MM", period = "05·MAY·2026",
#'     mtc1_num = "0,19%",  mtc1_label = "WoW", mtc1_direction = "+",
#'     mtc2_num = "3,29%",  mtc2_label = "MoM", mtc2_direction = "+",
#'     mtc3_num = "17,78%", mtc3_label = "YoY", mtc3_direction = "+"
#'   )
#' )
chanwe_subtitle <- function(text, note = NULL, kpi = NULL) {
  if (is.null(kpi) && is.null(note)) return(text)
  note_part <- if (!is.null(note) && is.null(kpi)) note else ""
  if (is.null(kpi)) return(paste(text, note_part, sep = .CW_SEP))
  paste(text, note_part, kpi, sep = .CW_SEP)
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
  as.character(text)
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
