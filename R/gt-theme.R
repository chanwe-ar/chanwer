#' ChanWe Theme for gt Tables
#'
#' Applies ChanWe branding to [gt::gt()] tables with neutral surfaces,
#' understated borders, editorial typography, and orange accents.
#'
#' @param data A gt table object.
#' @param variant One of `"spacious"` or `"compact"` to control table density.
#'   Both variants keep a taller table header.
#'
#' @return A themed gt table object.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   tbl <- gt::gt(head(mtcars)) |>
#'     gt::tab_header(title = "Motor Trend Cars") |>
#'     gt_theme_chanwe(variant = "spacious")
#' }
gt_theme_chanwe <- function(data, variant = c("spacious", "compact")) {
  chanwe_require_package("gt")

  colors <- chanwe_get_colors()
  variant <- match.arg(variant)

  density <- switch(
    variant,
    spacious = list(
      heading_padding = gt::px(30),
      column_labels_padding = gt::px(12),
      data_row_padding = gt::px(10)
    ),
    compact = list(
      heading_padding = gt::px(22),
      column_labels_padding = gt::px(9),
      data_row_padding = gt::px(5)
    )
  )

  gt::opt_table_font(
    data = data,
    font = list(gt::google_font("DM Sans"), gt::default_fonts()),
    size = gt::px(14),
    color = colors[["p13-gray-06"]],
    weight = 500,
    style = "normal"
  ) |>
    gt::tab_options(
      table.background.color = colors[["brand-pure-white"]],
      table.font.color = colors[["p13-gray-06"]],
      table.border.top.color = colors[["p13-gray-08"]],
      table.border.top.width = gt::px(0.8),
      table.border.bottom.color = colors[["brand-beige-soft"]],
      table.border.bottom.width = gt::px(1),
      heading.background.color = colors[["brand-pure-white"]],
      heading.title.font.weight = "900",
      heading.title.font.size = gt::px(25),
      heading.subtitle.font.weight = "500",
      heading.subtitle.font.size = gt::px(15),
      heading.padding = density$heading_padding,
      heading.border.bottom.color = colors[["brand-orange"]],
      heading.border.bottom.width = gt::px(2),
      column_labels.background.color = colors[["brand-pure-white"]],
      column_labels.font.weight = "800",
      column_labels.font.size = gt::px(14.5),
      column_labels.padding = density$column_labels_padding,
      column_labels.border.top.color = colors[["p13-gray-08"]],
      column_labels.border.top.width = gt::px(0.8),
      column_labels.border.bottom.color = colors[["brand-black"]],
      column_labels.border.bottom.width = gt::px(2),
      table_body.hlines.color = colors[["brand-beige-soft"]],
      table_body.hlines.width = gt::px(0.6),
      table_body.vlines.color = colors[["brand-beige-soft"]],
      table_body.vlines.width = gt::px(0.6),
      data_row.padding = density$data_row_padding,
      source_notes.font.size = gt::px(11),
      source_notes.background.color = colors[["brand-pure-white"]],
      footnotes.font.size = gt::px(11),
      footnotes.background.color = colors[["brand-pure-white"]]
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["brand-orange"]],
          weight = "bolder",
          size = gt::px(25),
          align = "left"
        )
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["brand-orange"]],
        weight = "600"
      ),
      locations = gt::cells_title(groups = "subtitle")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["brand-orange"]],
        weight = "800",
        size = gt::px(14.5)
      ),
      locations = gt::cells_column_labels()
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["p13-gray-06"]],
          weight = "500",
          size = gt::px(14)
        ),
        gt::cell_fill(color = "transparent")
      ),
      locations = gt::cells_body()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["p13-gray-07"]],
        size = gt::px(11)
      ),
      locations = gt::cells_source_notes()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["p13-gray-07"]],
        size = gt::px(11)
      ),
      locations = gt::cells_footnotes()
    ) |>
    gt::opt_css(
      css = sprintf(
        ".gt_table { border-radius: 4px; box-shadow: none; }
         .gt_heading { border-left: 4px solid %s; padding-left: 10px; }
         .gt_caption { color: %s; font-size: 12px; }
         .gt_row { line-height: 1.6; color: %s; font-weight: 500; background: transparent !important; }
         .gt_row td { background: transparent !important; border-bottom: 0.6px solid %s; }",
        colors[["brand-orange"]],
        colors[["p13-gray-07"]],
        colors[["p13-gray-06"]],
        colors[["brand-beige-soft"]]
      )
    )
}

#' ChanWe Spacious Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "spacious"`.
#'
#' @param data A gt table object.
#'
#' @return A themed gt table object.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   gt::gt(head(mtcars)) |>
#'     gt::tab_header(title = "Spacious table") |>
#'     gt_theme_chanwe_spacious()
#' }
gt_theme_chanwe_spacious <- function(data) {
  gt_theme_chanwe(data, variant = "spacious")
}

#' ChanWe Compact Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "compact"`.
#'
#' @param data A gt table object.
#'
#' @return A themed gt table object.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   gt::gt(head(mtcars)) |>
#'     gt::tab_header(title = "Compact table") |>
#'     gt_theme_chanwe_compact()
#' }
gt_theme_chanwe_compact <- function(data) {
  gt_theme_chanwe(data, variant = "compact")
}
