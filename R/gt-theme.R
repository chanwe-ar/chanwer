#' ChanWe Theme for gt Tables
#'
#' Applies ChanWe branding to a [gt::gt()] table: Archivo title, Satoshi body
#' text, JetBrains Mono column headers in mono-caps, thin black divider lines,
#' and a neutral surface. Pairs with [chanwe_gt_eyebrow()] for the orange
#' section-label treatment above the title.
#'
#' ## Layout variants
#' | `variant` | Row padding | Heading padding | Use |
#' |-----------|-------------|-----------------|-----|
#' | `"spacious"` (default) | 12 px | 28 px | Reports, presentations |
#' | `"compact"` | 6 px | 18 px | Dense data, dashboards |
#'
#' Convenience wrappers [gt_theme_chanwe_spacious()] and
#' [gt_theme_chanwe_compact()] call this function with the variant pre-set.
#'
#' ## Background variants
#' | Name | Hex | Use |
#' |------|-----|-----|
#' | `"white"` | `#FFFFFF` | Default |
#' | `"gray"` | `#F5F5F5` | Light neutral gray |
#' | `"beige"` | `#ECE5D8` | Warm brand beige |
#'
#' @param data A gt table object created with [gt::gt()].
#' @param variant One of `"spacious"` (default) or `"compact"`.
#' @param bg_color Background color. Accepts a hex string or `"white"`
#'   (default), `"gray"`, `"beige"`.
#' @param base_text_size Base font size in pixels (default `11`). All other
#'   font sizes scale proportionally from this value:
#'   - Body cells: `1.0×` base
#'   - Title: `~3.6×` base
#'   - Subtitle: `~1.45×` base
#'   - Column labels: `~0.82×` base
#'   - Stub / row groups: `~1.09×` base
#'   - Source notes / footnotes: `1.0×` base
#'
#' @return The input gt table with ChanWe styling applied.
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'
#'   ## Basic table
#'   gt::gt(head(mtcars, 8)) |>
#'     gt::tab_header(
#'       title = "Motor Trend Cars",
#'       subtitle = "Top 8 rows · mtcars"
#'     ) |>
#'     gt::tab_source_note("Source: Motor Trend, 1974") |>
#'     gt_theme_chanwe()
#'
#'   ## With eyebrow, beige background, spacious variant
#'   mt <- tibble::as_tibble(mtcars, rownames = "model")
#'   gt::gt(head(mt, 6), rowname_col = "model") |>
#'     gt::tab_header(
#'       title = gt::html(paste0(
#'         chanwe_gt_eyebrow("SECTION · FLEET"),
#'         "Operational Snapshot"
#'       )),
#'       subtitle = "Fleet overview · mtcars sample"
#'     ) |>
#'     gt::tab_source_note("Source · Motor Trend, 1974") |>
#'     gt_theme_chanwe(bg_color = "beige", variant = "spacious")
#'
#'   ## Compact variant, gray background
#'   gt::gt(head(mtcars, 10)) |>
#'     gt::tab_header(title = "Compact view") |>
#'     gt_theme_chanwe(variant = "compact", bg_color = "gray")
#'
#'   ## Larger base size for presentations
#'   gt::gt(head(mtcars, 6)) |>
#'     gt::tab_header(title = "Larger text") |>
#'     gt_theme_chanwe(base_text_size = 14)
#' }
gt_theme_chanwe <- function(
  data,
  variant = c("spacious", "compact"),
  bg_color = "white",
  base_text_size = 11
) {
  chanwe_require_package("gt")
  bg_color <- chanwe_resolve_bg(bg_color)

  colors <- chanwe_get_colors()
  variant <- match.arg(variant)

  density <- switch(
    variant,
    spacious = list(
      heading_padding = gt::px(36),
      column_labels_padding = gt::px(10),
      data_row_padding = gt::px(12)
    ),
    compact = list(
      heading_padding = gt::px(24),
      column_labels_padding = gt::px(7),
      data_row_padding = gt::px(6)
    )
  )

  sz <- function(ratio) gt::px(round(base_text_size * ratio))

  data |>
    gt::tab_options(
      table.background.color = bg_color,
      table.font.size = sz(1.0),
      table.font.color = colors[["typst-fg"]],
      table.font.names = "Satoshi",
      table.border.top.color = colors[["typst-ink"]],
      table.border.top.width = gt::px(0.5),
      table.border.bottom.color = colors[["typst-ink"]],
      table.border.bottom.width = gt::px(0.5),
      heading.background.color = bg_color,
      heading.title.font.size = sz(3.6),
      heading.title.font.weight = "bold",
      heading.subtitle.font.size = sz(1.8),
      heading.subtitle.font.weight = "normal",
      heading.padding = density$heading_padding,
      heading.border.bottom.color = colors[["typst-ink"]],
      heading.border.bottom.width = gt::px(0.5),
      column_labels.background.color = bg_color,
      column_labels.font.size = sz(0.82),
      column_labels.font.weight = "normal",
      column_labels.padding = density$column_labels_padding,
      column_labels.border.top.color = colors[["typst-ink"]],
      column_labels.border.top.width = gt::px(0.5),
      column_labels.border.bottom.color = colors[["typst-ink"]],
      column_labels.border.bottom.width = gt::px(0.5),
      table_body.border.top.color = colors[["typst-ink"]],
      table_body.border.top.width = gt::px(0.5),
      table_body.border.bottom.color = colors[["typst-ink"]],
      table_body.border.bottom.width = gt::px(0.5),
      table_body.hlines.color = colors[["typst-neutral-200"]],
      table_body.hlines.width = gt::px(0.3),
      table_body.vlines.color = "transparent",
      table_body.vlines.width = gt::px(0),
      row.striping.background_color = bg_color,
      stub.background.color = bg_color,
      row_group.background.color = bg_color,
      summary_row.background.color = bg_color,
      grand_summary_row.background.color = bg_color,
      data_row.padding = density$data_row_padding,
      source_notes.font.size = sz(1.0),
      source_notes.padding = gt::px(15),
      source_notes.background.color = bg_color,
      footnotes.font.size = sz(1.0),
      footnotes.padding = gt::px(15),
      footnotes.background.color = bg_color
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("Archivo"),
        color = colors[["typst-ink"]],
        weight = "bold",
        size = sz(3.00),
        align = "left"
      ),
      locations = gt::cells_title(groups = "title")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("Archivo"),
        color = colors[["typst-fg-muted"]],
        size = sz(1.50),
        align = "left"
      ),
      locations = gt::cells_title(groups = "subtitle")
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("JetBrains Mono"),
        color = colors[["typst-fg-subtle"]],
        weight = "normal",
        size = sz(0.75),
        transform = "uppercase",
        v_align = "middle"
      ),
      locations = gt::cells_column_labels()
    ) |>
    gt::tab_style(
      style = gt::cell_borders(
        sides = c("top", "bottom"),
        color = colors[["typst-ink"]],
        weight = gt::px(0.5),
        style = "solid"
      ),
      locations = gt::cells_column_labels(columns = gt::everything())
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["typst-fg"]],
          weight = "normal",
          size = sz(1.05)
        ),
        gt::cell_fill(color = bg_color)
      ),
      locations = gt::cells_body()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["typst-fg-subtle"]],
        weight = "normal",
        size = sz(1.09)
      ),
      locations = gt::cells_stub(rows = gt::everything())
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        font = gt::google_font("JetBrains Mono"),
        color = colors[["typst-fg-subtle"]],
        weight = "normal",
        size = sz(0.91)
      ),
      locations = gt::cells_source_notes()
    ) |>
    gt::tab_style(
      style = gt::cell_text(
        color = colors[["typst-fg-subtle"]],
        size = sz(1.0)
      ),
      locations = gt::cells_footnotes()
    ) |>
    gt::tab_style(
      style = list(
        gt::cell_text(
          color = colors[["typst-fg-muted"]],
          weight = "bold",
          size = sz(1.09)
        ),
        gt::cell_fill(color = bg_color)
      ),
      locations = gt::cells_row_groups()
    ) |>
    gt::opt_css(
      css = sprintf(
        "
        @import url('https://api.fontshare.com/v2/css?f[]=satoshi@400,500,700&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Archivo:wght@300&display=swap');
        .gt_subtitle { font-weight: 300 !important; }
        .gt_table { border-radius: 0; box-shadow: none; border-top: 0.5px solid %s !important; border-bottom: 0.5px solid %s !important; }
        .gt_heading { border-top: none; padding-left: 0; padding-top: 24px !important; text-align: left !important; }
        .gt_title { padding-bottom: 8px !important; margin-bottom: 0 !important; }
        .gt_subtitle { padding-top: 0 !important; margin-top: 0 !important; font-style: normal !important; }
        .gt_col_headings { border-top: 0.5px solid %s !important; border-bottom: 0.5px solid %s !important; }
        .gt_col_heading { letter-spacing: 0.08em; padding-top: 28px !important; padding-bottom: 14px !important; border-bottom: 0.5px solid #0F0F0F !important; }
        .gt_table_body tr:first-child td, .gt_table_body tr:first-child th { border-top: 0.5px solid #0F0F0F !important; }
        .gt_table_body tr:last-child td, .gt_table_body tr:last-child th { border-bottom: 0.5px solid #0F0F0F !important; }
        .gt_title { letter-spacing: -0.02em; }
        .gt_row { line-height: 1.55; background: %s !important; }
        .gt_row th, .gt_row td { background: %s !important; }
        .gt_striped, .gt_striped th, .gt_striped td { background: %s !important; }
        .gt_stub { background: %s !important; color: %s; font-size: %spx; border-right: none !important; }
        .gt_group_heading { background: %s !important; }
        .gt_summary_row, .gt_grand_summary_row { background: %s !important; }
        .gt_sourcenotes { border-top: 0.5px solid %s; border-bottom: 0.5px solid %s; padding-top: 20px !important; padding-bottom: 20px !important; font-style: normal !important; }
        .gt_sourcenotes .gt_sourcenote { padding-top: 20px !important; padding-bottom: 20px !important; }
        ",
        colors[["typst-ink"]],
        colors[["typst-ink"]],
        colors[["typst-ink"]],
        colors[["typst-ink"]],
        bg_color,
        bg_color,
        bg_color,
        bg_color,
        colors[["typst-fg-subtle"]],
        round(base_text_size * 1.09),
        bg_color,
        bg_color,
        colors[["typst-ink"]],
        colors[["typst-ink"]]
      )
    )
}

#' ChanWe GT Eyebrow Helper
#'
#' Returns an HTML `<div>` for use inside `gt::html()` in `tab_header(title =
#' ...)`. Renders an orange `──` rule followed by mono-caps JetBrains Mono
#' text above the main title, matching the [chanwe_title()] eyebrow treatment
#' in ggplot2.
#'
#' **Usage pattern:**
#' ```r
#' gt::tab_header(
#'   title = gt::html(paste0(chanwe_gt_eyebrow("SECTION LABEL"), "Title text"))
#' )
#' ```
#'
#' @param eyebrow Short label string shown above the title, e.g.
#'   `"SECTION · PEER BENCHMARK"`. Automatically upper-cased.
#'
#' @return An HTML string. Concatenate with the title string and wrap in
#'   [gt::html()].
#' @export
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'
#'   ## Single eyebrow + title
#'   gt::gt(head(mtcars, 5)) |>
#'     gt::tab_header(
#'       title = gt::html(paste0(
#'         chanwe_gt_eyebrow("SECTION · FLEET"),
#'         "Operational Snapshot"
#'       )),
#'       subtitle = "mtcars sample"
#'     ) |>
#'     gt_theme_chanwe()
#'
#'   ## With row stubs and source note
#'   mt <- tibble::as_tibble(mtcars, rownames = "model")
#'   gt::gt(head(mt, 6), rowname_col = "model") |>
#'     gt::tab_header(
#'       title = gt::html(paste0(
#'         chanwe_gt_eyebrow("OVERVIEW · Q1 2026"),
#'         "Fleet Performance"
#'       )),
#'       subtitle = "Weight, MPG and horsepower · mtcars"
#'     ) |>
#'     gt::tab_source_note("Source · Motor Trend, 1974") |>
#'     gt_theme_chanwe(bg_color = "beige")
#' }
chanwe_gt_eyebrow <- function(eyebrow) {
  color <- chanwe_get_colors()[["typst-primary"]]
  paste0(
    "<div style='font-family:\"JetBrains Mono\",monospace;font-size:7.5pt;",
    "font-weight:500;letter-spacing:0.12em;text-transform:uppercase;",
    "color:",
    color,
    ";margin-bottom:5px;'>",
    "── ",
    toupper(eyebrow),
    "</div>"
  )
}

#' ChanWe GT Header Helper
#'
#' Applies [gt::tab_header()] and optionally [gt::tab_source_note()] in a
#' single pipe step, with built-in support for the ChanWe eyebrow treatment.
#' When `eyebrow` is provided the title is automatically wrapped in
#' [gt::html()] with [chanwe_gt_eyebrow()] prepended — no manual
#' `paste0(chanwe_gt_eyebrow(...), title)` needed.
#'
#' ## Anatomy of a ChanWe gt header
#'
#' ```
#' ── SECTION · LABEL         ← eyebrow  (orange, JetBrains Mono, 7.5 pt)
#' Title text                 ← title    (Archivo Bold 700, ~40 px)
#' Subtitle text              ← subtitle (Archivo ExtraLight 200, ~16 px)
#' ─────────────────────────────────────────────────────────
#'  col A   col B   col C     ← table body
#'  ...
#' ─────────────────────────────────────────────────────────
#' Source · caption text      ← caption  (JetBrains Mono, ~10 px)
#' ```
#'
#' ## Parameter combinations
#'
#' | `eyebrow` | `subtitle` | `caption` | Result |
#' |-----------|------------|-----------|--------|
#' | `NULL` | `NULL` | `NULL` | Title only |
#' | set | `NULL` | `NULL` | Eyebrow + title |
#' | `NULL` | set | `NULL` | Title + subtitle |
#' | set | set | `NULL` | Eyebrow + title + subtitle |
#' | set | set | set | Full header — eyebrow, title, subtitle, caption |
#'
#' @param data A gt table object created with [gt::gt()].
#' @param title Main title string. Plain text; HTML is added automatically when
#'   `eyebrow` is not `NULL`.
#' @param subtitle Subtitle string rendered below the title in light-weight
#'   Archivo. `NULL` (default) omits the subtitle row entirely.
#' @param eyebrow Short section label shown above the title in orange
#'   JetBrains Mono mono-caps, preceded by an orange `──` rule
#'   (e.g. `"SECTION · FLEET"`). Automatically upper-cased. `NULL` (default)
#'   omits the eyebrow.
#' @param caption Source note string appended below the table body via
#'   [gt::tab_source_note()]. Styled in small JetBrains Mono by
#'   [gt_theme_chanwe()]. `NULL` (default) omits the source note.
#'
#' @return The input gt table with the header and optional source note applied.
#'   Returns a gt object that can be further piped into [gt_theme_chanwe()] or
#'   other gt functions.
#' @export
#'
#' @seealso [gt_theme_chanwe()], [chanwe_gt_eyebrow()]
#'
#' @examples
#' if (requireNamespace("gt", quietly = TRUE)) {
#'
#'   ## Title only — minimal header
#'   gt::gt(head(mtcars, 5)) |>
#'     chanwe_gt_header(title = "Motor Trend Cars") |>
#'     gt_theme_chanwe()
#'
#'   ## Title + subtitle, no eyebrow
#'   gt::gt(head(mtcars, 5)) |>
#'     chanwe_gt_header(
#'       title    = "Motor Trend Cars",
#'       subtitle = "Top 5 rows · mtcars dataset"
#'     ) |>
#'     gt_theme_chanwe()
#'
#'   ## Title + eyebrow, no subtitle
#'   gt::gt(head(mtcars, 5)) |>
#'     chanwe_gt_header(
#'       title   = "Fuel Efficiency Overview",
#'       eyebrow = "TLDR;"
#'     ) |>
#'     gt_theme_chanwe()
#'
#'   ## Full header — eyebrow, title, subtitle, caption
#'   mt <- tibble::as_tibble(mtcars, rownames = "model")
#'   gt::gt(head(mt, 6), rowname_col = "model") |>
#'     chanwe_gt_header(
#'       title    = "Operational Snapshot",
#'       subtitle = "Fleet overview · mtcars sample · Q1 2026",
#'       eyebrow  = "SECTION · OPERATIONAL",
#'       caption  = "Source · Motor Trend, 1974 · mtcars dataset"
#'     ) |>
#'     gt_theme_chanwe(bg_color = "beige")
#'
#'   ## Compact variant with gray background
#'   gt::gt(head(mtcars, 10)) |>
#'     chanwe_gt_header(
#'       title   = "Fleet Metrics",
#'       eyebrow = "DASHBOARD · Q1",
#'       caption = "Source · Motor Trend, 1974"
#'     ) |>
#'     gt_theme_chanwe(variant = "compact", bg_color = "gray")
#' }
chanwe_gt_header <- function(
  data,
  title,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL
) {
  chanwe_require_package("gt")

  title_content <- if (!is.null(eyebrow)) {
    gt::html(paste0(chanwe_gt_eyebrow(eyebrow), title))
  } else {
    title
  }

  out <- gt::tab_header(data, title = title_content, subtitle = subtitle)

  if (!is.null(caption)) {
    out <- gt::tab_source_note(out, caption)
  }

  out
}

#' ChanWe Spacious Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "spacious"`.
#'
#' @param data A gt table object.
#' @param bg_color Background color passed to [gt_theme_chanwe()]. Accepts hex strings or `"white"`, `"gray"`, `"beige"`.
#' @param base_text_size Base font size in pixels passed to [gt_theme_chanwe()]. Default `11`.
#' @param background Deprecated. Use `bg_color` instead.
#'
#' @return A themed gt table object.
#' @export
gt_theme_chanwe_spacious <- function(
  data,
  bg_color = "white",
  base_text_size = 11,
  background = NULL
) {
  if (!is.null(background)) {
    bg_color <- if (identical(background, "beige")) "#ECE5D8" else "#FFFFFF"
  }
  gt_theme_chanwe(
    data,
    variant = "spacious",
    bg_color = bg_color,
    base_text_size = base_text_size
  )
}

#' ChanWe Compact Theme for gt Tables
#'
#' Convenience wrapper for [gt_theme_chanwe()] with `variant = "compact"`.
#'
#' @param data A gt table object.
#' @param bg_color Background color passed to [gt_theme_chanwe()]. Accepts hex strings or `"white"`, `"gray"`, `"beige"`.
#' @param base_text_size Base font size in pixels passed to [gt_theme_chanwe()]. Default `11`.
#' @param background Deprecated. Use `bg_color` instead.
#'
#' @return A themed gt table object.
#' @export
gt_theme_chanwe_compact <- function(
  data,
  bg_color = "white",
  base_text_size = 11,
  background = NULL
) {
  if (!is.null(background)) {
    bg_color <- if (identical(background, "beige")) "#ECE5D8" else "#FFFFFF"
  }
  gt_theme_chanwe(
    data,
    variant = "compact",
    bg_color = bg_color,
    base_text_size = base_text_size
  )
}
