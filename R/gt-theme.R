#' ChanWe Theme for gt Tables
#'
#' Applies ChanWe branding to [gt::gt()] tables with neutral surfaces,
#' understated borders, editorial typography, and orange accents.
#'
#' @param data A gt table object.
#' @param variant One of `"spacious"` or `"compact"` to control table density.
#'   Both variants keep a taller table header.
#' @param background Background surface variant: `"beige"` (`#F7F7F7`) or
#'   `"white"` (`#FFFFFF`). Both use a light-gray border (`#F7F7F7`).
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
gt_theme_chanwe <- function(
  data,
  variant = c("spacious", "compact"),
  background = c("beige", "white")
) {
  chanwe_require_package("gt")

  colors <- chanwe_get_colors()
  variant <- match.arg(variant)
  background <- match.arg(background)
  surface_fill <- switch(
    background,
    beige = colors[["brand-white"]],
    white = colors[["brand-pure-white"]]
  )
  border_color <- colors[["brand-white"]]

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
    font = "DM Sans 9pt",
    size = gt::px(11),
    color = colors[["p13-gray-06"]],
    weight = 500,
    style = "normal"
  ) |>
    gt::tab_options(
      table.background.color = surface_fill,
      table.font.color = colors[["p13-gray-06"]],
      table.border.top.color = border_color,
      table.border.top.width = gt::px(0.6),
      table.border.bottom.color = border_color,
      table.border.bottom.width = gt::px(1),
      heading.background.color = surface_fill,
      heading.title.font.weight = "bold",
      heading.title.font.size = gt::px(16),
      heading.subtitle.font.weight = "normal",
      heading.subtitle.font.size = gt::px(12),
      heading.padding = density$heading_padding,
      heading.border.bottom.color = colors[["brand-orange"]],
      heading.border.bottom.width = gt::px(2),
      column_labels.background.color = surface_fill,
      column_labels.font.weight = "bold",
      column_labels.font.size = gt::px(14.5),
      column_labels.padding = density$column_labels_padding,
      column_labels.border.top.color = border_color,
      column_labels.border.top.width = gt::px(0.6),
      column_labels.border.bottom.color = colors[["brand-black"]],
      column_labels.border.bottom.width = gt::px(2),
      table_body.hlines.color = border_color,
      table_body.hlines.width = gt::px(0.6),
      table_body.vlines.color = border_color,
      table_body.vlines.width = gt::px(0.6),
      row.striping.background_color = surface_fill,
      stub.background.color = surface_fill,
      row_group.background.color = surface_fill,
      summary_row.background.color = surface_fill,
      grand_summary_row.background.color = surface_fill,
      data_row.padding = density$data_row_padding,
      source_notes.font.size = gt::px(11),
      source_notes.background.color = surface_fill,
      footnotes.font.size = gt::px(11),
      footnotes.background.color = surface_fill
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["brand-orange"]],
          weight = "bold",
          size = gt::px(16),
          align = "center"
        )
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["brand-orange"]],
        weight = "bold",
        size = gt::px(12),
        align = "center"
      ),
      locations = gt::cells_title(groups = "subtitle")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["brand-black"]],
        weight = "bold",
        size = gt::px(14.5)
      ),
      locations = gt::cells_column_labels()
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["p13-gray-06"]],
          weight = "normal",
          size = gt::px(11)
        ),
        gt::cell_fill(color = surface_fill)
      ),
      locations = gt::cells_body()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["p13-gray-03"]],
        weight = "bold"
      ),
      locations = gt::cells_stub(rows = gt::everything())
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
         .gt_heading { border-top: 0.6px solid %s; border-left: 4px solid %s; padding-left: 10px; }
         .gt_caption { color: %s; font-size: 12px; }
         .gt_row { line-height: 1.6; color: %s; font-weight: 500; background: %s !important; }
         .gt_row th, .gt_row td { background: %s !important; border-bottom: 0.6px solid %s; }
         .gt_striped, .gt_striped th, .gt_striped td { background: %s !important; }
         .gt_table tbody tr:nth-child(odd) > th,
         .gt_table tbody tr:nth-child(odd) > td,
         .gt_table tbody tr:nth-child(even) > th,
         .gt_table tbody tr:nth-child(even) > td { background: %s !important; }
         .gt_table tbody tr,
         .gt_table tbody tr > th,
         .gt_table tbody tr > td,
         .gt_stub,
         .gt_group_heading,
         .gt_summary_row,
         .gt_grand_summary_row { background: %s !important; background-color: %s !important; }",
        border_color,
        colors[["brand-orange"]],
        colors[["p13-gray-07"]],
        colors[["p13-gray-06"]],
        surface_fill,
        surface_fill,
        border_color,
        surface_fill,
        surface_fill,
        surface_fill,
        surface_fill
      )
    )
}

#' ChanWe Spacious Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "spacious"`.
#'
#' @param data A gt table object.
#' @param background Background surface variant passed to [gt_theme_chanwe()].
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
gt_theme_chanwe_spacious <- function(data, background = c("beige", "white")) {
  gt_theme_chanwe(data, variant = "spacious", background = background)
}

#' ChanWe Compact Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "compact"`.
#'
#' @param data A gt table object.
#' @param background Background surface variant passed to [gt_theme_chanwe()].
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
gt_theme_chanwe_compact <- function(data, background = c("beige", "white")) {
  gt_theme_chanwe(data, variant = "compact", background = background)
}
