# Brand color tokens -------------------------------------------------------

# Every colour comes from `chanwe_tokens` (R/brand-tokens.R), which
# chanwe-brandbook generates from brand/tokens/tokens.json and syncs here
# (`brand:sync`). Never edit that file or write a hex in this package: read a
# token with .cw_tk(), or build a tint from one with .cw_mix() / .cw_alpha().
# tests/testthat/test-token-drift.R fails on any string literal hex that is
# not a token.

# One token by name, from the light colours, then the plot group.
.cw_tk <- function(name) {
  value <- chanwe_tokens$colors[[name]]
  if (is.null(value)) {
    stop(sprintf("`%s` is not a colour in chanwe_tokens.", name), call. = FALSE)
  }
  value
}

# A token as a named character vector (the brand group, as before 3.0.0).
.chanwe_brand_colors <- unlist(chanwe_tokens$colors)

# Mix `col` with `with` by `t` (0 = col, 1 = with), as an uppercase hex.
.cw_mix <- function(col, with, t) {
  a <- grDevices::col2rgb(col)
  b <- grDevices::col2rgb(with)
  toupper(grDevices::rgb(t(a * (1 - t) + b * t), maxColorValue = 255))
}

# A token at an opacity, as #RRGGBBAA: the v2 tint is the text colour at 7%
# (brand-v2.md §6), the plot grid ink-fg at 25% (`plot.grid`).
.cw_alpha <- function(col, alpha) {
  rgb <- grDevices::col2rgb(substr(col, 1L, 7L))
  toupper(grDevices::rgb(
    rgb[1], rgb[2], rgb[3], round(alpha * 255), maxColorValue = 255
  ))
}

# The legacy chanwer ramps (p13, p14, p15, mb) predate the token system:
# their anchors were the retired orange #E94B2B, the retired black #101010
# and hues outside the palette. Since 2.6.0 every one is rebuilt from a
# brand token, keeping its name, its length and its light -> dark steps.
.cw_tints <- function(name, token, steps) {
  stats::setNames(
    vapply(steps, function(t) .cw_mix(token, .cw_tk("pure-white"), t), character(1)),
    sprintf("%s-%02d", name, seq_along(steps))
  )
}

# A 5-shade p15 family: the token (01) to a light pole (05) in four even
# steps. The pole is the token's own soft partner when the palette has one,
# otherwise a 75% tint.
.cw_p15 <- function(family, token, light = NULL) {
  from <- .cw_tk(token)
  to <- if (is.null(light)) .cw_mix(from, .cw_tk("pure-white"), 0.75) else .cw_tk(light)
  stats::setNames(
    vapply(0:4 / 4, function(t) .cw_mix(from, to, t), character(1)),
    sprintf("p15-%s-%02d", family, 1:5)
  )
}

# p13: ten steps from the token toward white, the steps the old ramps used.
.cw_p13_orange <- .cw_tints(
  "p13-orange", .cw_tk("primary"),
  c(0, 0.08, 0.16, 0.24, 0.32, 0.40, 0.48, 0.64, 0.72, 0.80)
)
.cw_p13_gray <- .cw_tints(
  "p13-gray", .cw_tk("ink"),
  c(0, 0.08, 0.16, 0.24, 0.32, 0.40, 0.56, 0.64, 0.72, 0.80)
)

# The plot group of tokens.json (brand-v2 Q3 / C1): the focus colour, the
# slate ramp for every other series (dark -> light) and the categorical
# order for charts with no focus series.
.chanwe_slate_colors <- stats::setNames(
  chanwe_tokens$plot$slate,
  paste0("slate-", seq_along(chanwe_tokens$plot$slate))
)

.chanwe_colors <- c(
  .chanwe_brand_colors,
  # Signed tokens - the canonical positive/negative/neutral for KPI arrows,
  # table deltas, and diverging-scale poles. Positive and negative are the
  # brand's kpi-green / kpi-red, which clear WCAG 4.5:1 small-text contrast
  # on every brand surface (the raw status-success tops out at 2.7:1);
  # neutral is the slate fg-muted.
  "signed-positive" = .cw_tk("kpi-green"),
  "signed-negative" = .cw_tk("kpi-red"),
  "signed-neutral"  = .cw_tk("fg-muted"),
  # The v2 plot tokens
  "plot-focus" = chanwe_tokens$plot$focus,
  "plot-grid" = chanwe_tokens$plot$grid,
  "plot-axis-text" = chanwe_tokens$plot$`axis-text`,
  "plot-title" = chanwe_tokens$plot$title,
  "plot-background" = chanwe_tokens$plot$background,
  # The v2 tint (brand-v2.md §6): the text colour at 7%, for table headers,
  # hover and grouping inside a pane.
  "tint" = .cw_alpha(.cw_tk("ink"), 0.07),
  .chanwe_slate_colors,
  # Legacy chanwer names, resolved to the brand tokens per the v1 -> v2
  # migration in _extensions/chanwe-brand/assets/COLORS.md.
  "brand-orange" = .cw_tk("primary"),
  "brand-black" = .cw_tk("ink"),
  "brand-white" = .cw_tk("paper"),
  "brand-pure-white" = .cw_tk("pure-white"),
  "brand-gray" = .cw_tk("chart-gray"),
  "brand-silver" = .cw_tk("neutral-300"),
  .cw_p13_orange,
  .cw_p13_gray,
  # p14 - strong/soft pairs: the palette's status and neon pairs
  "p14-yellow-strong" = .cw_tk("status-warning"),
  "p14-yellow-soft" = .cw_tk("status-warning-bg"),
  "p14-cyan-strong" = .cw_tk("chart-cyan"),
  "p14-cyan-soft" = .cw_tk("chart-cyan-soft"),
  "p14-blue-strong" = .cw_tk("status-info"),
  "p14-blue-soft" = .cw_tk("status-info-bg"),
  "p14-magenta-strong" = .cw_tk("chart-magenta"),
  "p14-magenta-soft" = .cw_mix(.cw_tk("chart-magenta"), .cw_tk("pure-white"), 0.75),
  "p14-green-strong" = .cw_tk("status-success"),
  "p14-green-soft" = .cw_tk("status-success-soft"),
  "p14-red-strong" = .cw_tk("status-error"),
  "p14-red-soft" = .cw_tk("status-error-bg"),
  # p15 - full 5-shade ramps (dark -> light) for 11 families, each anchored
  # on a brand token
  .cw_p15("coral", "primary"),
  .cw_p15("vermillion", "chart-red"),
  .cw_p15("green", "status-success", "status-success-soft"),
  .cw_p15("magenta", "chart-magenta"),
  .cw_p15("blue", "status-info", "status-info-bg"),
  .cw_p15("yellow", "status-warning", "status-warning-bg"),
  .cw_p15("cyan", "chart-cyan", "chart-cyan-soft"),
  .cw_p15("mustard", "exec-status-regular"),
  .cw_p15("violet", "violet", "violet-soft"),
  .cw_p15("teal", "chart-teal"),
  .cw_p15("ink", "ink"),
  # mb - main brand palette (orange . dark, 100-950 scale): the p13 ramps
  # read light -> dark
  stats::setNames(
    rev(unname(.cw_p13_orange)),
    paste0("mb-orange-", c(100, 200, 300, 400, 500, 600, 700, 800, 900, 950))
  ),
  stats::setNames(
    rev(unname(.cw_p13_gray)),
    paste0("mb-dark-", c(100, 200, 300, 400, 500, 600, 700, 800, 900, 950))
  ),
  # chanwe-report-typst token names used across the helpers, resolved to
  # their brand.yml roles (one orange: primary-text is primary).
  "typst-primary"      = .cw_tk("primary"),
  "typst-primary-text" = .cw_tk("primary-text"),
  "typst-ink"          = .cw_tk("ink"),
  "typst-fg"           = .cw_tk("fg"),
  "typst-fg-muted"     = .cw_tk("fg-muted"),
  "typst-fg-subtle"    = .cw_tk("fg-subtle"),
  "typst-neutral-100"  = .cw_tk("surface-sunken"),
  "typst-neutral-200"  = .cw_tk("rule"),
  "typst-neutral-300"  = .cw_tk("neutral-300"),
  "typst-neutral-700"  = .cw_tk("neutral-700"),
  "typst-neutral-900"  = .cw_tk("ink"),
  "typst-white"        = .cw_tk("pure-white"),
  "typst-green"        = .cw_tk("callout-do"),
  "typst-red"          = .cw_tk("callout-dont"),
  "typst-warning"      = .cw_tk("callout-warning"),
  "typst-info"         = .cw_tk("callout-note"),
  "typst-tip"          = .cw_tk("callout-tip"),
  "typst-caution"      = .cw_tk("callout-caution")
)

.chanwe_semantic_names <- c(
  foreground = "fg-muted",
  background = "paper",
  primary    = "primary",
  secondary  = "fg",
  success    = "status-success",
  warning    = "status-warning",
  danger     = "status-error",
  info       = "status-info",
  positive   = "signed-positive",
  negative   = "signed-negative",
  neutral    = "signed-neutral"
)

# Categorical chart palette - tokens.json `plot.categorical`, for charts
# with no focus series (rule C1). Each hue is named by its colour token.
.chanwe_chart_colors <- local({
  hexes <- chanwe_tokens$plot$categorical
  pool <- .chanwe_brand_colors[c(
    "primary", "chart-blue", "chart-teal", "chart-indigo", "chart-purple",
    "chart-green", "chart-orange", "chart-red"
  )]
  stats::setNames(hexes, names(pool)[match(toupper(hexes), toupper(pool))])
})

.chanwe_chart_names <- names(.chanwe_chart_colors)

# A sequential ramp as a named palette group, light -> dark: `blue-1` ...
.chanwe_named_ramp <- function(name) {
  values <- .chanwe_seq_ramps()[[name]]
  stats::setNames(values, paste0(name, "-", seq_along(values)))
}

.chanwe_palette_groups <- function() {
  list(
    core = .chanwe_colors[c(
      "brand-orange", "brand-black", "brand-white", "brand-pure-white",
      "brand-gray", "brand-silver"
    )],
    brand = .chanwe_brand_colors,
    p13_orange = .chanwe_colors[grep("^p13-orange", names(.chanwe_colors))],
    p13_gray = .chanwe_colors[grep("^p13-gray", names(.chanwe_colors))],
    p14_accents = .chanwe_colors[grep("^p14", names(.chanwe_colors))],
    p15_coral = .chanwe_colors[grep("^p15-coral", names(.chanwe_colors))],
    p15_vermillion = .chanwe_colors[grep("^p15-vermillion", names(.chanwe_colors))],
    p15_green = .chanwe_colors[grep("^p15-green", names(.chanwe_colors))],
    p15_magenta = .chanwe_colors[grep("^p15-magenta", names(.chanwe_colors))],
    p15_blue = .chanwe_colors[grep("^p15-blue", names(.chanwe_colors))],
    p15_yellow = .chanwe_colors[grep("^p15-yellow", names(.chanwe_colors))],
    p15_cyan = .chanwe_colors[grep("^p15-cyan", names(.chanwe_colors))],
    p15_mustard = .chanwe_colors[grep("^p15-mustard", names(.chanwe_colors))],
    p15_violet = .chanwe_colors[grep("^p15-violet", names(.chanwe_colors))],
    p15_teal = .chanwe_colors[grep("^p15-teal", names(.chanwe_colors))],
    p15_ink = .chanwe_colors[grep("^p15-ink", names(.chanwe_colors))],
    mb_orange = .chanwe_colors[grep("^mb-orange", names(.chanwe_colors))],
    mb_dark   = .chanwe_colors[grep("^mb-dark",   names(.chanwe_colors))],
    ramp_blue   = .chanwe_named_ramp("blue"),
    ramp_indigo = .chanwe_named_ramp("indigo"),
    ramp_teal   = .chanwe_named_ramp("teal"),
    ramp_green  = .chanwe_named_ramp("green"),
    ramp_amber  = .chanwe_named_ramp("amber"),
    ramp_red    = .chanwe_named_ramp("red"),
    ramp_purple = .chanwe_named_ramp("purple"),
    semantic = chanwe_get_semantic(),
    signed = chanwe_get_signed(),
    chart = .chanwe_chart_colors,
    slate = .chanwe_slate_colors,
    focus = c("plot-focus" = chanwe_tokens$plot$focus, .chanwe_slate_colors)
  )
}

chanwe_get_colors <- function() {
  .chanwe_colors
}

chanwe_get_semantic <- function() {
  stats::setNames(
    .chanwe_colors[unname(.chanwe_semantic_names)],
    names(.chanwe_semantic_names)
  )
}

chanwe_get_chart <- function() {
  .chanwe_chart_colors
}

chanwe_get_signed <- function() {
  c(
    positive = .chanwe_colors[["signed-positive"]],
    negative = .chanwe_colors[["signed-negative"]],
    neutral  = .chanwe_colors[["signed-neutral"]]
  )
}

# Sequential ramps for the continuous scales - light -> dark, one series hue
# each: two tints of the hue toward white, the hue itself, and a dark pole
# (the hue stepped toward ink) so the strong end clears 3:1 mark contrast on
# the light brand surfaces. Green and red end in the signed tokens instead,
# so magnitude and valence share one pole. The light pole stops at a 65%
# tint: lighter shades all but vanish on the brand surfaces, so
# minimum-value marks would carry data invisibly. "orange" is the historical
# default gradient anchored on the report primary; "mustard" and "ink" keep
# their p15 ramps (no series hue replaces them). `vermillion` and `violet`
# are the earlier names of `red` and `purple`.
.chanwe_seq_ramps <- function() {
  cols <- .chanwe_colors
  hue_ramp <- function(key, dark = NULL) {
    h <- cols[[key]]
    c(
      .cw_mix(h, "#FFFFFF", 0.65),
      .cw_mix(h, "#FFFFFF", 0.35),
      h,
      if (is.null(dark)) .cw_mix(h, cols[["ink"]], 0.35) else dark
    )
  }
  p15 <- function(prefix) {
    shades <- rev(unname(cols[grep(paste0("^", prefix), names(cols))]))
    shades[-1] # clamp the light pole: drop the -05 shade
  }
  red <- hue_ramp("chart-red", dark = cols[["signed-negative"]])
  purple <- hue_ramp("chart-purple")
  list(
    orange     = unname(cols[c("p13-orange-07", "p13-orange-03", "primary")]),
    blue       = hue_ramp("chart-blue"),
    indigo     = hue_ramp("chart-indigo"),
    teal       = hue_ramp("chart-teal"),
    green      = hue_ramp("chart-green", dark = cols[["signed-positive"]]),
    amber      = hue_ramp("chart-orange"),
    red        = red,
    vermillion = red,
    purple     = purple,
    violet     = purple,
    mustard    = p15("p15-mustard"),
    ink        = p15("p15-ink")
  )
}

# Diverging ramp: negative (red arm) -> neutral midpoint -> positive (green
# arm), built from the series hues. Poles are the signed tokens; each arm
# runs pole -> hue -> 40% tint -> 70% tint, so lightness is monotone from the
# `rule` midpoint out to each pole.
#
# cvd = TRUE swaps the positive arm for chart-blue. Red<->green is the
# canonical deuteranopia trap; when the audience includes red-green CVD
# readers, the red<->blue variant keeps polarity legible.
.chanwe_div_ramp <- function(cvd = FALSE) {
  cols <- .chanwe_colors
  arm <- function(key) {
    h <- cols[[key]]
    c(.cw_mix(h, "#FFFFFF", 0.7), .cw_mix(h, "#FFFFFF", 0.4), h)
  }
  positive_arm <- if (isTRUE(cvd)) {
    c(arm("chart-blue"), .cw_mix(cols[["chart-blue"]], cols[["ink"]], 0.35))
  } else {
    c(arm("chart-green"), cols[["signed-positive"]])
  }
  unname(c(
    cols[["signed-negative"]],
    rev(arm("chart-red")),
    cols[["rule"]],
    positive_arm
  ))
}

#' Chanwe Color Palette Tokens
#'
#' Returns Chanwe brand colors as a single named vector, grouped vectors,
#' or specific palette subsets used by plotting and reporting helpers.
#'
#' @param palette Optional palette selector. Use `NULL` (default) to return
#'   all colors and grouped palettes. Supported names are `"all"`, `"core"`,
#'   `"brand"` (every colour of chanwe-brandbook `tokens.json`, read from the
#'   generated `chanwe_tokens`),
#'   `"p13_orange"`, `"p13_gray"`, `"p14_accents"`, `"p15_coral"`,
#'   `"p15_vermillion"`, `"p15_green"`, `"p15_magenta"`, `"p15_blue"`,
#'   `"p15_yellow"`, `"p15_cyan"`, `"p15_mustard"`, `"p15_violet"`,
#'   `"p15_teal"`, `"p15_ink"`, `"mb_orange"`, `"mb_dark"`, the series-hue
#'   ramps `"ramp_blue"`, `"ramp_indigo"`, `"ramp_teal"`, `"ramp_green"`,
#'   `"ramp_amber"`, `"ramp_red"`, `"ramp_purple"`,
#'   `"semantic"`, `"signed"`, `"chart"` (the categorical order of
#'   `tokens.json` `plot.categorical`, for charts with no focus series),
#'   `"slate"` (the `plot.slate` ramp, dark to light, for the series that are
#'   not the focus) and `"focus"` (the focus orange followed by the slate
#'   ramp).
#'
#' @section The focus rule (v2):
#' Orange is the one signal: the series that matters takes `plot.focus`
#' (`#FD3810`) and every other series sits on the slate ramp. Use
#' [scale_color_chanwe_focus()] / [scale_fill_chanwe_focus()] for that; keep
#' the categorical `"chart"` palette for charts where no series is the focus.
#'
#' @section Signed colors:
#' The `"signed"` group carries the canonical positive / negative / neutral
#' colors, derived from the brand families the manual designates for those
#' roles (green = positive, vermillion = alert, ink = neutral) and darkened
#' until they pass WCAG 4.5:1 small-text contrast on every brand surface.
#' They are used by the KPI scoreboard arrows ([chanwe_kpi()]), the table
#' helper [chanwe_col_signed()], and the poles of
#' [scale_color_chanwe_div()]. Use them for any "went up / went down"
#' encoding so the same pair appears in charts, tables, and reports.
#'
#' @section Legacy ramps:
#' The `p13_*`, `p14_accents`, `p15_*` and `mb_*` groups predate the brand
#' token system. Since chanwer 2.6.0 each keeps its name and length but is
#' rebuilt from a brand token: the orange ramps from `primary` (the retired
#' `#E94B2B` is gone), the gray ramps from `ink` (not the retired `#101010`),
#' the p14 pairs from the palette's status and neon pairs, and each p15
#' family from one token stepped toward its soft partner or a 75% tint
#' (coral = `primary`, vermillion = `chart-red`, green = `status-success`,
#' magenta = `chart-magenta`, blue = `status-info`, yellow =
#' `status-warning`, cyan = `chart-cyan`, mustard = `exec-status-regular`,
#' violet = `violet`, teal = `chart-teal`, ink = `ink`). For new charts
#' prefer `"chart"` and the `ramp_*` groups.
#'
#' @return If `palette = NULL`, a list containing `all` and `groups`.
#'   Otherwise, a named character vector of hex colors.
#' @export
#'
#' @examples
#' chanwe_palette()
#' chanwe_palette("chart")
chanwe_palette <- function(palette = NULL) {
  groups <- .chanwe_palette_groups()

  if (is.null(palette)) {
    return(list(all = .chanwe_colors, groups = groups))
  }

  valid <- c("all", names(groups))
  if (!palette %in% valid) {
    stop(
      "`palette` must be one of: ",
      paste(sprintf("'%s'", valid), collapse = ", "),
      call. = FALSE
    )
  }

  if (identical(palette, "all")) {
    .chanwe_colors
  } else {
    groups[[palette]]
  }
}

#' Chanwe Brand Tokens
#'
#' Returns structured brand tokens used across theme helpers and Quarto
#' reporting components.
#'
#' @return A list with color, typography, geometry, plot and reporting token
#'   blocks. Values come from the generated `chanwe_tokens`
#'   (chanwe-brandbook `tokens.json`).
#' @export
#'
#' @examples
#' chanwe_brand_tokens()
chanwe_brand_tokens <- function() {
  semantic <- chanwe_get_semantic()

  list(
    name = "Chanwe",
    colors = chanwe_get_colors(),
    semantic = semantic,
    chart_order = chanwe_get_chart(),
    # tokens.json `font`: Satoshi for text, Schibsted Grotesk for titles and
    # display, JetBrains Mono for eyebrows, labels and metadata; Cormorant
    # Garamond only for editorial italics and numerals. Inter is retired.
    typography = list(
      family = chanwe_tokens$fonts$body,
      display_family = chanwe_tokens$fonts$display,
      mono_family = chanwe_tokens$fonts$mono,
      serif_family = "Cormorant Garamond",
      base_size = chanwe_tokens$type$body,
      base_line_height = 1.62,
      heading_weight = 600,
      heading_line_height = 1.15,
      link_weight = 500,
      # the v2 type scale in px (label 10 ... display 48)
      scale = unlist(chanwe_tokens$type)
    ),
    # v2 shapes (tokens.json `radius`, brand-v2.md §3): rows 8px, dense
    # panes 12px, panes on a page 16px, every control a 999px pill.
    geometry = list(
      radius_small = chanwe_tokens$radii$row,
      radius_base = chanwe_tokens$radii$pane,
      radius_large = chanwe_tokens$radii$surface,
      radius_pill = chanwe_tokens$radii$pill,
      radii = unlist(chanwe_tokens$radii),
      space = unlist(chanwe_tokens$space),
      control = unlist(chanwe_tokens$control),
      shadow = "none"
    ),
    # tokens.json `plot` (brand-v2 Q3): focus, slate ramp, categorical,
    # grid, axis text, line width, point size and bar radius.
    plot = chanwe_tokens$plot,
    reporting = list(
      code_background = semantic[["background"]],
      code_left_rule = semantic[["primary"]],
      # Captions are small text that is read: pizarra, not fg-subtle (the
      # guide keeps fg-subtle for large or decorative text).
      caption_color = chanwe_get_colors()[["fg-muted"]],
      # brand.yml `callout-*` accents
      callouts = c(
        note = chanwe_get_colors()[["callout-note"]],
        info = chanwe_get_colors()[["callout-note"]],
        tip = chanwe_get_colors()[["callout-tip"]],
        success = chanwe_get_colors()[["callout-do"]],
        warning = chanwe_get_colors()[["callout-warning"]],
        important = chanwe_get_colors()[["callout-important"]],
        caution = chanwe_get_colors()[["callout-caution"]],
        alert = chanwe_get_colors()[["callout-dont"]]
      ),
      section_marker_asset = system.file(
        "assets",
        "Estrategia_Color1.png",
        package = "chanwer"
      )
    )
  )
}

#' Preview Chanwe Palette
#'
#' Draws a swatch grid of Chanwe colors using ggplot2. The grid title names
#' the previewed group so rendered previews stay self-describing.
#'
#' @param palette Palette selector accepted by `chanwe_palette()`.
#'
#' @return A ggplot object.
#' @export
#'
#' @examples
#' p <- chanwe_preview_palette("chart")
chanwe_preview_palette <- function(palette = "all") {
  chanwe_load_fonts()
  values <- chanwe_palette(palette)

  if (is.list(values)) {
    values <- values$all
  }

  title_label <- paste0(
    "Chanwe palette \u00b7 ",
    if (is.null(palette)) "all" else palette
  )

  n <- length(values)
  ncol <- if (n <= 12) 4 else 5

  df <- data.frame(
    name = names(values),
    value = unname(values),
    idx = seq_len(n),
    stringsAsFactors = FALSE
  )

  df$col <- (df$idx - 1L) %% ncol + 1L
  df$row <- ceiling(df$idx / ncol)
  df$label <- paste0(df$name, "\n", toupper(df$value))
  # white labels on dark tiles, ink on light ones (perceived luminance)
  rgb <- grDevices::col2rgb(df$value) / 255
  luminance <- 0.299 * rgb[1, ] + 0.587 * rgb[2, ] + 0.114 * rgb[3, ]
  df$label_col <- ifelse(
    luminance < 0.45,
    chanwe_get_colors()[["pure-white"]],
    chanwe_get_colors()[["ink"]]
  )

  ggplot2::ggplot(df, ggplot2::aes(x = col, y = -row)) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = value),
      color = chanwe_get_colors()[["pure-white"]],
      linewidth = 0.8,
      width = 0.95,
      height = 0.95
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = label, color = label_col),
      # token names and hex codes are labels: JetBrains Mono
      family = "JetBrains Mono",
      size = 2.6,
      lineheight = 1.1,
      fontface = "bold"
    ) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_identity() +
    ggplot2::theme_void(base_family = "Satoshi") +
    ggplot2::labs(title = title_label) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        family = "Schibsted Grotesk SemiBold",
        hjust = 0,
        size = 14,
        face = "plain",
        color = chanwe_get_colors()[["ink"]]
      ),
      plot.background = ggplot2::element_rect(
        fill = chanwe_get_colors()[["paper"]],
        color = NA
      )
    )
}
