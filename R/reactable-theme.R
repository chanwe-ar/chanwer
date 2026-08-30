#' Chanwe Interactive Table via reactable (HTML)
#'
#' An interactive `reactable` styled with the same header grammar as
#' [chanwe_gt()] and [chanwe_kbl()]: eyebrow / title / subtitle block above
#' the table, `//`-prefixed caption below, mono-caps column labels, JetBrains
#' Mono tabular figures right-aligned, hairline ink rules, optional valence
#' colouring for signed columns.
#'
#' Interaction states follow the brand: the sortable header darkens on hover,
#' sort and pagination buttons respond on press (100 ms, no overshoot), the
#' current page sits on an ink background and page buttons turn brand orange
#' on hover.
#'
#' @param data A data frame or tibble.
#' @param title,subtitle,eyebrow Header block rendered above the table.
#' @param caption Source note rendered below the table with a `//` prefix.
#' @param signed Optional character vector of column names coloured by
#'   valence (positive green, negative vermillion, zero/NA neutral).
#' @param smaller_is_better Logical. Flip the valence mapping for `signed`
#'   columns. Default `FALSE`.
#' @param columns Optional named list of `reactable::colDef()` overrides,
#'   merged on top of the defaults this function builds (numeric columns are
#'   right-aligned in mono; `signed` columns get the valence style).
#' @param bg Table background. Named shorthand accepted by [theme_chanwe()]
#'   or any hex string. Default `"white"`.
#' @param ... Further arguments passed to `reactable::reactable()`
#'   (`defaultPageSize`, `searchable`, `defaultSorted`, ...). `highlight` and
#'   `borderless` default to `TRUE`; pass them explicitly to override.
#'
#' @return An `htmlwidget` of class `reactable`.
#' @export
#'
#' @examplesIf requireNamespace("reactable", quietly = TRUE) && requireNamespace("htmlwidgets", quietly = TRUE)
#' df <- data.frame(
#'   metric = c("Revenue", "EBITDA", "Net income"),
#'   value = c(45.9, 12.3, 8.1),
#'   delta = c(12.4, -3.1, 5.8)
#' )
#' tbl <- chanwe_reactable(
#'   df,
#'   title = "Quarterly deltas",
#'   eyebrow = "TABLE · P&L",
#'   caption = "Source · Internal ledger.",
#'   signed = "delta",
#'   columns = list(
#'     delta = reactable::colDef(
#'       name = "vs plan",
#'       cell = function(v) sprintf("%+.1f%%", v)
#'     )
#'   )
#' )
chanwe_reactable <- function(
  data,
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL,
  signed = NULL,
  smaller_is_better = FALSE,
  columns = list(),
  bg = "white",
  ...
) {
  chanwe_require_package("reactable")
  chanwe_require_package("htmlwidgets")
  tk <- chanwe_html_tokens()
  bg <- chanwe_resolve_bg(bg)
  ease <- "cubic-bezier(.2,.8,.2,1)"

  num_style <- list(
    fontFamily = .cw_font_mono,
    fontSize = "12px",
    fontVariantNumeric = "tabular-nums"
  )

  # Column defaults: numbers right-aligned in mono, text left in Satoshi.
  # Text cells stay at body weight and colour (400, fg) — the same as the
  # chanwe_gt() body — so a table of labels reads as data, not as a wall of
  # medium-weight ink. Emphasis belongs to the header block and signed cells.
  cols <- list()
  for (nm in names(data)) {
    cols[[nm]] <- if (is.numeric(data[[nm]])) {
      reactable::colDef(
        align = "right",
        style = num_style,
        headerStyle = list(textAlign = "right")
      )
    } else {
      reactable::colDef(
        align = "left",
        style = list(fontFamily = .cw_font_sans, fontWeight = 400, color = tk$fg)
      )
    }
  }
  for (nm in signed) {
    if (!nm %in% names(data)) {
      stop(sprintf("`signed` column '%s' not found in `data`.", nm), call. = FALSE)
    }
    force(smaller_is_better)
    cols[[nm]] <- reactable::colDef(
      align = "right",
      headerStyle = list(textAlign = "right"),
      style = function(value) {
        c(
          num_style,
          list(
            fontWeight = 500,
            color = chanwe_signed_color(value, tk, smaller_is_better)
          )
        )
      }
    )
  }
  for (nm in names(columns)) {
    cols[[nm]] <- if (is.null(cols[[nm]])) {
      columns[[nm]]
    } else {
      utils::modifyList(cols[[nm]], columns[[nm]])
    }
  }

  theme <- reactable::reactableTheme(
    color = tk$fg,
    backgroundColor = bg,
    borderColor = tk$n200,
    highlightColor = tk$n100,
    cellPadding = "10px 12px",
    style = list(fontFamily = .cw_font_sans, fontSize = "13px"),
    tableStyle = list(borderTop = paste("1px solid", tk$ink)),
    headerStyle = list(
      fontFamily = .cw_font_mono,
      fontSize = "10px",
      fontWeight = 500,
      letterSpacing = ".14em",
      textTransform = "uppercase",
      color = tk$fg_subtle,
      borderBottom = paste("1px solid", tk$n300),
      transition = paste("color 120ms", ease),
      "&:hover" = list(color = tk$ink),
      "&:active" = list(transform = "translateY(1px)")
    ),
    rowStyle = list(transition = paste("background-color 120ms", ease)),
    paginationStyle = list(
      fontFamily = .cw_font_mono,
      fontSize = "11px",
      color = tk$fg_muted,
      borderTop = paste("1px solid", tk$ink),
      padding = "10px 0 0"
    ),
    pageButtonStyle = list(
      borderRadius = "4px",
      padding = "5px 9px",
      transition = paste0(
        "transform 100ms ", ease, ", background-color 120ms ", ease,
        ", color 120ms ", ease
      ),
      "&:active" = list(transform = "scale(.94)")
    ),
    pageButtonHoverStyle = list(backgroundColor = tk$primary, color = "#FFFFFF"),
    pageButtonActiveStyle = list(
      backgroundColor = tk$primary_active,
      color = "#FFFFFF"
    ),
    pageButtonCurrentStyle = list(
      backgroundColor = tk$ink,
      color = "#FFFFFF",
      fontWeight = 500
    )
  )

  dots <- list(...)
  if (is.null(dots$highlight)) dots$highlight <- TRUE
  if (is.null(dots$borderless)) dots$borderless <- TRUE
  if (is.null(dots$theme)) dots$theme <- theme
  if (is.null(dots$columns)) dots$columns <- cols

  x <- do.call(reactable::reactable, c(list(data), dots))

  hdr <- chanwe_html_header_tag(title, subtitle, eyebrow)
  if (!is.null(hdr)) {
    x <- htmlwidgets::prependContent(x, hdr)
  }
  cap <- chanwe_html_caption_tag(caption)
  if (!is.null(cap)) {
    x <- htmlwidgets::appendContent(x, cap)
  }
  x$dependencies <- c(x$dependencies, chanwe_html_fonts_dependency())
  x
}
