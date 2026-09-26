# Brand color tokens -------------------------------------------------------

# Mirror of `color.palette` in _extensions/chanwe-brand/brand.yml - the
# source of truth. brand.yml is not installed with the package, so the values
# are copied by hand: edit brand.yml in chanwe-brand first, sync the
# extension, then update this table. Aliases (`primary-text`,
# `primary-active` -> `primary`) are resolved to their hex.
.chanwe_brand_colors <- c(
  # The accent: one orange
  "primary"          = "#FD3810",
  "primary-text"     = "#FD3810",
  "primary-active"   = "#FD3810",
  # Obsidian and what sits on it
  "ink"              = "#111319",
  "ink-soft"         = "#37393F",
  "ink-fg"           = "#64748B",
  "ink-subtle"       = "#646464",
  "rule-ink"         = "#434D5D",
  # Type
  "fg"               = "#111319",
  "body-fg"          = "#475569",
  "fg-muted"         = "#475569",
  "fg-subtle"        = "#8A94A6",
  "emphasis"         = "#484848",
  # The series hues (Apple-HIG-calibrated): the chart series and the
  # callout roles share them; `primary` is the eighth member.
  "chart-blue"       = "#007AFF",
  "chart-green"      = "#34C759",
  "chart-indigo"     = "#5856D6",
  "chart-orange"     = "#FF9500",
  "chart-red"        = "#FF3B30",
  "chart-teal"       = "#00C7BE",
  "chart-purple"     = "#AF52DE",
  # Paper and slate surfaces
  "paper"            = "#F8FAFC",
  "callout-surface"  = "#F8FAFC",
  "surface-sunken"   = "#F1F5F9",
  "surface-slate"    = "#EBF0F6",
  "callout-header"   = "#EBF0F6",
  "pure-white"       = "#FFFFFF",
  "pure-black"       = "#000000",
  # Hairlines
  "rule"             = "#E2E8F0",
  "rule-cool"        = "#C6CDD6",
  "border-cool"      = "#CFD6DF",
  "border"           = "#1113191A",
  "neutral-300"      = "#D4D4D4",
  "neutral-700"      = "#525252",
  # Callouts - every one a series hue
  "callout-note"      = "#007AFF", # chart-blue
  "callout-tip"       = "#00C7BE", # chart-teal
  "callout-warning"   = "#FF9500", # chart-orange
  "callout-important" = "#FD3810", # primary
  "callout-caution"   = "#AF52DE", # chart-purple
  "callout-do"        = "#34C759", # chart-green
  "callout-dont"      = "#FF3B30", # chart-red
  # Report semaphores
  "research-muted"      = "#99999E",
  "kpi-green"           = "#147705",
  "kpi-red"             = "#CC1914",
  "exec-status-good"    = "#15803D",
  "exec-status-regular" = "#D97706",
  "exec-status-bad"     = "#CC1914",
  # Code highlighting
  "code-keyword"     = "#FD3810",
  "code-string"      = "#15803D",
  "code-number"      = "#7C3AED",
  "code-operator"    = "#0758E5",
  "code-function"    = "#475569",
  "code-type"        = "#353535",
  "code-comment"     = "#928D86",
  # HTML statuses (semantic chrome, not series colours) and the legacy
  # chart accents - cyan, magenta and gray are no longer in the series
  "status-success"      = "#1EB508",
  "status-success-soft" = "#C9FFC0",
  "status-error"        = "#D32F2F",
  "status-error-bg"     = "#FDECEA",
  "status-warning"      = "#F9E710",
  "status-warning-bg"   = "#FFF8B8",
  "status-info"         = "#0C48ED",
  "status-info-bg"      = "#B8CEFF",
  "chart-cyan"          = "#11F7E6",
  "chart-cyan-soft"     = "#B6FFF8",
  "chart-magenta"       = "#EB03F2",
  "chart-gray"          = "#71706C"
)

.chanwe_colors <- c(
  .chanwe_brand_colors,
  # Signed tokens - the canonical positive/negative/neutral for KPI arrows,
  # table deltas, and diverging-scale poles. Positive and negative are the
  # brand's kpi-green / kpi-red, which clear WCAG 4.5:1 small-text contrast
  # on every brand surface (the raw status-success #1EB508 tops out at
  # 2.7:1); neutral is the slate fg-muted.
  "signed-positive" = "#147705",
  "signed-negative" = "#CC1914",
  "signed-neutral"  = "#475569",
  # Legacy chanwer names, resolved to brand.yml per the v1 -> v2 migration
  # in _extensions/chanwe-brand/assets/COLORS.md.
  "brand-orange" = "#FD3810",     # primary
  "brand-black" = "#111319",      # ink
  "brand-white" = "#F8FAFC",      # paper
  "brand-pure-white" = "#FFFFFF", # pure-white
  "brand-gray" = "#71706C",       # chart-gray
  "brand-silver" = "#D4D4D4",     # neutral-300
  "p13-orange-01" = "#E94B2B",
  "p13-orange-02" = "#EA5A3C",
  "p13-orange-03" = "#EC684E",
  "p13-orange-04" = "#ED775F",
  "p13-orange-05" = "#EF8670",
  "p13-orange-06" = "#F09482",
  "p13-orange-07" = "#F2A393",
  "p13-orange-08" = "#F5C0B6",
  "p13-orange-09" = "#F6CFC7",
  "p13-orange-10" = "#F8DDD9",
  "p13-gray-01" = "#101010",
  "p13-gray-02" = "#232323",
  "p13-gray-03" = "#353535",
  "p13-gray-04" = "#484848",
  "p13-gray-05" = "#5B5B5B",
  "p13-gray-06" = "#6D6D6D",
  "p13-gray-07" = "#929292",
  "p13-gray-08" = "#A5A5A5",
  "p13-gray-09" = "#B8B8B8",
  "p13-gray-10" = "#CACACA",
  "p14-yellow-strong" = "#F9E710",
  "p14-yellow-soft" = "#FFF8B8",
  "p14-cyan-strong" = "#11F7E6",
  "p14-cyan-soft" = "#B6FFF8",
  "p14-blue-strong" = "#0C48ED",
  "p14-blue-soft" = "#B8CEFF",
  "p14-magenta-strong" = "#EB03F2",
  "p14-magenta-soft" = "#FDCFFF",
  "p14-green-strong" = "#1EB508",
  "p14-green-soft" = "#C9FFC0",
  "p14-red-strong" = "#F40C0C",
  "p14-red-soft" = "#F9A7A7",
  # p15 - full 5-shade ramps (dark -> light) for 11 semantic families
  "p15-coral-01" = "#EE5524", "p15-coral-02" = "#F37548",
  "p15-coral-03" = "#F79676", "p15-coral-04" = "#FBB89F",
  "p15-coral-05" = "#FDD9C8",
  "p15-vermillion-01" = "#F40C0C", "p15-vermillion-02" = "#F53333",
  "p15-vermillion-03" = "#F75A5A", "p15-vermillion-04" = "#F88080",
  "p15-vermillion-05" = "#F9A7A7",
  "p15-green-01" = "#1EB508", "p15-green-02" = "#49C836",
  "p15-green-03" = "#74DA64", "p15-green-04" = "#9EED92",
  "p15-green-05" = "#C9FFC0",
  "p15-magenta-01" = "#EB03F2", "p15-magenta-02" = "#F036F5",
  "p15-magenta-03" = "#F469F9", "p15-magenta-04" = "#F99CFC",
  "p15-magenta-05" = "#FDCFFF",
  "p15-blue-01" = "#0C48ED", "p15-blue-02" = "#376AF2",
  "p15-blue-03" = "#628BF6", "p15-blue-04" = "#8DADFB",
  "p15-blue-05" = "#B8CEFF",
  "p15-yellow-01" = "#F9E710", "p15-yellow-02" = "#FBEB3A",
  "p15-yellow-03" = "#FCF064", "p15-yellow-04" = "#FEF48E",
  "p15-yellow-05" = "#FFF8B8",
  "p15-cyan-01" = "#11F7E6", "p15-cyan-02" = "#3AF9EB",
  "p15-cyan-03" = "#64FBEF", "p15-cyan-04" = "#8DFDF3",
  "p15-cyan-05" = "#B6FFF8",
  "p15-mustard-01" = "#E8B400", "p15-mustard-02" = "#F0C32A",
  "p15-mustard-03" = "#F6D255", "p15-mustard-04" = "#F8DD86",
  "p15-mustard-05" = "#F8E7B6",
  "p15-violet-01" = "#9B2E8F", "p15-violet-02" = "#B549AA",
  "p15-violet-03" = "#C775BD", "p15-violet-04" = "#D7A2D2",
  "p15-violet-05" = "#E5C9E0",
  "p15-teal-01" = "#14A4B8", "p15-teal-02" = "#2BBED2",
  "p15-teal-03" = "#5BCDDC", "p15-teal-04" = "#8AD9E5",
  "p15-teal-05" = "#B8E7EE",
  "p15-ink-01" = "#141414", "p15-ink-02" = "#3D3D3D",
  "p15-ink-03" = "#666666", "p15-ink-04" = "#8F8F8F",
  "p15-ink-05" = "#B8B8B8",
  # mb - main brand palette (orange . dark, 100-950 scale)
  "mb-orange-100" = "#F8DDD9", "mb-orange-200" = "#F6CFC7",
  "mb-orange-300" = "#F5C0B6", "mb-orange-400" = "#F2A393",
  "mb-orange-500" = "#F09482", "mb-orange-600" = "#EF8670",
  "mb-orange-700" = "#ED775F", "mb-orange-800" = "#EC684E",
  "mb-orange-900" = "#EA5A3C", "mb-orange-950" = "#E94B2B",
  "mb-dark-100" = "#CACACA", "mb-dark-200" = "#B8B8B8",
  "mb-dark-300" = "#A5A5A5", "mb-dark-400" = "#929292",
  "mb-dark-500" = "#6D6D6D", "mb-dark-600" = "#5B5B5B",
  "mb-dark-700" = "#484848", "mb-dark-800" = "#353535",
  "mb-dark-900" = "#232323", "mb-dark-950" = "#101010",
  # chanwe-report-typst token names used across the helpers, resolved to
  # their brand.yml roles.
  "typst-primary"      = "#FD3810", # primary
  # brand.yml retired the darker text orange (#C52C0C): one orange, so the
  # small-text accent is primary itself.
  "typst-primary-text" = "#FD3810", # primary-text -> primary
  "typst-ink"          = "#111319", # ink
  "typst-fg"           = "#111319", # fg
  "typst-fg-muted"     = "#475569", # fg-muted
  "typst-fg-subtle"    = "#8A94A6", # fg-subtle
  "typst-neutral-100"  = "#F1F5F9", # surface-sunken
  "typst-neutral-200"  = "#E2E8F0", # rule
  "typst-neutral-300"  = "#D4D4D4", # neutral-300
  "typst-neutral-700"  = "#525252", # neutral-700
  "typst-neutral-900"  = "#111319", # ink
  "typst-white"        = "#FFFFFF", # pure-white
  "typst-green"        = "#34C759", # callout-do
  "typst-red"          = "#FF3B30", # callout-dont
  "typst-warning"      = "#FF9500", # callout-warning
  "typst-info"         = "#007AFF", # callout-note
  "typst-tip"          = "#00C7BE", # callout-tip
  "typst-caution"      = "#AF52DE"  # callout-caution
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

# Categorical chart palette - brand.yml `meta.chart-palette-order`: the
# eight series hues. `chart-red` sits last on purpose: it is dE00 5.0 from
# `primary`, so the two reds only meet in an eight-series chart; the worst
# pair inside the first seven is dE00 15.3 (blue vs indigo).
.chanwe_chart_colors <- .chanwe_brand_colors[c(
  "primary", "chart-blue", "chart-green", "chart-indigo",
  "chart-orange", "chart-teal", "chart-purple", "chart-red"
)]

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
    chart = .chanwe_chart_colors
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

# Mix `col` with `with` by `t` (0 = col, 1 = with), as an uppercase hex.
.cw_mix <- function(col, with, t) {
  a <- grDevices::col2rgb(col)
  b <- grDevices::col2rgb(with)
  toupper(grDevices::rgb(t(a * (1 - t) + b * t), maxColorValue = 255))
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
#'   `"brand"` (the `color.palette` of the chanwe-brand `brand.yml`),
#'   `"p13_orange"`, `"p13_gray"`, `"p14_accents"`, `"p15_coral"`,
#'   `"p15_vermillion"`, `"p15_green"`, `"p15_magenta"`, `"p15_blue"`,
#'   `"p15_yellow"`, `"p15_cyan"`, `"p15_mustard"`, `"p15_violet"`,
#'   `"p15_teal"`, `"p15_ink"`, `"mb_orange"`, `"mb_dark"`, the series-hue
#'   ramps `"ramp_blue"`, `"ramp_indigo"`, `"ramp_teal"`, `"ramp_green"`,
#'   `"ramp_amber"`, `"ramp_red"`, `"ramp_purple"`,
#'   `"semantic"`, `"signed"`, and `"chart"`.
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
#' @return A list with color, typography, geometry, and reporting token blocks.
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
    # brand.yml `typography`
    typography = list(
      family = "Inter",
      display_family = "Schibsted Grotesk",
      mono_family = "JetBrains Mono",
      serif_family = "Cormorant Garamond",
      base_size = 13.5,
      base_line_height = 1.62,
      heading_weight = 600,
      heading_line_height = 1.15,
      link_weight = 500
    ),
    geometry = list(
      radius_small = 3,
      radius_base = 4,
      radius_large = 6,
      shadow = "none"
    ),
    reporting = list(
      code_background = semantic[["background"]],
      code_left_rule = semantic[["primary"]],
      caption_color = chanwe_get_colors()[["fg-subtle"]],
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
      family = "Inter",
      size = 3,
      lineheight = 1.1,
      fontface = "bold"
    ) +
    ggplot2::scale_color_identity() +
    ggplot2::scale_fill_identity() +
    ggplot2::theme_void(base_family = "Inter") +
    ggplot2::labs(title = title_label) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        hjust = 0,
        size = 14,
        face = "bold",
        color = chanwe_get_colors()[["ink"]]
      ),
      plot.background = ggplot2::element_rect(
        fill = chanwe_get_colors()[["paper"]],
        color = NA
      )
    )
}
