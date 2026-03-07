#' ChanWe Theme for gt Tables
#'
#' Applies ChanWe branding to [gt::gt()] tables with neutral surfaces,
#' understated borders, editorial typography, and orange accents.
#'
#' @param data A gt table object.
#'
#' @return A themed gt table object.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   tbl <- gt::gt(head(mtcars)) |>
#'     gt::tab_header(title = "Motor Trend Cars") |>
#'     gt_theme_chanwe()
#' }
gt_theme_chanwe <- function(data) {
  chanwe_require_package("gt")

  colors <- chanwe_get_colors()

  gt::opt_table_font(
    data = data,
    font = list(gt::google_font("DM Sans"), gt::default_fonts()),
    size = gt::px(13.5),
    color = colors[["p13-gray-05"]],
    weight = 400,
    style = "normal"
  ) |>
    gt::tab_options(
      table.background.color = colors[["brand-white"]],
      table.font.color = colors[["p13-gray-05"]],
      table.border.top.color = colors[["brand-beige-soft"]],
      table.border.top.width = gt::px(1),
      table.border.bottom.color = colors[["brand-beige-soft"]],
      table.border.bottom.width = gt::px(1),
      heading.background.color = colors[["brand-pure-white"]],
      heading.title.font.weight = "900",
      heading.title.font.size = gt::px(24),
      heading.subtitle.font.weight = "500",
      heading.subtitle.font.size = gt::px(14),
      heading.border.bottom.color = colors[["brand-orange"]],
      heading.border.bottom.width = gt::px(2),
      column_labels.background.color = colors[["brand-beige"]],
      column_labels.font.weight = "700",
      column_labels.font.size = gt::px(12),
      column_labels.border.top.color = colors[["brand-beige-soft"]],
      column_labels.border.bottom.color = colors[["brand-beige-soft"]],
      table_body.hlines.color = colors[["brand-beige-soft"]],
      table_body.vlines.color = colors[["brand-beige-soft"]],
      data_row.padding = gt::px(6),
      source_notes.font.size = gt::px(11),
      source_notes.background.color = colors[["brand-white"]],
      footnotes.font.size = gt::px(11),
      footnotes.background.color = colors[["brand-white"]]
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["brand-black"]],
          weight = "bolder",
          size = gt::px(24),
          align = "left"
        )
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["p13-gray-06"]],
        size = gt::px(11)
      ),
      locations = gt::cells_source_notes()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["p13-gray-06"]],
        size = gt::px(11)
      ),
      locations = gt::cells_footnotes()
    ) |>
    gt::opt_css(
      css = sprintf(
        ".gt_table { border-radius: 4px; box-shadow: none; }
         .gt_heading { border-left: 4px solid %s; padding-left: 10px; }
         .gt_caption { color: %s; font-size: 12px; }
         .gt_row { line-height: 1.6; }",
        colors[["brand-orange"]],
        colors[["p13-gray-06"]]
      )
    )
}
