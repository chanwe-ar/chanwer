#' ChanWe Table via Native Typst Output
#'
#' Generates a styled Typst table directly from a data frame, bypassing the
#' HTML→Pandoc→Typst pipeline. Matches the visual design of
#' [gt_theme_chanwe()]: Archivo title, Satoshi body, JetBrains Mono column
#' headers, thin ink divider lines. No CSS translation losses.
#'
#' @param data A data frame or tibble.
#' @param title Table title.
#' @param subtitle Subtitle line rendered below the title.
#' @param eyebrow Small mono-caps label above the title in primary orange,
#'   prefixed with an orange vertical rule.
#' @param caption Source note at the bottom in JetBrains Mono.
#' @param col_widths Character vector of Typst column width specs, e.g.
#'   \code{c("1fr", "auto", "20\%")}. Defaults to \code{"auto"} for every column.
#' @param col_aligns Per-column alignment: \code{"left"}, \code{"right"}, or
#'   \code{"center"}. Single value is recycled. Defaults to auto-detect (right
#'   for numeric, left otherwise).
#' @param col_labels Named character vector to override displayed column names.
#' @param stub Name of the stub/row-identifier column. Displayed left-aligned
#'   in muted ink; excluded from auto numeric-alignment detection.
#' @param density \code{"spacious"} (default) or \code{"compact"}.
#' @param title_size Typst size string for the title. Default \code{"19pt"} / \code{"13pt"}.
#' @param eyebrow_size Typst size string for the eyebrow. Default \code{"7pt"} / \code{"6pt"}.
#' @param subtitle_size Typst size string for the subtitle. Default \code{"11pt"} / \code{"9pt"}.
#' @param body_size Typst size string for data cell text. Default \code{"10pt"} / \code{"8pt"}.
#' @param label_size Typst size string for column label text. Default \code{"8pt"} / \code{"7pt"}.
#' @param note_size Typst size string for the footer note. Default \code{"8pt"} / \code{"7pt"}.
#' @param col_label_top Extra vertical space in pt above column label text
#'   (between the separator line and the labels). Default \code{0}.
#' @param footer_top Extra vertical space in pt above the footer note text.
#'   Default \code{0}.
#' @param fmt Named list of formatting functions, keyed by column name.
#'   Each function receives the column vector and must return a character vector.
#'
#' @return A \code{\link[knitr]{asis_output}} containing a raw \code{{=typst}} block.
#'   Works in Quarto documents rendered with \code{format: chanwe-typst}.
#' @export
chanwe_kbl <- function(
  data,
  title         = NULL,
  subtitle      = NULL,
  eyebrow       = NULL,
  caption       = NULL,
  col_widths    = NULL,
  col_aligns    = NULL,
  col_labels    = NULL,
  stub          = NULL,
  density       = c("spacious", "compact"),
  title_size    = NULL,
  eyebrow_size  = NULL,
  subtitle_size = NULL,
  body_size     = NULL,
  label_size    = NULL,
  note_size     = NULL,
  col_label_top = 0,
  footer_top    = 0,
  fmt           = list()
) {
  chanwe_require_package("knitr")
  density <- match.arg(density)

  sp <- density == "spacious"

  title_pt   <- title_size    %||% if (sp) "19pt" else "13pt"
  eyebrow_pt <- eyebrow_size  %||% if (sp) "7pt"  else "6pt"
  sub_pt     <- subtitle_size %||% if (sp) "11pt" else "9pt"
  body_pt    <- body_size     %||% if (sp) "10pt" else "8pt"
  label_pt   <- label_size    %||% if (sp) "8pt"  else "7pt"
  note_pt    <- note_size     %||% if (sp) "8pt"  else "7pt"

  top_v   <- if (sp) "6pt" else "4pt"   # space inside title cell before eyebrow
  bot_v   <- if (sp) "5pt" else "1pt"   # space inside subtitle cell before separator
  inset_y <- if (sp) "8pt" else "3pt"   # cell y-inset (controls data row height)

  n   <- ncol(data)
  nms <- colnames(data)

  # displayed column labels
  labels <- nms
  if (!is.null(col_labels)) {
    for (nm in names(col_labels)) {
      idx <- match(nm, nms)
      if (!is.na(idx)) labels[idx] <- col_labels[[nm]]
    }
  }

  # column alignment: stub always left, others auto-detect
  if (is.null(col_aligns)) {
    col_aligns <- vapply(seq_len(n), function(i) {
      if (!is.null(stub) && nms[i] == stub) return("left")
      if (is.numeric(data[[i]])) "right" else "left"
    }, character(1))
  } else if (length(col_aligns) == 1L) {
    col_aligns <- rep(col_aligns, n)
  }

  widths <- if (is.null(col_widths)) rep("auto", n) else col_widths

  # apply format functions
  fmt_data <- data
  for (nm in names(fmt)) {
    idx <- match(nm, nms)
    if (!is.na(idx)) fmt_data[[idx]] <- fmt[[nm]](data[[idx]])
  }
  fmt_data <- lapply(fmt_data, as.character)

  # Typst escape: characters special in markup mode
  esc <- function(x) {
    x <- as.character(x)
    x <- gsub("\\\\", "\\\\\\\\", x, perl = FALSE)
    x <- gsub("[",  "\\[",  x, fixed = TRUE)
    x <- gsub("]",  "\\]",  x, fixed = TRUE)
    x <- gsub("#",  "\\#",  x, fixed = TRUE)
    x <- gsub("@",  "\\@",  x, fixed = TRUE)
    x <- gsub("_",  "\\_",  x, fixed = TRUE)
    x <- gsub("*",  "\\*",  x, fixed = TRUE)
    x <- gsub("`",  "\\`",  x, fixed = TRUE)
    x <- gsub("$",  "\\$",  x, fixed = TRUE)
    x <- gsub("<",  "\\<",  x, fixed = TRUE)
    x
  }

  pt_v <- function(n) if (n > 0) paste0("#v(", n, "pt, weak: false)") else ""

  # orange vertical rule prefix rendered before eyebrow text
  eyebrow_prefix <- '#box(height: 0.65em, width: 2pt, fill: _t.primary)#h(4pt)'

  # code builder
  L <- character(0)
  p <- function(...) L <<- c(L, paste0(...))

  p("#{ set table(inset: (x: 2.5mm, y: ", inset_y, "), stroke: none)")
  p("  [")
  p("  #table(")
  p("    columns: (", paste(widths, collapse = ", "), "),")
  p("    align: (", paste(col_aligns, collapse = ", "), ",),")

  has_hdr <- !is.null(title) || !is.null(eyebrow) || !is.null(subtitle)
  if (has_hdr) {
    p("    table.header(")

    if (!is.null(title) || !is.null(eyebrow)) {
      inner <- ""
      if (!is.null(eyebrow)) {
        inner <- paste0(
          "#v(", top_v, ", weak: false)",
          eyebrow_prefix,
          '#text(font: "JetBrains Mono", size: ', eyebrow_pt,
          ', fill: _t.primary, weight: "regular", tracking: 0.05em)[',
          esc(toupper(eyebrow)), ']',
          "#linebreak()"
        )
      }
      if (!is.null(title)) {
        inner <- paste0(
          inner,
          '#text(font: "Archivo", size: ', title_pt,
          ', fill: _t.ink, weight: "bold")[', esc(title), ']'
        )
      }
      p("      table.cell(align: left, colspan: ", n,
        ", stroke: (top: 0.5pt + _t.ink))[", inner, "],")
    }

    if (!is.null(subtitle)) {
      p("      table.cell(align: left, colspan: ", n, ")[",
        '#text(font: "Satoshi", size: ', sub_pt,
        ', fill: _t.fg-muted, weight: "regular")[', esc(subtitle), ']',
        "#v(", bot_v, ", weak: false)",
        "],")
    }

    p("      table.hline(stroke: 0.5pt + _t.ink),")

    for (i in seq_len(n)) {
      p("      table.cell(align: ", col_aligns[i], ")[",
        pt_v(col_label_top),
        '#text(font: "JetBrains Mono", size: ', label_pt,
        ', fill: _t.fg-subtle, weight: "regular", tracking: 0.05em)[',
        esc(toupper(labels[i])), ']],')
    }

    p("    ),")
  }

  p("    table.hline(stroke: 0.5pt + _t.ink),")

  nr <- nrow(data)
  for (i in seq_len(nr)) {
    for (j in seq_len(n)) {
      val     <- esc(fmt_data[[j]][i])
      is_stub <- !is.null(stub) && nms[j] == stub
      fill    <- if (is_stub) "_t.fg-muted" else "_t.fg"
      p("    table.cell(align: ", col_aligns[j], ")[",
        '#text(font: "Satoshi", size: ', body_pt,
        ', fill: ', fill, ', weight: "regular")[', val, "]],")
    }
  }

  p("    table.hline(stroke: 0.5pt + _t.ink),")

  if (!is.null(caption)) {
    p("    table.footer(")
    p("      table.hline(stroke: 0.5pt + _t.ink),")
    p("      table.cell(colspan: ", n, ", align: left)[",
      pt_v(footer_top),
      '#text(font: "JetBrains Mono", size: ', note_pt,
      ', fill: _t.fg-subtle)[',
      '#text(fill: _t.primary)[/\\/]', esc(caption), ']],')
    p("    )")
  } else {
    p("    table.footer(table.hline(stroke: 0.5pt + _t.ink))")
  }

  p("  )")
  p("  ]")
  p("}")

  knitr::asis_output(paste0(
    "\n```{=typst}\n",
    paste(L, collapse = "\n"),
    "\n```\n"
  ))
}
