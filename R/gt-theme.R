#' ChanWe Theme for gt Tables
#'
#' Applies ChanWe branding to [gt::gt()] tables: editorial typography,
#' mono-caps column headers, clean black divider lines, and neutral surfaces.
#'
#' @param data A gt table object.
#' @param variant One of `"spacious"` or `"compact"` to control table density.
#' @param bg_color Background hex color for the table surface. Defaults to
#'   `"#FFFFFF"`. Pass `"#F5F5F5"` for the standard neutral-100 beige.
#'
#' @return A themed gt table object.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   gt::gt(head(mtcars)) |>
#'     gt::tab_header(title = "Motor Trend Cars", subtitle = "Top rows") |>
#'     gt_theme_chanwe()
#' }
gt_theme_chanwe <- function(
  data,
  variant   = c("spacious", "compact"),
  bg_color  = "#FFFFFF"
) {
  chanwe_require_package("gt")

  colors  <- chanwe_get_colors()
  variant <- match.arg(variant)

  density <- switch(
    variant,
    spacious = list(
      heading_padding       = gt::px(28),
      column_labels_padding = gt::px(10),
      data_row_padding      = gt::px(12)
    ),
    compact = list(
      heading_padding       = gt::px(18),
      column_labels_padding = gt::px(7),
      data_row_padding      = gt::px(6)
    )
  )

  data |>
    gt::tab_options(
      table.background.color               = bg_color,
      table.font.size                      = gt::px(13),
      table.font.color                     = colors[["typst-fg"]],
      table.font.names                     = "Satoshi",
      table.border.top.color               = colors[["typst-ink"]],
      table.border.top.width               = gt::px(0.5),
      table.border.bottom.color            = colors[["typst-ink"]],
      table.border.bottom.width            = gt::px(0.5),
      heading.background.color             = bg_color,
      heading.title.font.size              = gt::px(40),
      heading.title.font.weight            = "bold",
      heading.subtitle.font.size           = gt::px(13),
      heading.subtitle.font.weight         = "normal",
      heading.padding                      = density$heading_padding,
      heading.border.bottom.color          = colors[["typst-ink"]],
      heading.border.bottom.width          = gt::px(0.5),
      column_labels.background.color       = bg_color,
      column_labels.font.size              = gt::px(10),
      column_labels.font.weight            = "normal",
      column_labels.padding                = density$column_labels_padding,
      column_labels.border.top.color       = colors[["typst-ink"]],
      column_labels.border.top.width       = gt::px(0.5),
      column_labels.border.bottom.color    = colors[["typst-ink"]],
      column_labels.border.bottom.width    = gt::px(0.5),
      table_body.hlines.color              = colors[["typst-neutral-200"]],
      table_body.hlines.width              = gt::px(0.3),
      table_body.vlines.color              = "transparent",
      table_body.vlines.width              = gt::px(0),
      row.striping.background_color        = bg_color,
      stub.background.color                = bg_color,
      row_group.background.color           = bg_color,
      summary_row.background.color         = bg_color,
      grand_summary_row.background.color   = bg_color,
      data_row.padding                     = density$data_row_padding,
      source_notes.font.size               = gt::px(11),
      source_notes.background.color        = bg_color,
      footnotes.font.size                  = gt::px(11),
      footnotes.background.color           = bg_color
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font      = gt::google_font("Archivo"),
        color     = colors[["typst-ink"]],
        weight    = "bold",
        size      = gt::px(40),
        align     = "left"
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font   = gt::google_font("Satoshi"),
        color  = colors[["typst-fg-muted"]],
        weight = "normal",
        size   = gt::px(13),
        align  = "left"
      ),
      locations = gt::cells_title(groups = "subtitle")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font          = gt::google_font("JetBrains Mono"),
        color         = colors[["typst-fg-subtle"]],
        weight        = "normal",
        size          = gt::px(10),
        transform     = "uppercase",
        v_align       = "middle"
      ),
      locations = gt::cells_column_labels()
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides  = c("top", "bottom"),
        color  = colors[["typst-ink"]],
        weight = gt::px(0.5),
        style  = "solid"
      ),
      locations = gt::cells_column_labels(columns = gt::everything())
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color  = colors[["typst-fg"]],
          weight = "normal",
          size   = gt::px(13)
        ),
        gt::cell_fill(color = bg_color)
      ),
      locations = gt::cells_body()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color  = colors[["typst-fg-subtle"]],
        weight = "normal",
        size   = gt::px(12)
      ),
      locations = gt::cells_stub(rows = gt::everything())
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font   = gt::google_font("JetBrains Mono"),
        color  = colors[["typst-fg-subtle"]],
        weight = "normal",
        size   = gt::px(10)
      ),
      locations = gt::cells_source_notes()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color  = colors[["typst-fg-subtle"]],
        size   = gt::px(11)
      ),
      locations = gt::cells_footnotes()
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color  = colors[["typst-fg-muted"]],
          weight = "bold",
          size   = gt::px(12)
        ),
        gt::cell_fill(color = bg_color)
      ),
      locations = gt::cells_row_groups()
    ) |>
    gt::opt_css(
      css = sprintf(
        "
        .gt_table { border-radius: 0; box-shadow: none; border-top: 0.5px solid %s !important; border-bottom: 0.5px solid %s !important; }
        .gt_heading { border-top: none; padding-left: 0; text-align: left !important; }
        .gt_title { padding-bottom: 2px !important; margin-bottom: 0 !important; }
        .gt_subtitle { padding-top: 2px !important; margin-top: 0 !important; font-style: normal !important; }
        .gt_col_headings { border-top: 0.5px solid %s !important; border-bottom: 0.5px solid %s !important; }
        .gt_col_heading { letter-spacing: 0.08em; }
        .gt_row { line-height: 1.55; background: %s !important; }
        .gt_row th, .gt_row td { background: %s !important; }
        .gt_striped, .gt_striped th, .gt_striped td { background: %s !important; }
        .gt_stub { background: %s !important; color: %s; font-size: 12px; border-right: none !important; }
        .gt_group_heading { background: %s !important; }
        .gt_summary_row, .gt_grand_summary_row { background: %s !important; }
        .gt_sourcenotes { border-top: 0.5px solid %s; border-bottom: 0.5px solid %s; padding-top: 14px; padding-bottom: 14px; font-style: normal !important; }
        ",
        colors[["typst-ink"]], colors[["typst-ink"]],
        colors[["typst-ink"]], colors[["typst-ink"]],
        bg_color, bg_color, bg_color, bg_color,
        colors[["typst-fg-subtle"]],
        bg_color, bg_color,
        colors[["typst-ink"]], colors[["typst-ink"]]
      )
    )
}

#' ChanWe GT Eyebrow Helper
#'
#' Returns an HTML string for use inside `gt::html()` as the `title` argument.
#' Renders an orange `──` rule followed by mono-caps eyebrow text above the
#' title, matching the [chanwe_title()] treatment in ggplot2.
#'
#' @param eyebrow Eyebrow label string, e.g. `"SECTION · PEER BENCHMARK"`.
#'
#' @return An HTML string. Wrap the title with `gt::html(paste0(chanwe_gt_eyebrow("..."), "Title"))`.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'   gt::gt(head(mtcars)) |>
#'     gt::tab_header(
#'       title = gt::html(paste0(chanwe_gt_eyebrow("SECTION · FLEET"), "Operational Snapshot"))
#'     ) |>
#'     gt_theme_chanwe()
#' }
chanwe_gt_eyebrow <- function(eyebrow) {
  color <- chanwe_get_colors()[["typst-primary"]]
  paste0(
    "<div style='font-family:\"JetBrains Mono\",monospace;font-size:7.5pt;",
    "font-weight:500;letter-spacing:0.12em;text-transform:uppercase;",
    "color:", color, ";margin-bottom:5px;'>",
    "── ", toupper(eyebrow),
    "</div>"
  )
}

#' ChanWe Spacious Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "spacious"`.
#'
#' @param data A gt table object.
#' @param bg_color Background hex color passed to [gt_theme_chanwe()].
#' @param background Deprecated. Use `bg_color` instead.
#'
#' @return A themed gt table object.
#' @export
gt_theme_chanwe_spacious <- function(data, bg_color = "#FFFFFF",
                                     background = NULL) {
  if (!is.null(background)) {
    bg_color <- if (identical(background, "beige")) "#F5F5F5" else "#FFFFFF"
  }
  gt_theme_chanwe(data, variant = "spacious", bg_color = bg_color)
}

#' ChanWe Compact Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "compact"`.
#'
#' @param data A gt table object.
#' @param bg_color Background hex color passed to [gt_theme_chanwe()].
#' @param background Deprecated. Use `bg_color` instead.
#'
#' @return A themed gt table object.
#' @export
gt_theme_chanwe_compact <- function(data, bg_color = "#FFFFFF",
                                    background = NULL) {
  if (!is.null(background)) {
    bg_color <- if (identical(background, "beige")) "#F5F5F5" else "#FFFFFF"
  }
  gt_theme_chanwe(data, variant = "compact", bg_color = bg_color)
}
