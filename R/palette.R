# Brand color tokens -------------------------------------------------------

.chanwe_colors <- c(
  # Editorial 8-color chart palette — p15 family primaries (shade -01)
  "chart-coral"   = "#EE5524",
  "chart-blue"    = "#0C48ED",
  "chart-green"   = "#1EB508",
  "chart-mustard" = "#E8B400",
  "chart-violet"  = "#9B2E8F",
  "chart-teal"    = "#14A4B8",
  "chart-magenta" = "#EB03F2",
  "chart-ink"     = "#141414",
  "brand-orange" = "#E94B2B",
  "brand-black" = "#101010",
  "brand-white" = "#F7F7F7",
  "brand-pure-white" = "#FFFFFF",
  "brand-beige" = "#F8F8F8",
  "brand-beige-soft" = "#EEEEEE",
  "brand-gray" = "#6B6B6B",
  "brand-silver" = "#C9C9C9",
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
  # p15 — full 5-shade ramps (dark → light) for 11 semantic families
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
  # chanwe-typst report system tokens
  "typst-primary"     = "#FB3D0E",
  "typst-ink"         = "#0F0F0F",
  "typst-fg"          = "#211F1C",
  "typst-fg-muted"    = "#71706C",
  "typst-fg-subtle"   = "#928D86",
  "typst-neutral-100" = "#F5F5F5",
  "typst-neutral-200" = "#E8E8E8",
  "typst-neutral-300" = "#D4D4D4",
  "typst-neutral-700" = "#525252",
  "typst-neutral-900" = "#1F1F1F",
  "typst-white"       = "#FFFFFF",
  "typst-green"       = "#15803D",
  "typst-red"         = "#CC1914",
  "typst-warning"     = "#EB9113",
  "typst-info"        = "#0758E5"
)

.chanwe_semantic_names <- c(
  foreground = "typst-fg",
  background = "typst-neutral-100",
  primary    = "typst-primary",
  secondary  = "typst-ink",
  success    = "typst-green",
  warning    = "typst-warning",
  danger     = "typst-red",
  info       = "typst-info"
)

# Editorial 8-color chart palette — p15 family primaries (shade -01)
.chanwe_chart_colors <- c(
  "chart-coral"    = "#EE5524",
  "chart-blue"     = "#0C48ED",
  "chart-green"    = "#1EB508",
  "chart-mustard"  = "#E8B400",
  "chart-violet"   = "#9B2E8F",
  "chart-teal"     = "#14A4B8",
  "chart-magenta"  = "#EB03F2",
  "chart-ink"      = "#141414"
)

.chanwe_chart_names <- names(.chanwe_chart_colors)

.chanwe_palette_groups <- function() {
  list(
    core = .chanwe_colors[c(
      "brand-orange", "brand-black", "brand-white", "brand-pure-white",
      "brand-beige", "brand-beige-soft", "brand-gray", "brand-silver"
    )],
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
    semantic = chanwe_get_semantic(),
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

#' ChanWe Color Palette Tokens
#'
#' Returns ChanWe brand colors as a single named vector, grouped vectors,
#' or specific palette subsets used by plotting and reporting helpers.
#'
#' @param palette Optional palette selector. Use `NULL` (default) to return
#'   all colors and grouped palettes. Supported names are `"all"`, `"core"`,
#'   `"p13_orange"`, `"p13_gray"`, `"p14_accents"`, `"p15_coral"`,
#'   `"p15_vermillion"`, `"p15_green"`, `"p15_magenta"`, `"p15_blue"`,
#'   `"p15_yellow"`, `"p15_cyan"`, `"p15_mustard"`, `"p15_violet"`,
#'   `"p15_teal"`, `"p15_ink"`, `"semantic"`, and `"chart"`.
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

#' ChanWe Brand Tokens
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
    name = "ChanWe",
    colors = chanwe_get_colors(),
    semantic = semantic,
    chart_order = chanwe_get_chart(),
    typography = list(
      family = "Satoshi",
      base_size = 13.5,
      base_line_height = 1.62,
      heading_weight = 900,
      heading_line_height = 1.15,
      link_weight = 600
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
      caption_color = chanwe_get_colors()[["typst-fg-subtle"]],
      callouts = c(
        note = chanwe_get_colors()[["p14-cyan-strong"]],
        info = chanwe_get_colors()[["p14-cyan-strong"]],
        success = chanwe_get_colors()[["p14-green-strong"]],
        warning = chanwe_get_colors()[["p14-yellow-strong"]],
        important = chanwe_get_colors()[["p14-magenta-strong"]],
        caution = chanwe_get_colors()[["p14-red-strong"]],
        alert = chanwe_get_colors()[["p14-red-strong"]]
      ),
      section_marker_asset = system.file(
        "assets",
        "Estrategia_Color1.png",
        package = "chanwer"
      )
    )
  )
}

#' Preview ChanWe Palette
#'
#' Draws a swatch grid of ChanWe colors using ggplot2.
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

  ggplot2::ggplot(df, ggplot2::aes(x = col, y = -row)) +
    ggplot2::geom_tile(
      ggplot2::aes(fill = value),
      color = chanwe_get_colors()[["typst-white"]],
      linewidth = 0.8,
      width = 0.95,
      height = 0.95
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = label),
      family = "Satoshi",
      size = 3,
      lineheight = 1.1,
      color = chanwe_get_colors()[["typst-ink"]],
      fontface = "bold"
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::coord_equal() +
    ggplot2::theme_void(base_family = "Satoshi") +
    ggplot2::labs(title = "ChanWe Palette") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        hjust = 0,
        size = 14,
        face = "bold",
        color = chanwe_get_colors()[["typst-ink"]]
      ),
      plot.background = ggplot2::element_rect(
        fill = chanwe_get_colors()[["typst-neutral-100"]],
        color = NA
      )
    )
}
