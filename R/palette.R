# Brand color tokens -------------------------------------------------------

.chanwe_colors <- c(
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
  "p14-red-soft" = "#F9A7A7"
)

.chanwe_semantic_names <- c(
  foreground = "p13-gray-05",
  background = "brand-white",
  primary = "brand-orange",
  secondary = "brand-black",
  success = "p14-green-strong",
  warning = "p14-yellow-strong",
  danger = "p14-red-strong",
  info = "p14-cyan-strong"
)

.chanwe_chart_names <- c(
  "brand-orange",
  "p14-blue-strong",
  "p14-cyan-strong",
  "p14-green-strong",
  "p14-yellow-strong",
  "p14-magenta-strong",
  "p14-red-strong",
  "brand-gray"
)

.chanwe_palette_groups <- function() {
  list(
    core = .chanwe_colors[c(
      "brand-orange", "brand-black", "brand-white", "brand-pure-white",
      "brand-beige", "brand-beige-soft", "brand-gray", "brand-silver"
    )],
    p13_orange = .chanwe_colors[grep("^p13-orange", names(.chanwe_colors))],
    p13_gray = .chanwe_colors[grep("^p13-gray", names(.chanwe_colors))],
    p14_accents = .chanwe_colors[grep("^p14", names(.chanwe_colors))],
    semantic = chanwe_get_semantic(),
    chart = .chanwe_colors[.chanwe_chart_names]
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
  .chanwe_colors[.chanwe_chart_names]
}

#' ChanWe Color Palette Tokens
#'
#' Returns ChanWe brand colors as a single named vector, grouped vectors,
#' or specific palette subsets used by plotting and reporting helpers.
#'
#' @param palette Optional palette selector. Use `NULL` (default) to return
#'   all colors and grouped palettes. Supported names are `"all"`, `"core"`,
#'   `"p13_orange"`, `"p13_gray"`, `"p14_accents"`, `"semantic"`, and
#'   `"chart"`.
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
      family = "DM Sans",
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
      caption_color = chanwe_get_colors()[["p13-gray-06"]],
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
        package = "chanweThemes"
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
      color = chanwe_get_colors()[["brand-pure-white"]],
      linewidth = 0.8,
      width = 0.95,
      height = 0.95
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = label),
      family = "DM Sans",
      size = 3,
      lineheight = 1.1,
      color = chanwe_get_colors()[["brand-black"]],
      fontface = "bold"
    ) +
    ggplot2::scale_fill_identity() +
    ggplot2::coord_equal() +
    ggplot2::theme_void(base_family = "DM Sans") +
    ggplot2::labs(title = "ChanWe Palette") +
    ggplot2::theme(
      plot.title = ggplot2::element_text(
        hjust = 0,
        size = 14,
        face = "bold",
        color = chanwe_get_colors()[["brand-black"]]
      ),
      plot.background = ggplot2::element_rect(
        fill = chanwe_get_colors()[["brand-white"]],
        color = NA
      )
    )
}
