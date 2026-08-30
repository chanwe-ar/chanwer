#' Chanwe Table via gt (HTML)
#'
#' The HTML counterpart of [chanwe_kbl()]: a `gt` table styled with the
#' Chanwe header grammar -- mono-caps eyebrow with an orange rule prefix,
#' Archivo title, Satoshi subtitle, mono-caps column labels, JetBrains Mono
#' tabular figures right-aligned, hairline ink rules above and below the
#' table, a thin neutral rule under the column labels and to the right of
#' the stub, striped rows, and a `//`-prefixed source note.
#'
#' The function returns a regular `gt_tbl`, so every `gt` verb
#' (`gt::fmt_number()`, `gt::cols_label()`, `gt::tab_style()`, ...) can be
#' piped after it.
#'
#' Fonts: the table uses the brand faces when they are available on the
#' page. Load them with [chanwe_reporting_css()] in Quarto HTML documents.
#'
#' @param data A data frame or tibble.
#' @param title Table title (Archivo, 20px).
#' @param subtitle Subtitle line rendered below the title.
#' @param eyebrow Small mono-caps label with an orange rule prefix, rendered
#'   above the title.
#' @param caption Source note at the bottom, prefixed with `//`.
#' @param stub Name of the stub/row-identifier column (passed to
#'   `gt::gt(rowname_col = )`). Rendered left-aligned in ink with a thin
#'   vertical rule on its right.
#' @param signed Optional character vector of column names whose values are
#'   coloured by valence with the canonical signed tokens (positive green,
#'   negative vermillion, zero/NA neutral). Formatting is untouched -- pair it
#'   with `gt::fmt()` for `+x.x%` rendering.
#' @param smaller_is_better Logical. Flip the valence mapping for `signed`
#'   columns where a negative delta is good (costs, churn). Default `FALSE`.
#' @param density `"spacious"` (default) or `"compact"` row padding.
#' @param bg Table background. Named shorthand accepted by [theme_chanwe()]
#'   (`"white"`, `"white-ivory"`, `"metallic"`, `"gray"`, `"beige"`,
#'   `"transparent"`) or any hex string. Default `"white"`.
#' @param id Optional HTML id for the table. A random id is generated when
#'   `NULL` so the scoped CSS never leaks between tables.
#'
#' @return A `gt_tbl` object.
#' @export
#'
#' @examplesIf requireNamespace("gt", quietly = TRUE)
#' df <- data.frame(
#'   metric = c("Revenue", "EBITDA", "Net income"),
#'   value = c(45.9, 12.3, 8.1),
#'   delta = c(12.4, -3.1, 5.8)
#' )
#' tbl <- chanwe_gt(
#'   df,
#'   title = "Quarterly deltas",
#'   eyebrow = "TABLE · P&L",
#'   subtitle = "USD MM and change vs. plan.",
#'   caption = "Source · Internal ledger.",
#'   stub = "metric",
#'   signed = "delta"
#' ) |>
#'   gt::fmt(columns = "delta", fns = function(x) sprintf("%+.1f%%", x))
chanwe_gt <- function(
  data,
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL,
  stub = NULL,
  signed = NULL,
  smaller_is_better = FALSE,
  density = c("spacious", "compact"),
  bg = "white",
  id = NULL
) {
  chanwe_require_package("gt")
  density <- match.arg(density)
  tk <- chanwe_html_tokens()
  bg <- chanwe_resolve_bg(bg)
  if (is.null(id)) {
    id <- gt::random_id()
  }
  row_pad <- if (density == "spacious") 9 else 5

  g <- gt::gt(data, id = id, rowname_col = stub)

  # Heading: eyebrow + title share the gt title slot so the eyebrow sits on
  # top of the title exactly as in chanwe_kbl() and theme_chanwe().
  if (!is.null(title) || !is.null(eyebrow) || !is.null(subtitle)) {
    ttl <- paste0(
      if (!is.null(eyebrow)) {
        sprintf(
          "<span class='chanwe-eyebrow'>%s</span>",
          chanwe_html_escape(eyebrow)
        )
      },
      if (!is.null(title)) {
        sprintf(
          "<span class='chanwe-title'>%s</span>",
          chanwe_html_escape(title)
        )
      }
    )
    g <- gt::tab_header(g, title = gt::html(ttl), subtitle = subtitle)
  }

  g <- gt::tab_options(
    g,
    table.width = gt::pct(100),
    table.font.names = c("Satoshi", "DM Sans", "system-ui", "sans-serif"),
    table.font.size = gt::px(13),
    table.font.color = tk$fg,
    table.background.color = bg,
    heading.align = "left",
    heading.padding = gt::px(6),
    heading.border.bottom.style = "none",
    heading.border.lr.style = "none",
    # hairline ink rules above and below the whole table
    table.border.top.style = "solid",
    table.border.top.width = gt::px(1),
    table.border.top.color = tk$ink,
    table.border.bottom.style = "solid",
    table.border.bottom.width = gt::px(1),
    table.border.bottom.color = tk$ink,
    # ink rule between the heading and the column labels; a single thin
    # neutral rule under the labels (gt's default 2px body-top rule is off)
    column_labels.border.top.style = "solid",
    column_labels.border.top.width = gt::px(1),
    column_labels.border.top.color = tk$ink,
    column_labels.border.bottom.style = "solid",
    column_labels.border.bottom.width = gt::px(1),
    column_labels.border.bottom.color = tk$n300,
    column_labels.padding = gt::px(8),
    table_body.border.top.style = "none",
    table_body.border.bottom.style = "none",
    table_body.hlines.style = "solid",
    table_body.hlines.width = gt::px(1),
    table_body.hlines.color = tk$n200,
    # thin stub divider (gt default is 2px)
    stub.border.style = "solid",
    stub.border.width = gt::px(1),
    stub.border.color = tk$n300,
    data_row.padding = gt::px(row_pad),
    row.striping.include_table_body = TRUE,
    row.striping.include_stub = TRUE,
    row.striping.background_color = tk$n100,
    source_notes.padding = gt::px(8),
    source_notes.border.bottom.style = "none"
  )

  css <- sprintf(
    paste(
      "#%1$s .gt_heading { padding: 4px 0 12px 0 !important; }",
      "#%1$s .chanwe-eyebrow { display:block; font: 500 10px/1.2 %8$s;",
      "  letter-spacing:.18em; text-transform:uppercase; color:%2$s;",
      "  margin-bottom:8px; }",
      "#%1$s .chanwe-eyebrow::before { content:''; display:inline-block;",
      "  width:22px; height:1px; background:%2$s; vertical-align:middle;",
      "  margin-right:8px; }",
      "#%1$s .chanwe-title { font: 600 20px/1.1 %9$s;",
      "  letter-spacing:-0.015em; color:%3$s; }",
      "#%1$s .gt_subtitle { font: 400 13px/1.45 %10$s !important;",
      "  color:%4$s; padding-top:4px !important; }",
      "#%1$s .gt_col_heading { font: 500 10px/1.2 %8$s !important;",
      "  letter-spacing:.14em; text-transform:uppercase; color:%5$s; }",
      "#%1$s .gt_row { font-variant-numeric: tabular-nums; }",
      "#%1$s .gt_row.gt_right { font-family:%8$s; font-size:12px; }",
      "#%1$s .gt_stub { color:%3$s; font-weight:500; }",
      "#%1$s .gt_sourcenote { font: 400 10.5px/1.4 %8$s !important;",
      "  color:%4$s; }",
      "#%1$s .gt_sourcenote::before { content:'// '; color:%11$s; }",
      "#%1$s tbody tr:nth-child(even) > td, #%1$s tbody tr:nth-child(even) > th",
      "  { background:%6$s !important; }",
      "#%1$s tbody tr > td, #%1$s tbody tr > th",
      "  { transition: background-color 120ms ease-out; }",
      "#%1$s tbody tr:hover > td, #%1$s tbody tr:hover > th",
      "  { background:%7$s !important; }",
      "@media (prefers-reduced-motion: reduce) {",
      "  #%1$s tbody tr > td, #%1$s tbody tr > th { transition: none; } }",
      sep = "\n"
    ),
    id, tk$primary, tk$ink, tk$fg_muted, tk$fg_subtle, tk$n100, tk$n200,
    .cw_font_mono, .cw_font_display, .cw_font_sans, tk$primary_text
  )
  g <- gt::opt_css(g, css)

  for (col in signed) {
    if (!col %in% names(data)) {
      stop(sprintf("`signed` column '%s' not found in `data`.", col), call. = FALSE)
    }
    cols <- chanwe_signed_color(data[[col]], tk, smaller_is_better)
    for (colour in unique(cols)) {
      g <- gt::tab_style(
        g,
        style = gt::cell_text(color = colour, weight = 500),
        locations = gt::cells_body(columns = col, rows = which(cols == colour))
      )
    }
  }

  if (!is.null(caption)) {
    g <- gt::tab_source_note(g, caption)
  }
  g
}
