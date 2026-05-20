#' ChanWe Table via Native Typst Output
#'
#' Generates a styled Typst table directly from a data frame, bypassing the
#' HTML→Pandoc→Typst pipeline. Archivo title, Satoshi body, JetBrains Mono
#' column headers, thin ink divider lines. No CSS translation losses.
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
#' @param title_size Typst size string for the title. Default \code{"16pt"}.
#' @param eyebrow_size Typst size string for the eyebrow. Default \code{"8.5pt"}.
#' @param subtitle_size Typst size string for the subtitle. Default \code{"11pt"} / \code{"9pt"}.
#' @param body_size Typst size string for data cell text. Default \code{"10pt"} / \code{"8pt"}.
#' @param header_size Typst size string for column label text. Default \code{"8pt"} / \code{"7pt"}.
#' @param note_size Typst size string for the footer note. Default \code{"8pt"} / \code{"7pt"}.
#' @param col_label_top Extra vertical space in pt above column label text
#'   (between the separator line and the labels). Default \code{0}.
#' @param footer_top Extra vertical space in pt above the footer note text.
#'   Default \code{0}.
#' @param bg Table background colour. Named shorthand: \code{"white-ivory"}
#'   (default, \code{#FAF9F7}), \code{"white"}, \code{"beige"} (\code{#F5F1EB}),
#'   \code{"gray"} (\code{#EDF0F1}), \code{"metallic"} (\code{#F7F7F7}).
#'   Or any raw Typst color expression (e.g. \code{"rgb(\\\"#EEF0F2\\\")"}). Pass \code{NULL} for transparent.
#' @param padding Uniform outer margin in pts applied around the entire table
#'   block (equivalent to \code{plot_padding} in \code{theme_chanwe()}). Default \code{0}.
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
  title_size = '13pt',
  eyebrow_size = '4pt',
  subtitle_size = '8pt',
  body_size = '7pt',
  header_size = '5.5pt',
  note_size = '5.5pt',
  col_label_top = 0,
  footer_top = 0,
  bg = "white-ivory",
  top_border = TRUE,
  header_rule = TRUE,
  padding = 12.5,
  fmt = list(),
  col_colors = list(),
  n_total = 0,
  total_fill = TRUE,
  vlines = NULL,
  highlight_cols = NULL,
  highlight_color = "#F5F1EB"
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
  eyebrow_pt <- if (!is.null(eyebrow_size)) eyebrow_size else "4pt"
  sub_pt <- if (!is.null(subtitle_size)) {
    subtitle_size
  } else if (sp) {
    "10pt"
  } else {
    "9pt"
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

  top_v <- if (sp) "4pt" else "2pt" # space inside title cell before eyebrow
  bot_v <- if (sp) "8pt" else "4pt" # space inside subtitle cell before separator

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

  # apply color functions (original numeric data → Typst color strings, not escaped)
  color_data <- vector("list", n)
  for (nm in names(col_colors)) {
    idx <- match(nm, nms)
    if (!is.na(idx)) color_data[[idx]] <- col_colors[[nm]](data[[idx]])
  }

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
  title_bot <- if (is.null(subtitle)) (if (sp) "14pt" else "10pt") else "3pt"
  inset_title <- paste0("(top: ", inset_y, ", bottom: ", title_bot, ", x: 2.5mm)")
  inset_sub <- paste0("(top: 3pt, bottom: ", inset_y, ", x: 2.5mm)")
  colhdr_top <- if (!is.null(subtitle)) {
    if (sp) "20pt" else "14pt"
  } else if (!is.null(title) || !is.null(eyebrow)) {
    if (sp) "18pt" else "16pt"
  } else {
    if (sp) "6pt" else "4pt"
  }
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

  fill_val <- if (is.null(bg)) {
    NULL
  } else {
    switch(
      bg,
      "white-ivory" = 'rgb("#FAF9F7")',
      "ivory" = 'rgb("#FAF9F7")',
      "white" = "white",
      "beige" = 'rgb("#F5F1EB")',
      "cream" = 'rgb("#F5F1EB")',
      "gray" = 'rgb("#EDF0F1")',
      "grey" = 'rgb("#EDF0F1")',
      "metallic" = 'rgb("#F7F7F7")',
      "silver" = 'rgb("#F7F7F7")',
      "transparent" = "none",
      bg
    )
  }
  bg_fill <- if (!is.null(fill_val)) paste0(", fill: ", fill_val) else ""
  row_divider_color <- if (!is.null(bg) && tolower(bg) %in% c("metallic", "silver")) {
    "#D4D4D4"
  } else {
    "#E9E9E9"
  }

  # code builder
  L <- character(0)
  p <- function(...) L <<- c(L, paste0(...))

  p(
    "#{ set text(size: 10pt, fill: _t.ink, weight: \"regular\", tracking: 0pt, style: \"normal\"); set table(inset: (x: 2.5mm, y: ",
    inset_y,
    "), stroke: none",
    bg_fill,
    ")"
  )
  p("  [")
  p("  #table(")
  p("    columns: (", paste(widths, collapse = ", "), "),")
  p("    align: (", paste(col_aligns, collapse = ", "), ",),")

  if (!is.null(vlines)) {
    for (vx in vlines) {
      p('    table.vline(x: ', vx, ', stroke: 0.4pt + rgb("#DADADA")),')
    }
  }

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
          "#v(-6pt, weak: false)"
        )
      }
      if (!is.null(title)) {
        inner <- paste0(
          inner,
          '#text(font: "Archivo", size: ',
          title_pt,
          ', fill: _t.ink, weight: "medium")[',
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
      hdr_fill <- if (!is.null(highlight_cols) && i %in% highlight_cols) paste0(', fill: rgb("', highlight_color, '")') else ""
      p(
        "      table.cell(align: ",
        col_aligns[i],
        ", inset: ",
        inset_colhdr,
        hdr_fill,
        ")[",
        pt_v(col_label_top),
        '#text(font: "JetBrains Mono", size: ',
        label_pt,
        ', fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[',
        esc(toupper(labels[i])),
        ']],'
      )
    }

    p("    ),")
  }

  p("    table.hline(stroke: 0.1pt + _t.ink),")

  nr <- nrow(data)
  total_start <- if (n_total > 0) nr - n_total + 1L else nr + 1L
  for (i in seq_len(nr)) {
    is_total <- i >= total_start
    if (is_total && i == total_start) {
      p("    table.hline(stroke: 0.7pt + _t.ink),")
    }
    for (j in seq_len(n)) {
      val <- esc(fmt_data[[j]][i])
      is_first <- j == 1L
      base_fill <- if (is_first) "_t.ink" else "_t.ink"
      fill <- if (!is.null(color_data[[j]])) color_data[[j]][i] else base_fill
      weight <- if (is_first) '"medium"' else '"thin"'
      cell_fill <- if (is_total && total_fill) {
        ', fill: rgb("#F3F3F3")'
      } else if (!is.null(highlight_cols) && j %in% highlight_cols) {
        paste0(', fill: rgb("', highlight_color, '")')
      } else {
        ""
      }
      p(
        "    table.cell(align: ",
        col_aligns[j],
        cell_fill,
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
    if (i < nr && !is_total) {
      p('    table.hline(stroke: 0.3pt + rgb("', row_divider_color, '")),')
    }
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
      ', fill: _t.ink)[',
      '#text(fill: _t.primary)[/\\/]#h(4pt)',
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

  pad_fill <- if (!is.null(fill_val)) paste0(", fill: ", fill_val) else ""

  if (padding > 0) {
    L <- c(
      paste0("#block(inset: (x: ", padding, "pt, y: 0pt)", pad_fill, ")["),
      L,
      "]"
    )
  }

  # Wrap in a block with above/below spacing so the table gets the same
  # breathing room as native Typst content blocks (raw {=typst} blocks skip it).
  L <- c(
    "#block(above: 2.5em, below: 2.5em)[",
    L,
    "]"
  )

  knitr::asis_output(paste0(
    "\n```{=typst}\n",
    paste(L, collapse = "\n"),
    "\n```\n"
  ))
}
