# ggplot2 helpers -----------------------------------------------------------

chanwe_discrete_pal <- function(palette = "chart", reverse = FALSE) {
  is_named_group <- length(palette) == 1L && !grepl("^#", palette[[1L]])
  # Ramp groups (one-hue shade scales) sample across the FULL ramp so small
  # n still spans light → dark; categorical groups keep their fixed,
  # CVD-validated slot order and recycle past their length.
  is_ramp <- is_named_group && grepl("^(p13_|p15_|mb_)", palette[[1L]])
  values <- if (is_named_group) {
    unname(chanwe_palette(palette))
  } else {
    as.character(palette) # raw color vector passed directly
  }
  if (isTRUE(reverse)) {
    values <- rev(values)
  }
  function(n) {
    if (is_ramp) {
      if (n > length(values)) {
        grDevices::colorRampPalette(values)(n)
      } else {
        values[round(seq(1L, length(values), length.out = n))]
      }
    } else {
      rep(values, length.out = n)
    }
  }
}

chanwe_seq_pal <- function(palette = "orange", reverse = FALSE) {
  ramps <- .chanwe_seq_ramps()
  if (length(palette) > 1L || grepl("^#", palette[[1L]])) {
    values <- as.character(palette) # raw color vector passed directly
  } else {
    if (!palette %in% names(ramps)) {
      stop(
        "`palette` must be one of: ",
        paste(sprintf("'%s'", names(ramps)), collapse = ", "),
        " (yellow and cyan are excluded: their ramps are too light to encode",
        " magnitude on the brand surfaces).",
        call. = FALSE
      )
    }
    values <- ramps[[palette]]
  }
  if (isTRUE(reverse)) values <- rev(values)
  values
}

#' Chanwe ggplot2 Theme
#'
#' A clean editorial ggplot2 theme with Chanwe typography, neutral surfaces,
#' orange accents, and minimal chrome. Pairs with [chanwe_title()],
#' [chanwe_subtitle()], and [chanwe_caption()] for the full Chanwe title
#' treatment, and with [scale_color_chanwe_d()] / [scale_fill_chanwe_d()] for
#' brand-consistent color palettes.
#'
#' ## Typography
#' | Element | Font | Weight |
#' |---------|------|--------|
#' | Title (with eyebrow) | Archivo | 400 |
#' | Subtitle | Satoshi | 400 |
#' | Subtitle note / KPI hero | Cormorant Garamond | italic |
#' | Axis text | Satoshi | 400 |
#' | Axis titles | JetBrains Mono | 400 |
#' | Facet strip labels | JetBrains Mono Thin | 100 |
#' | Legend text / title | JetBrains Mono | 400 |
#' | Caption | JetBrains Mono Thin | 100 |
#'
#' The eyebrow renders in the brand primary (`typst-primary`, `#FD3810`);
#' the caption `//` prefix uses the text-accessible primary variant
#' (`typst-primary-text`), which passes WCAG 4.5:1 small-text contrast on
#' every brand surface. The title is set at 1.85x the base size with a
#' 1.0 line-height so the header, subtitle/KPI block and chart read as
#' three distinct levels.
#'
#' Call [chanwe_load_fonts()] once per session to register the custom font
#' families. `theme_chanwe()` calls it automatically.
#'
#' ## Background variants
#' | Name | Hex | Major grid | Minor grid |
#' |------|-----|------------|------------|
#' | `"metallic"` | `#F7F7F7` | `#E4E4E4` | `#EFEFEF` |
#' | `"white-ivory"` | `#FAF9F7` | `#ECEAE6` | `#F1F0ED` |
#' | `"white"` | `#FFFFFF` | `#E8E8E8` | `#EEEEEE` |
#' | `"gray"` | `#EDF0F1` | `#D4D9DB` | `#E3E7E9` |
#' | `"beige"` | `#F5F1EB` | `#D8D1C7` | `#E3DDD5` |
#'
#' @param base_text_size Base text size in points. Default `6.75`. Title scales at ×1.85, subtitle ×0.90, eyebrow ×0.62.
#' @param base_family Base font family for body text. Default `"Satoshi"`.
#' @param base_lineheight Base line-height multiplier. Default `1.60`.
#' @param legend_position Legend position string passed to
#'   `theme(legend.position = )`. Default `"bottom"`.
#' @param bg_color Background color for the plot surface. Accepts a hex string
#'   or one of `"metallic"` (default), `"white-ivory"`, `"white"`, `"gray"`,
#'   `"beige"`, or `"transparent"`.
#' @param plot_padding Uniform outer margin in pts applied to all four sides of
#'   the plot (title, caption, and panel included). Default `10`.
#'   Pass a single number, e.g. `plot_padding = 18`.
#' @param plot_borders Controls decorative border lines on the plot frame.
#'   `"none"` (default) draws no borders. `"top"` adds a thin ink line above
#'   the title. `"bottom"` adds one below the caption. `"top_bottom"` adds
#'   both. `"complete"` adds all four sides. Pass `TRUE` as shorthand for
#'   `"top_bottom"`.
#' @param has_subtitle Set to `FALSE` when the plot has no subtitle. Reduces
#'   the title's bottom margin and draws a separator line below the title text
#'   (matching the line that the subtitle grob normally draws).
#' @param compact_title When `TRUE` (default) reduces the header block in three
#'   ways: top padding above the eyebrow 8 → 4 pt, gap between subtitle text
#'   and separator line 14 → 6 pt, and bottom padding below the separator line
#'   20 → 12 pt. Set to `FALSE` for the spacious layout.
#' @param header_line When `TRUE` (default) draws the thin separator line that
#'   visually closes the header area: the subtitle grob draws it between the
#'   subtitle text and the chart, and when `has_subtitle = FALSE` the title grob
#'   draws it below the title text. Set to `FALSE` to suppress the line entirely
#'   (e.g. for minimal or embedded layouts).
#'
#' @section Header layout modes:
#'
#' The title + subtitle area is built from custom grobs rather than plain
#' `element_text`, which allows the three-line structure (eyebrow / title /
#' subtitle) and the KPI scoreboard to be positioned with pixel-level control.
#' The `theme_chanwe()` params drive the spacing fields of those grobs:
#'
#' \describe{
#'   \item{Normal (title + subtitle)}{
#'     Use `labs(title = chanwe_title(...), subtitle = chanwe_subtitle(...))`.
#'     `compact_title` controls three paddings simultaneously (see param docs).
#'   }
#'   \item{KPI scoreboard}{
#'     Wrap with `chanwe_subtitle("text", kpi = chanwe_kpi(...))` or omit the
#'     text entirely with `chanwe_subtitle("", kpi = chanwe_kpi(...))`.
#'     When subtitle text is empty, the text row and its separator line are
#'     skipped and the KPI panel starts with just 2 pt of top padding.
#'   }
#'   \item{No subtitle (`has_subtitle = FALSE`)}{
#'     Pass `has_subtitle = FALSE` to `theme_chanwe()`. The title grob draws
#'     its own 0.4 pt separator line 15 pt above the chart area (same visual
#'     weight as the subtitle separator). `compact_title` still controls the
#'     top padding above the eyebrow.
#'   }
#'   \item{No separator line (`header_line = FALSE`)}{
#'     Pass `header_line = FALSE` to suppress the thin ink line that closes the
#'     header area. Works in both subtitle and no-subtitle modes. Useful for
#'     minimal or embedded layouts where the line adds visual noise.
#'   }
#' }
#'
#' @return A ggplot2 theme object. Add to any ggplot with `+ theme_chanwe()`.
#' @export
#'
#' @examples
#' # Plots are assigned; print them to render (requires the brand fonts,
#' # see chanwe_load_fonts()).
#'
#' ## Basic scatter — metallic background, bottom legend
#' p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'   ggplot2::geom_point(size = 3) +
#'   scale_color_chanwe_d() +
#'   ggplot2::labs(
#'     title = chanwe_title("Fuel efficiency by weight"),
#'     subtitle = "Highway mpg vs vehicle weight",
#'     caption = chanwe_caption("Source: Motor Trend, 1974")
#'   ) +
#'   theme_chanwe()
#'
#' ## With eyebrow, beige background, no legend
#' p2 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'   ggplot2::geom_point(size = 3) +
#'   scale_color_chanwe_d() +
#'   ggplot2::labs(
#'     title = chanwe_title("Fuel efficiency", eyebrow = "SECTION - FLEET"),
#'     subtitle = "Highway mpg vs vehicle weight",
#'     caption = chanwe_caption("Source: Motor Trend, 1974")
#'   ) +
#'   theme_chanwe(bg_color = "beige", legend_position = "none")
#'
#' ## Bar chart — gray background, fill scale
#' avg_mpg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#' p3 <- ggplot2::ggplot(avg_mpg,
#'   ggplot2::aes(factor(cyl), mpg, fill = factor(cyl))) +
#'   ggplot2::geom_col(width = 0.6) +
#'   scale_fill_chanwe_d() +
#'   ggplot2::labs(
#'     title = chanwe_title("Average MPG by cylinder count"),
#'     caption = chanwe_caption("Source: mtcars")
#'   ) +
#'   theme_chanwe(bg_color = "gray", legend_position = "none")
theme_chanwe <- function(
  base_text_size = 6.75,
  base_family = "Satoshi",
  base_lineheight = 1.60,
  legend_position = "bottom",
  bg_color = "metallic",
  plot_padding = 10,
  plot_borders = "none",
  has_subtitle = TRUE,
  compact_title = TRUE,
  header_line = TRUE
) {
  chanwe_load_fonts()
  options(chanwer.plot_borders = plot_borders)

  bg_color <- chanwe_resolve_bg(bg_color)
  colors <- chanwe_get_colors()
  surface_fill <- bg_color
  grid_color <- switch(
    bg_color,
    "#F7F7F7" = "#E4E4E4",
    "#FAF9F7" = "#D0CEC8",
    "#FFFFFF" = "#E9E9E9",
    "#EDF0F1" = "#D4D9DB",
    "#F5F1EB" = "#BAB3A8",
    "#C4C4C4"
  )
  grid_color_minor <- switch(
    bg_color,
    "#F7F7F7" = "#EFEFEF",
    "#FAF9F7" = "#E2E0DA",
    "#FFFFFF" = "#F7F7F7",
    "#EDF0F1" = "#E3E7E9",
    "#F5F1EB" = "#CCC5BA",
    "#D6D6D6"
  )
  panel_border_element <- ggplot2::element_blank()

  has_systemfonts <- requireNamespace("systemfonts", quietly = TRUE)
  reg <- if (has_systemfonts) systemfonts::registry_fonts()$family else character(0)
  sys <- if (has_systemfonts) systemfonts::system_fonts()$family else character(0)
  title_family <- "Archivo"
  title_face <- "plain"
  subtitle_family <- "Satoshi"
  italic_family <- if ("Cormorant Garamond" %in% reg) {
    "Cormorant Garamond"
  } else {
    "serif"
  }
  mono_family <- if ("JetBrains Mono" %in% c(reg, sys)) {
    "JetBrains Mono"
  } else {
    "mono"
  }
  mono_thin_family <- if ("JetBrains Mono Thin" %in% reg) {
    "JetBrains Mono Thin"
  } else {
    mono_family
  }

  title_element <- new_element_chanwe_title(
    family = title_family,
    face = title_face,
    # Display size: more contrast against the subtitle/KPI block so the
    # header reads as its own level (hierarchy = weight + size + leading).
    size = base_text_size * 1.85,
    colour = colors[["typst-ink"]],
    eyebrow_family = mono_family,
    eyebrow_size = base_text_size * 0.62,
    # Eyebrow in the brand primary (#FD3810) by request; the `//` caption
    # prefix keeps the text-accessible darkening.
    eyebrow_colour = colors[["typst-primary"]],
    ink_colour = colors[["typst-ink"]],
    top_pad = if (compact_title) 4 else 8
  )
  if (!has_subtitle) {
    title_element$margin <- ggplot2::margin(0, 0, 25, 0)
    title_element$draw_bottom_line <- isTRUE(header_line)
  }
  kpi_label_colour <- colors[["typst-fg-muted"]]

  subtitle_element <- new_element_chanwe_subtitle(
    family = subtitle_family,
    italic_family = italic_family,
    size = base_text_size * 0.9,
    colour = colors[["typst-fg-muted"]],
    ink_colour = colors[["typst-ink"]],
    mono_family = mono_family,
    mono_thin_family = mono_thin_family,
    kpi_label_colour = kpi_label_colour,
    gap_ln = if (compact_title) 10 else 14,
    sub_bot = if (compact_title) 16 else 20,
    sub_top = if (compact_title) 3 else 4,
    draw_middle = isTRUE(header_line)
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
        mono_thin_family = mono_thin_family,
        size = base_text_size * 0.70,
        colour = colors[["typst-ink"]],
        primary_colour = colors[["typst-primary-text"]],
        ink_colour = colors[["typst-ink"]]
      ),
      axis.title = ggplot2::element_text(
        family = mono_family,
        color = colors[["typst-ink"]],
        face = "plain",
        size = base_text_size * 0.66
      ),
      axis.text = ggplot2::element_text(
        color = colors[["typst-ink"]],
        size = base_text_size * 0.66
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
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.major.y = ggplot2::element_line(
        color = grid_color,
        linewidth = 0.07
      ),
      panel.grid.major.x = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
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
      legend.justification = c(1, 0),
      legend.box.just = "right",
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

#' Chanwe Title Helper
#'
#' Produces a title string for `labs(title = ...)` styled by [theme_chanwe()].
#' Without an eyebrow you can pass plain text directly — this helper is only
#' needed when you want the orange mono-caps eyebrow line above the title.
#'
#' The eyebrow renders as a small-caps JetBrains Mono label in the brand
#' orange, prefixed by `──────`. Rendering is handled by the custom title
#' element installed by [theme_chanwe()] — no extra packages are required.
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
#' ## Use in a full plot (assign; print to render with brand fonts):
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(title = chanwe_title("Fleet overview", eyebrow = "TLDR;")) +
#'   theme_chanwe()
chanwe_title <- function(text, eyebrow = NULL) {
  if (is.null(eyebrow)) {
    return(text)
  }
  paste(eyebrow, text, sep = .CW_SEP)
}

#' Chanwe KPI Panel Encoder
#'
#' Builds the KPI scoreboard that sits between the subtitle and the chart.
#' Always wrap the result in [chanwe_subtitle()] and pass that to
#' `labs(subtitle = ...)` — never use the output of `chanwe_kpi()` directly.
#'
#' ## Panel layout
#'
#' ```
#' ── subtitle text ────────────────────────────────────────────
#'
#'   45,91          WOW    MOM    YOY
#'   USD MM       ▲ 0,19% ▲ 3,29% ▲ 17,78%
#'   05·MAY·2026
#'
#' ── chart ────────────────────────────────────────────────────
#' ```
#'
#' - **Left block** — hero value (`num`), unit label (`label`), date (`period`)
#' - **Right block** — up to 3 period metrics, right-anchored, each with a
#'   short label row (e.g. WOW) and a value row with ▲/▼ direction indicator
#'
#' ## Direction vs valence
#'
#' The arrow and the color are two separate channels. `mtcN_direction`
#' states the *movement* (`"+"` → ▲, `"-"` → ▼); `mtcN_valence` states
#' whether that movement is *good news*, and drives the color. The default
#' `"auto"` colors by arithmetic sign (up = positive green), which is right
#' for revenue-like metrics. For smaller-is-better metrics (unemployment,
#' churn, costs) pass the valence explicitly: a falling unemployment rate
#' is `mtc1_direction = "-", mtc1_valence = "good"` — a green ▼. This keeps
#' the brand promise that green/red always encode good/bad, never a raw
#' sign.
#'
#' ## Call pattern
#'
#' ```r
#' labs(
#'   subtitle = chanwe_subtitle(
#'     "Your subtitle text",
#'     kpi = chanwe_kpi(num = ..., label = ..., period = ..., ...)
#'   )
#' )
#' ```
#'
#' @param num Hero value shown in large italic type. **Must be a pre-formatted
#'   string** — formatting (decimal separator, rounding) is your responsibility,
#'   e.g. `"45,91"` not `45.91`.
#' @param label Unit or currency label shown in small caps above the date,
#'   e.g. `"USD MM"`. Pass `""` to omit.
#' @param period Date or period string shown below the label,
#'   e.g. `"05·MAY·2026"`. Pass `""` to omit.
#' @param mtc1_num,mtc2_num,mtc3_num Pre-formatted value for each period
#'   metric, e.g. `"0,19%"`. Set both `mtcN_num` **and** `mtcN_label` to
#'   non-`NULL` to display a metric; set either to `NULL` to omit it entirely.
#' @param mtc1_label,mtc2_label,mtc3_label Short header rendered above the
#'   metric value, e.g. `"WoW"`, `"MoM"`, `"YoY"`.
#' @param mtc1_direction,mtc2_direction,mtc3_direction
#'   Movement of the metric: `"+"` → ▲; `"-"` → ▼; any other value → no
#'   arrow. Default `"+"`.
#' @param mtc1_valence,mtc2_valence,mtc3_valence Whether the movement is
#'   good news — drives the color via the canonical signed tokens.
#'   `"good"` → positive green, `"bad"` → alert vermillion, `"neutral"` →
#'   neutral ink, `"auto"` (default) → derive from the direction (up = good,
#'   down = bad). Set explicitly for smaller-is-better metrics.
#'
#' @return An opaque encoded string. Pass it to the `kpi` argument of
#'   [chanwe_subtitle()]; do not use it directly in `labs()`.
#' @seealso [chanwe_subtitle()], [chanwe_title()], [theme_chanwe()]
#' @export
#'
#' @examples
#' ## Minimal — hero value only, no period metrics:
#' chanwe_kpi(num = "45,91", label = "USD MM", period = "05·MAY·2026")
#'
#' ## With all three period metrics:
#' chanwe_kpi(
#'   num = "45,91", label = "USD MM", period = "05·MAY·2026",
#'   mtc1_num = "0,19%",  mtc1_label = "WoW", mtc1_direction = "+",
#'   mtc2_num = "3,29%",  mtc2_label = "MoM", mtc2_direction = "+",
#'   mtc3_num = "17,78%", mtc3_label = "YoY", mtc3_direction = "-"
#' )
#'
#' ## Smaller-is-better metric — falling churn is GOOD news (green ▼):
#' chanwe_kpi(
#'   num = "2,1", label = "PCT", period = "Q1·2026",
#'   mtc1_num = "0,3pp", mtc1_label = "QoQ",
#'   mtc1_direction = "-", mtc1_valence = "good"
#' )
#'
#' ## Full plot — the typical usage (assign; print to render with brand fonts):
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'   ggplot2::geom_line() +
#'   ggplot2::labs(
#'     title    = chanwe_title("Fleet overview", eyebrow = "MOTOR TREND"),
#'     subtitle = chanwe_subtitle(
#'       "Highway mpg vs vehicle weight",
#'       kpi = chanwe_kpi(
#'         num    = "21,0",   label  = "MPG",  period = "1974",
#'         mtc1_num = "2,1%", mtc1_label = "WoW", mtc1_direction = "+",
#'         mtc2_num = "0,5%", mtc2_label = "MoM", mtc2_direction = "-",
#'         mtc3_num = "4,3%", mtc3_label = "YoY", mtc3_direction = "+"
#'       )
#'     ),
#'     caption = chanwe_caption("Source: mtcars")
#'   ) +
#'   theme_chanwe()
chanwe_kpi <- function(
  num,
  label     = "",
  period    = "",
  mtc1_num  = NULL, mtc1_label = NULL, mtc1_direction = "+", mtc1_valence = "auto",
  mtc2_num  = NULL, mtc2_label = NULL, mtc2_direction = "+", mtc2_valence = "auto",
  mtc3_num  = NULL, mtc3_label = NULL, mtc3_direction = "+", mtc3_valence = "auto"
) {
  raw_metrics <- list(
    list(num = mtc1_num, label = mtc1_label, direction = mtc1_direction, valence = mtc1_valence),
    list(num = mtc2_num, label = mtc2_label, direction = mtc2_direction, valence = mtc2_valence),
    list(num = mtc3_num, label = mtc3_label, direction = mtc3_direction, valence = mtc3_valence)
  )
  metric_fields <- character(0)
  for (m in raw_metrics) {
    if (!is.null(m$num) && !is.null(m$label)) {
      dir <- if (identical(m$direction, "+")) 1L else if (identical(m$direction, "-")) -1L else 0L
      val <- switch(
        as.character(m$valence),
        good = 1L,
        bad = -1L,
        neutral = 0L,
        dir # "auto" (and anything else): color follows the movement
      )
      metric_fields <- c(
        metric_fields,
        m$label, as.character(m$num), as.character(dir), as.character(val)
      )
    }
  }
  paste(c(as.character(num), label, period, metric_fields), collapse = .CW_KPI_SEP)
}

#' Chanwe Subtitle Helper
#'
#' Wraps a subtitle string for `labs(subtitle = ...)` when you need either a
#' secondary note line or a KPI scoreboard panel. For plain text you do
#' **not** need this helper — pass the string directly to `labs(subtitle = )`.
#'
#' ## When to use
#'
#' | Situation | What to write |
#' |-----------|---------------|
#' | Plain subtitle | `labs(subtitle = "My subtitle")` — no helper |
#' | Subtitle + methodological note | `chanwe_subtitle("My subtitle", note = "...")` |
#' | Subtitle + KPI scoreboard | `chanwe_subtitle("My subtitle", kpi = chanwe_kpi(...))` |
#'
#' Note: `note` is ignored when `kpi` is supplied — the two do not stack.
#'
#' @param text Main subtitle string (Satoshi, muted ink, below the title rule).
#' @param note Optional smaller italic line rendered below the subtitle, e.g. a
#'   methodological caveat. Ignored when `kpi` is supplied.
#' @param kpi KPI panel produced by [chanwe_kpi()]. When provided, a scoreboard
#'   zone is inserted between the subtitle separator and the chart. `note` is
#'   silently ignored.
#'
#' @return A character string ready for `labs(subtitle = ...)`.
#' @seealso [chanwe_kpi()], [chanwe_title()], [theme_chanwe()]
#' @export
#'
#' @examples
#' ## 1. Plain subtitle — no helper needed:
#' # labs(subtitle = "Faceted by transmission type")
#'
#' ## 2. Subtitle + note:
#' chanwe_subtitle(
#'   "Faceted by transmission type",
#'   note = "Excludes outliers beyond 3 SD"
#' )
#'
#' ## 3. Subtitle + KPI scoreboard:
#' chanwe_subtitle(
#'   "Evolución de reservas internacionales brutas.",
#'   kpi = chanwe_kpi(
#'     num    = "45,91",  label  = "USD MM", period = "05·MAY·2026",
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

#' Chanwe Caption Helper
#'
#' Marks a string for the Chanwe caption treatment: [theme_chanwe()] renders
#' captions in JetBrains Mono with an orange `//` prefix and a thin separator
#' line above. Use inside `labs(caption = ...)`. Plain strings passed directly
#' to `labs(caption = )` receive the same treatment; this helper exists to
#' keep call sites explicit and future-proof.
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
#' ## In a plot (assign; print to render with brand fonts):
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
#'   ggplot2::geom_point() +
#'   ggplot2::labs(caption = chanwe_caption("Source: mtcars")) +
#'   theme_chanwe()
chanwe_caption <- function(text) {
  as.character(text)
}

#' Chanwe Discrete Color Scales
#'
#' Apply a Chanwe categorical palette to `color` or `fill` aesthetics.
#' Colors cycle through the chosen palette when there are more categories
#' than palette entries.
#'
#' `scale_color_chanwe_d()` maps to the `colour` aesthetic (points, lines,
#' text). `scale_fill_chanwe_d()` maps to the `fill` aesthetic (bars, areas,
#' ribbons).
#'
#' ## The default chart palette
#'
#' The default `"chart"` palette is the editorial 8-color set in a fixed,
#' CVD-validated slot order (coral, blue, teal, green, violet, magenta,
#' mustard, ink — worst adjacent pair \eqn{\Delta}E 17.5 under
#' protanopia/deuteranopia simulation). Mustard and ink sit in the last two
#' slots deliberately: charts with up to 6 series never reach them.
#' For scatter, bubble, and map charts — where any two series can sit side
#' by side — keep to at most 3 series (the first three slots are validated
#' all-pairs); fold the rest into "Other" or facet.
#'
#' @param palette Palette to draw colors from. Either a group name accepted
#'   by [chanwe_palette()] (default `"chart"`; ramp groups like
#'   `"p15_blue"` or `"mb_orange"` work for ordinal series) or a character
#'   vector of colors to use directly.
#' @param reverse Reverse the palette order. Default `FALSE`.
#' @param ... Additional arguments passed to [ggplot2::discrete_scale()],
#'   e.g. `name`, `labels`, `guide`, `drop`.
#'
#' @return A ggplot2 scale object.
#' @export
#'
#' @examples
#' ## Points colored by group (assign; print to render with brand fonts)
#' p1 <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) +
#'   ggplot2::geom_point(size = 3) +
#'   scale_color_chanwe_d() +
#'   theme_chanwe()
#'
#' ## Ordinal series (small → large): use a one-hue ramp group
#' avg <- aggregate(mpg ~ cyl, data = mtcars, FUN = mean)
#' p2 <- ggplot2::ggplot(avg, ggplot2::aes(factor(cyl), mpg, fill = factor(cyl))) +
#'   ggplot2::geom_col() +
#'   scale_fill_chanwe_d(palette = "p15_blue", reverse = TRUE) +
#'   theme_chanwe(legend_position = "none")
scale_color_chanwe_d <- function(palette = "chart", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "colour",
    palette = chanwe_discrete_pal(palette, reverse),
    ...
  )
}

#' @rdname scale_color_chanwe_d
#' @export
scale_fill_chanwe_d <- function(palette = "chart", reverse = FALSE, ...) {
  ggplot2::discrete_scale(
    aesthetics = "fill",
    palette = chanwe_discrete_pal(palette, reverse),
    ...
  )
}

#' Chanwe Continuous Color Scales
#'
#' Sequential (one hue, light \eqn{\to} dark) Chanwe gradient scales for
#' magnitude encoding. Pick the hue with `palette`; every named ramp is a
#' brand family from [chanwe_palette()].
#'
#' Available palettes: `"orange"` (default — the report primary gradient),
#' `"coral"`, `"blue"`, `"teal"`, `"green"`, `"vermillion"`, `"magenta"`,
#' `"violet"`, `"mustard"`, and `"ink"`. The green and vermillion ramps end
#' in the signed positive/negative tokens so their dark pole stays readable;
#' the brand's yellow and cyan families are deliberately not offered — their
#' entire ramp is too light to encode magnitude on the brand surfaces.
#'
#' For polarity (values diverging around zero) use
#' [scale_color_chanwe_div()] instead.
#'
#' @param palette Name of a sequential ramp (see above), or a character
#'   vector of colors to interpolate directly.
#' @param reverse Reverse the ramp (dark \eqn{\to} light). Default `FALSE`.
#' @param colours Deprecated in favor of `palette`; a character vector of
#'   colors that, when supplied, overrides `palette`.
#' @param ... Additional arguments passed to
#'   [ggplot2::scale_color_gradientn()] / [ggplot2::scale_fill_gradientn()].
#'
#' @return A ggplot2 scale object.
#' @export
#'
#' @examples
#' p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = disp)) +
#'   ggplot2::geom_point(size = 3) +
#'   scale_color_chanwe_c(palette = "teal") +
#'   theme_chanwe()
scale_color_chanwe_c <- function(
  palette = "orange",
  reverse = FALSE,
  colours = NULL,
  ...
) {
  values <- if (!is.null(colours)) colours else chanwe_seq_pal(palette, reverse)
  ggplot2::scale_color_gradientn(colours = values, ...)
}

#' @rdname scale_color_chanwe_c
#' @export
scale_fill_chanwe_c <- function(
  palette = "orange",
  reverse = FALSE,
  colours = NULL,
  ...
) {
  values <- if (!is.null(colours)) colours else chanwe_seq_pal(palette, reverse)
  ggplot2::scale_fill_gradientn(colours = values, ...)
}

#' Chanwe Diverging Color Scales
#'
#' Diverging gradient for values with a meaningful zero or baseline:
#' negative pole in the brand vermillion (alert) family, positive pole in
#' the brand green (positive) family, neutral gray midpoint. The poles are
#' the canonical signed tokens (`chanwe_palette("signed")`), so charts,
#' table deltas ([chanwe_col_signed()]), and KPI arrows all share one pair.
#'
#' The midpoint maps to the *middle of the data range*, so give the scale
#' symmetric limits when zero is the baseline, e.g.
#' `limits = c(-max(abs(x)), max(abs(x)))` — otherwise zero drifts off the
#' neutral gray.
#'
#' ## Color-vision deficiency
#'
#' Red↔green is the classic deuteranopia trap. When the audience includes
#' red-green CVD readers, pass `cvd = TRUE`: the positive arm switches to
#' the brand's structural blue family (pole = the report info blue) while
#' the negative arm stays vermillion, so polarity survives simulation and
#' both arms remain brand families.
#'
#' @param reverse Flip the scale (positive pole on the low end).
#'   Default `FALSE`.
#' @param cvd Use the CVD-safe vermillion↔blue variant instead of
#'   vermillion↔green. Default `FALSE`.
#' @param ... Additional arguments passed to
#'   [ggplot2::scale_color_gradientn()] / [ggplot2::scale_fill_gradientn()],
#'   e.g. `limits`, `name`, `na.value`.
#'
#' @return A ggplot2 scale object.
#' @seealso [chanwe_col_signed()] for the same mapping in Typst tables,
#'   [scale_color_chanwe_c()] for plain magnitude.
#' @export
#'
#' @examples
#' df <- data.frame(x = 1:10, y = 1, delta = seq(-3, 3, length.out = 10))
#' m <- max(abs(df$delta))
#' p <- ggplot2::ggplot(df, ggplot2::aes(x, y, fill = delta)) +
#'   ggplot2::geom_tile() +
#'   scale_fill_chanwe_div(limits = c(-m, m)) +
#'   theme_chanwe()
scale_color_chanwe_div <- function(reverse = FALSE, cvd = FALSE, ...) {
  values <- .chanwe_div_ramp(cvd = cvd)
  if (isTRUE(reverse)) values <- rev(values)
  ggplot2::scale_color_gradientn(colours = values, ...)
}

#' @rdname scale_color_chanwe_div
#' @export
scale_fill_chanwe_div <- function(reverse = FALSE, cvd = FALSE, ...) {
  values <- .chanwe_div_ramp(cvd = cvd)
  if (isTRUE(reverse)) values <- rev(values)
  ggplot2::scale_fill_gradientn(colours = values, ...)
}
