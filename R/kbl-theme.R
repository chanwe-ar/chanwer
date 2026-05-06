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
#' @param eyebrow Small mono-caps label with an orange horizontal rule prefix.
#' @param caption Source note at the bottom in JetBrains Mono.
#' @param full_width Logical. If \code{TRUE}, columns share the full available
#'   width equally (\code{"1fr"} each). Overridden by \code{col_widths}.
#' @param col_widths Character vector of Typst column width specs, e.g.
#'   \code{c("1fr", "auto", "20\%")}. Defaults to \code{"auto"} for every column.
#' @param col_aligns Per-column alignment: \code{"left"}, \code{"right"}, or
#'   \code{"center"}. Single value is recycled. Defaults to auto-detect (right
#'   for numeric, left otherwise).
#' @param col_labels Named character vector to override displayed column names.
#' @param stub Name of the stub/row-identifier column. Displayed left-aligned
#'   in muted ink; excluded from auto numeric-alignment detection.
#' @param density \code{"spacious"} (default) or \code{"compact"}.
#' @param row_padding Typst size string overriding the vertical cell inset for
#'   data rows and column labels (e.g. \code{"6pt"}). Defaults to \code{"8pt"}
#'   (spacious) or \code{"3pt"} (compact).
#' @param title_size Typst size string for the title. Default \code{"19pt"} / \code{"13pt"}.
#' @param eyebrow_size Typst size string for the eyebrow. Default \code{"8.5pt"}.
#' @param subtitle_size Typst size string for the subtitle. Default \code{"11pt"} / \code{"9pt"}.
#' @param body_size Typst size string for data cell text. Default \code{"10pt"} / \code{"8pt"}.
#' @param header_size Typst size string for column label text. Default \code{"8pt"} / \code{"7pt"}.
#' @param note_size Typst size string for the footer note. Default \code{"8pt"} / \code{"7pt"}.
#' @param col_label_top Extra vertical space in pt above column label text
#'   (between the separator line and the labels). Default \code{0}.
#' @param footer_top Extra vertical space in pt above the footer note text.
#'   Default \code{0}.
#' @param bg Table background colour. Named shorthand: \code{"white"},
#'   \code{"beige"} (\code{#F7F3EE}), \code{"gray"} (\code{#F5F5F5}).
#'   Or any raw Typst color expression (e.g. \code{"rgb(\\\"#EEF0F2\\\")"}). Default \code{NULL} (transparent).
#' @param fmt Named list of formatting functions, keyed by column name.
#'   Each function receives the column vector and must return a character vector.
#'
#' @return A \code{\link[knitr]{asis_output}} containing a raw \code{{=typst}} block.
#'   Works in Quarto documents rendered with \code{format: chanwe-typst}.
#' @export
chanwe_kbl <- function(
  data,
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL,
  full_width = TRUE,
  col_widths = NULL,
  col_aligns = NULL,
  col_labels = NULL,
  stub = NULL,
  density = c("spacious", "compact"),
  row_padding = NULL,
  title_size = '18pt',
  eyebrow_size = '6pt',
  subtitle_size = '9pt',
  body_size = '7pt',
  header_size = '5.5pt',
  note_size = '7pt',
  col_label_top = 0,
  footer_top = 0,
  bg = NULL,
  top_border = TRUE,
  header_rule = TRUE,
  fmt = list()
) {
  chanwe_require_package("knitr")
  density <- match.arg(density)

  sp <- density == "spacious"

  inset_y <- if (!is.null(row_padding)) {
    row_padding
  } else if (sp) {
    "10pt"
  } else {
    "5pt"
  }
  title_pt <- if (!is.null(title_size)) {
    title_size
  } else if (sp) {
    "19pt"
  } else {
    "16pt"
  }
  eyebrow_pt <- if (!is.null(eyebrow_size)) eyebrow_size else "8.5pt"
  sub_pt <- if (!is.null(subtitle_size)) {
    subtitle_size
  } else if (sp) {
    "11pt"
  } else {
    "10pt"
  }
  body_pt <- if (!is.null(body_size)) {
    body_size
  } else if (sp) {
    "10pt"
  } else {
    "7pt"
  }
  label_pt <- if (!is.null(header_size)) {
    header_size
  } else if (sp) {
    "8pt"
  } else {
    "7pt"
  }
  note_pt <- if (!is.null(note_size)) {
    note_size
  } else if (sp) {
    "8pt"
  } else {
    "7pt"
  }

  top_v <- if (sp) "2pt" else "2pt" # space inside title cell before eyebrow
  bot_v <- if (sp) "2pt" else "2pt" # space inside subtitle cell before separator

  n <- ncol(data)
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
    col_aligns <- vapply(
      seq_len(n),
      function(i) {
        if (!is.null(stub) && nms[i] == stub) {
          return("left")
        }
        if (is.numeric(data[[i]])) "right" else "left"
      },
      character(1)
    )
  } else if (length(col_aligns) == 1L) {
    col_aligns <- rep(col_aligns, n)
  }

  widths <- if (!is.null(col_widths)) {
    col_widths
  } else if (full_width) {
    rep("1fr", n)
  } else {
    rep("auto", n)
  }

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
    x <- gsub("[", "\\[", x, fixed = TRUE)
    x <- gsub("]", "\\]", x, fixed = TRUE)
    x <- gsub("#", "\\#", x, fixed = TRUE)
    x <- gsub("@", "\\@", x, fixed = TRUE)
    x <- gsub("_", "\\_", x, fixed = TRUE)
    x <- gsub("*", "\\*", x, fixed = TRUE)
    x <- gsub("`", "\\`", x, fixed = TRUE)
    x <- gsub("$", "\\$", x, fixed = TRUE)
    x <- gsub("<", "\\<", x, fixed = TRUE)
    x
  }

  pt_v <- function(n) if (n > 0) paste0("#v(", n, "pt, weak: false)") else ""

  # per-cell inset strings — header cells get tight bottom/top to avoid
  # excessive gap between title, subtitle, and separator
  inset_title <- paste0("(top: ", inset_y, ", bottom: 5pt, x: 2.5mm)")
  inset_sub <- paste0("(top: 4pt, bottom: ", inset_y, ", x: 2.5mm)")
  colhdr_top <- if (sp) "20pt" else "14pt"
  inset_colhdr <- paste0(
    "(top: ",
    colhdr_top,
    ", bottom: ",
    inset_y,
    ", x: 2.5mm)"
  )
  footer_top_inset <- if (sp) "10pt" else "9pt"
  inset_footer <- paste0(
    "(top: ",
    footer_top_inset,
    ", bottom: ",
    inset_y,
    ", x: 2.5mm)"
  )

  bg_fill <- if (is.null(bg)) {
    ""
  } else {
    fill_val <- switch(
      bg,
      "white" = "white",
      "beige" = 'rgb("#F7F3EE")',
      "cream" = 'rgb("#F7F3EE")',
      "gray" = 'rgb("#F5F5F5")',
      "grey" = 'rgb("#F5F5F5")',
      bg
    )
    paste0(", fill: ", fill_val)
  }

  # code builder
  L <- character(0)
  p <- function(...) L <<- c(L, paste0(...))

  p(
    "#{ set table(inset: (x: 2.5mm, y: ",
    inset_y,
    "), stroke: none",
    bg_fill,
    ")"
  )
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
        # chanwe-eyebrow with-rule: true renders "---- TEXT" matching template style
        inner <- paste0(
          "#v(",
          top_v,
          ", weak: false)",
          '#chanwe-eyebrow(with-rule: true, size: ',
          eyebrow_pt,
          ')[',
          esc(eyebrow),
          ']',
          "#v(8pt, weak: false)"
        )
      }
      if (!is.null(title)) {
        inner <- paste0(
          inner,
          '#text(font: "Archivo", size: ',
          title_pt,
          ', fill: _t.ink, weight: "bold")[',
          esc(title),
          ']'
        )
      }
      p(
        "      table.cell(align: left, colspan: ",
        n,
        ", inset: ",
        inset_title,
        if (top_border) ", stroke: (top: 0.1pt + _t.ink)" else "",
        ")[",
        inner,
        "],"
      )
    }

    if (!is.null(subtitle)) {
      p(
        "      table.cell(align: left, colspan: ",
        n,
        ", inset: ",
        inset_sub,
        ")[",
        '#text(font: "Satoshi", size: ',
        sub_pt,
        ', fill: _t.fg-muted, weight: "regular")[',
        esc(subtitle),
        ']',
        "#v(",
        bot_v,
        ", weak: false)",
        "],"
      )
    }

    if (header_rule) {
      p("      table.hline(stroke: 0.7pt + _t.ink),")
    }

    for (i in seq_len(n)) {
      p(
        "      table.cell(align: ",
        col_aligns[i],
        ", inset: ",
        inset_colhdr,
        ")[",
        pt_v(col_label_top),
        '#text(font: "JetBrains Mono", size: ',
        label_pt,
        ', fill: _t.fg-subtle, weight: "regular", tracking: 0.05em)[',
        esc(toupper(labels[i])),
        ']],'
      )
    }

    p("    ),")
  }

  p("    table.hline(stroke: 0.1pt + _t.ink),")

  nr <- nrow(data)
  for (i in seq_len(nr)) {
    for (j in seq_len(n)) {
      val <- esc(fmt_data[[j]][i])
      is_first <- j == 1L
      fill <- if (is_first) "_t.ink" else "_t.fg-muted"
      weight <- if (is_first) '"bold"' else '"regular"'
      p(
        "    table.cell(align: ",
        col_aligns[j],
        ")[",
        '#text(font: "JetBrains Mono", size: ',
        body_pt,
        ', fill: ',
        fill,
        ', weight: ',
        weight,
        ')[',
        val,
        "]],"
      )
    }
    if (i < nr) p('    table.hline(stroke: 0.3pt + rgb("#E9E9E9")),')
  }

  p("    table.hline(stroke: 0.5pt + _t.ink),")

  if (!is.null(caption)) {
    p("    table.footer(")
    p("      table.hline(stroke: 0.3pt + _t.ink),")
    p(
      "      table.cell(colspan: ",
      n,
      ", align: left, inset: ",
      inset_footer,
      ")[",
      pt_v(footer_top),
      '#text(font: "JetBrains Mono", size: ',
      note_pt,
      ', fill: _t.fg-subtle)[',
      '#text(fill: _t.primary)[/\\/]',
      esc(caption),
      ']],'
    )
    p("    )")
  } else {
    p("    table.footer(table.hline(stroke: 0.1pt + _t.ink))")
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
