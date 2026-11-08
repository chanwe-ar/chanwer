#' Chanwe Table via Native Typst Output
#'
#' Generates a styled Typst table directly from a data frame, bypassing the
#' HTML→Pandoc→Typst pipeline. The table is a v2 pane: a rounded block with a
#' hairline, the column labels on the slate tint, hairline rows. Schibsted
#' Grotesk title, Satoshi subtitle and text cells, JetBrains Mono column
#' labels and right-aligned figures (mono keeps them tabular so numeric
#' columns align digit-for-digit), the source line as a mono label. Colours,
#' fonts and radii come from the generated tokens (\code{chanwe_tokens}).
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
#'   data rows and column labels (e.g. \code{"6pt"}). Defaults to \code{"10pt"}
#'   (spacious) or \code{"5pt"} (compact).
#' @param title_size Typst size string for the title. Default \code{"13pt"};
#'   pass \code{NULL} for the density-based default (\code{"19pt"} spacious /
#'   \code{"16pt"} compact).
#' @param eyebrow_size Typst size string for the eyebrow. Default \code{"4pt"}.
#' @param subtitle_size Typst size string for the subtitle. Default \code{"8pt"};
#'   \code{NULL} for the density-based default (\code{"10pt"} / \code{"9pt"}).
#' @param body_size Typst size string for data cell text. Default \code{"7pt"};
#'   \code{NULL} for the density-based default (\code{"10pt"} / \code{"7pt"}).
#' @param header_size Typst size string for column label text. Default
#'   \code{"5.5pt"}; \code{NULL} for the density-based default
#'   (\code{"8pt"} / \code{"7pt"}).
#' @param note_size Typst size string for the footer note. Default
#'   \code{"5.5pt"}; \code{NULL} for the density-based default
#'   (\code{"8pt"} / \code{"7pt"}).
#' @param col_label_top Extra vertical space in pt above column label text
#'   (between the separator line and the labels). Default \code{0}.
#' @param footer_top Extra vertical space in pt above the footer note text.
#'   Default \code{0}.
#' @param bg Table background colour. Named shorthand for the brand surfaces:
#'   \code{"paper"} (default, \code{#F8FAFC}), \code{"white"},
#'   \code{"sunken"} (\code{#F1F5F9}), \code{"slate"} (\code{#EBF0F6}); the
#'   earlier \code{"white-ivory"}, \code{"metallic"} and \code{"gray"} resolve
#'   to paper / paper / slate. Or any raw Typst color expression (e.g.
#'   \code{"rgb(\\\"#EBF0F6\\\")"}). Pass \code{NULL} for transparent.
#' @param top_border Logical. Draw a slate hairline above the title cell.
#'   Default \code{NULL}: \code{FALSE} for a pane (its border closes the
#'   top), \code{TRUE} with \code{pane = FALSE}.
#' @param header_rule Logical. Draw the heavier rule between the title block
#'   and the column labels. Default \code{TRUE}.
#' @param padding Uniform outer margin in pts applied around the entire table
#'   block (equivalent to \code{plot_padding} in \code{theme_chanwe()}).
#'   Default \code{12.5}.
#' @param fmt Named list of formatting functions, keyed by column name.
#'   Each function receives the column vector and must return a character vector.
#' @param col_colors Named list of functions, keyed by column name. Each
#'   function receives the column's \emph{original} values — before \code{fmt}
#'   is applied — and must return a character vector of raw Typst color
#'   expressions (e.g. \code{"rgb(\\\"#CC1914\\\")"}, not escaped) used as the
#'   text fill for each cell. This is deliberate: color logic can branch on
#'   raw numbers (e.g. the sign of a delta) even when \code{fmt} renders the
#'   same column as text. For the standard positive/negative treatment use
#'   \code{\link{chanwe_col_signed}()} — see the examples.
#' @param n_total Number of trailing rows to treat as total rows. Total rows
#'   get a heavier rule above them, no row dividers, and (optionally) a
#'   highlight fill. Default \code{0} (no total rows).
#' @param total_fill Logical. Fill total rows with the slate tint. Default
#'   \code{FALSE} since 3.2.0: a total row is set off by a 0.75pt ink rule
#'   above it and the medium weight, not by a fill (the tint is the header's).
#'   Only used when \code{n_total > 0}. Default \code{TRUE}.
#' @param vlines Optional integer vector of column indices at which to draw
#'   vertical divider lines (Typst \code{table.vline} x positions).
#' @param highlight_cols Optional integer vector of column indices whose header
#'   and data cells get a highlight background fill.
#' @param highlight_color Hex color for \code{highlight_cols} fill.
#'   Default \code{NULL}: the \code{surface-slate} token (\code{#EBF0F6}).
#' @param pane Logical. Draw the table as a v2 pane (brand-v2 Q1 B): a block
#'   with the 16px surface radius (scaled to the document like the type, 8pt
#'   at the default 7pt body), a hairline border, column labels on the slate
#'   tint and no outer fill around it. Default \code{TRUE}; \code{FALSE} draws
#'   the open chanwer 2.x table.
#' @param header The figure frame's header card, as in [chanwe_figure()]:
#'   \code{"A"} (the obsidian band with the eyebrow and the tag), \code{"C"}
#'   (the numeral), \code{"D"} (two columns), \code{"dark"}. \code{NULL}
#'   (default) keeps the title rows inside the table.
#' @param header_fill \code{"tint"} or \code{"none"}.
#' @param tag The section or series at the right of the header. The ID goes
#'   to \code{id}, in the footer.
#' @param numeral The table number, for \code{header = "C"}.
#' @param footer \code{"rule"} (a hairline, the ID in a white pill) or
#'   \code{"tint"} (a tinted strip). \code{NULL} keeps the caption row.
#' @param source,source_label,id The footer's source, its label and the
#'   document ID. \code{source} defaults to \code{caption}.
#' @param frame \code{"simple"}, \code{"shadow"} or \code{"none"}; replaces
#'   \code{pane} when set.
#' @param total_style \code{"ink"} (an ink rule over the total), \code{"tint"}
#'   or \code{"band"} (the total row on obsidian).
#' @param delta_style How a \code{chanwe_col_signed()} column draws:
#'   \code{"pill"}, \code{"arrow"} or \code{"bar"} (a bar from the centre).
#' @param caption_style \code{"mono"} (v2 default): the source line as a
#'   JetBrains Mono label. \code{"stamp"}: the orange stamp of chanwer 2.x.
#'   \code{NULL} reads \code{getOption("chanwer.caption_style", "mono")}.
#'
#' @return A \code{\link[knitr]{asis_output}} containing a raw \code{{=typst}} block.
#'   Works in Quarto documents rendered with \code{format: chanwe-report-typst}.
#'
#' @examplesIf requireNamespace("knitr", quietly = TRUE)
#' df <- data.frame(
#'   metric = c("Revenue", "EBITDA", "Net income"),
#'   delta = c(12.4, -3.1, 5.8)
#' )
#'
#' ## Signed-deltas pattern: fmt renders the delta as text, while the
#' ## col_colors function still receives the raw numbers and colors by sign
#' ## using the canonical Chanwe signed tokens.
#' chanwe_kbl(
#'   df,
#'   title = "Quarterly deltas",
#'   fmt = list(delta = function(x) sprintf("%+.1f%%", x)),
#'   col_colors = list(delta = chanwe_col_signed())
#' )
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
  bg = "paper",
  top_border = NULL,
  header_rule = TRUE,
  padding = 12.5,
  fmt = list(),
  col_colors = list(),
  n_total = 0,
  total_fill = FALSE,
  vlines = NULL,
  highlight_cols = NULL,
  highlight_color = NULL,
  pane = TRUE,
  caption_style = NULL,
  header = NULL,
  header_fill = c("tint", "none"),
  tag = NULL,
  numeral = NULL,
  footer = NULL,
  source = NULL,
  source_label = "Fuente",
  id = NULL,
  frame = NULL,
  total_style = c("ink", "tint", "band"),
  delta_style = c("pill", "arrow", "bar")
) {
  chanwe_require_package("knitr")
  density <- match.arg(density)
  header_fill <- match.arg(header_fill)
  total_style <- match.arg(total_style)
  delta_style <- match.arg(delta_style)
  if (!is.null(header)) header <- match.arg(header, c("A", "C", "D", "dark"))
  if (!is.null(footer)) footer <- match.arg(footer, c("rule", "tint"))
  if (!is.null(frame)) frame <- match.arg(frame, c("simple", "shadow", "none"))
  if (identical(total_style, "tint")) total_fill <- TRUE
  # The figure frame (chanwer 3.2.0): with `header`, the title block is a card
  # above the table, the same as chanwe_figure(); with `footer`, the source and
  # the ID close it. The table itself keeps only its column labels and body.
  card_title <- title; card_subtitle <- subtitle; card_eyebrow <- eyebrow
  if (!is.null(header)) { title <- NULL; subtitle <- NULL; eyebrow <- NULL }
  if (!is.null(footer)) { if (is.null(source)) source <- caption; caption <- NULL }
  if (!is.null(frame)) pane <- frame == "simple"
  caption_style <- chanwe_caption_style(caption_style)
  if (is.null(top_border)) top_border <- !isTRUE(pane)

  sp <- density == "spacious"

  # Every value comes from the generated tokens (chanwe_tokens, from
  # tokens.json): colours, fonts, the type scale and the radii.
  tokens <- chanwe_get_colors()
  fonts <- chanwe_tokens$fonts
  typst_rgb <- function(hex) paste0('rgb("', hex, '")')
  # v2-print (brand-v2 Q1 B): hairlines are `rule`, fills are the slate
  # tint (the text colour at 7%), never a grey.
  hairline <- tokens[["rule"]]
  tint <- tokens[["tint"]]
  vline_color <- hairline
  total_fill_color <- tint
  if (is.null(highlight_color)) highlight_color <- tokens[["surface-slate"]]

  inset_y <- if (!is.null(row_padding)) {
    row_padding
  } else if (sp) {
    "10pt"
  } else {
    "3.4pt"
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
    "6.5pt"
  }
  label_pt <- if (!is.null(header_size)) {
    header_size
  } else if (sp) {
    "8pt"
  } else {
    "6pt"
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

  # apply color functions — deliberately on the ORIGINAL (pre-fmt) values, so
  # color logic can branch on raw numbers even when fmt renders text; the
  # returned Typst color expressions are used verbatim (not escaped)
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
    surface <- chanwe_surface_name(bg)
    if (identical(tolower(trimws(bg)), "transparent")) {
      "none"
    } else if (is.na(surface)) {
      bg
    } else {
      paste0('rgb("', .chanwe_surfaces[[surface]][["fill"]], '")')
    }
  }
  bg_fill <- if (!is.null(fill_val)) paste0(", fill: ", fill_val) else ""
  # Rules follow the chanwe-report table and figure frame: slate, never ink.
  # Structural rules (above the title, under the title block, under the
  # column labels, closing the body) are border-cool 0.5pt; the total rule
  # one slate step darker; row dividers the lighter `rule` slate.
  rule_color <- if (isTRUE(pane)) typst_rgb(hairline) else typst_rgb(tokens[["border-cool"]])
  # The total row opens with an ink rule: the only rule in the table that is
  # not a hairline (2026-11-07).
  total_rule_color <- "_t.ink"
  row_divider_color <- hairline

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
      p('    table.vline(x: ', vx, ', stroke: 0.4pt + rgb("', vline_color, '")),')
    }
  }

  # With the frame's header card the table still opens with its column labels.
  has_hdr <- !is.null(title) || !is.null(eyebrow) || !is.null(subtitle) || !is.null(header)
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
          ', color: rgb("', tokens[["primary"]], '"))[',
          esc(eyebrow),
          ']',
          "#v(-6pt, weak: false)"
        )
      }
      if (!is.null(title)) {
        inner <- paste0(
          inner,
          '#text(font: "', fonts$display, '", size: ',
          title_pt,
          ', fill: _t.ink, weight: "semibold", tracking: -0.05em)[',
          esc(title),
          ']'
        )
      }
      p(
        "      table.cell(align: left, colspan: ",
        n,
        ", inset: ",
        inset_title,
        if (top_border) paste0(", stroke: (top: 0.5pt + ", rule_color, ")") else "",
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
        '#text(font: "', fonts$body, '", size: ',
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

    if (header_rule && is.null(header)) {
      p("      table.hline(stroke: 0.5pt + ", rule_color, "),")
    }

    for (i in seq_len(n)) {
      # v2 tint header: the column labels sit on the tint inside the pane
      hdr_fill <- if (!is.null(highlight_cols) && i %in% highlight_cols) {
        paste0(", fill: ", typst_rgb(highlight_color))
      } else if (isTRUE(pane) || !is.null(frame)) {
        paste0(", fill: ", typst_rgb(tint))
      } else {
        ""
      }
      p(
        "      table.cell(align: ",
        col_aligns[i],
        ", inset: ",
        inset_colhdr,
        hdr_fill,
        ")[",
        pt_v(col_label_top),
        '#text(font: "', fonts$mono, '", size: ',
        label_pt,
        ', fill: _t.fg-muted, weight: "regular", tracking: 0.08em)[',
        esc(toupper(labels[i])),
        ']],'
      )
    }

    p("    ),")
  }

  p("    table.hline(stroke: 0.5pt + ", rule_color, "),")

  nr <- nrow(data)
  total_start <- if (n_total > 0) nr - n_total + 1L else nr + 1L
  for (i in seq_len(nr)) {
    is_total <- i >= total_start
    if (is_total && i == total_start) {
      p("    table.hline(stroke: 0.75pt + ", total_rule_color, "),")
    }
    for (j in seq_len(n)) {
      val <- esc(fmt_data[[j]][i])
      is_first <- j == 1L
      fill <- if (!is.null(color_data[[j]])) color_data[[j]][i] else "_t.ink"
      # Figures (right-aligned columns) stay in mono so digits line up;
      # text cells read in Satoshi, at the document body weight (300).
      is_figure <- identical(col_aligns[j], "right")
      cell_font <- if (is_figure) fonts$mono else fonts$body
      weight <- if (is_first || (is_total && is_figure)) {
        '"medium"'
      } else if (is_figure) {
        '"thin"'
      } else {
        '"light"'
      }
      # A signed column (chanwe_col_signed) renders its values as pills: the
      # sign's colour as text on the same colour at 10%, as the KPI pane does.
      is_signed <- !is.null(color_data[[j]]) && isTRUE(attr(color_data[[j]], "chanwe_pill")) &&
        !is.na(data[[j]][i]) && nzchar(fmt_data[[j]][i])
      is_pill <- is_signed && delta_style == "pill"
      on_band <- is_total && total_style == "band"
      if (on_band && !is_signed) fill <- "_t.rule-cool"
      cell_fill <- if (on_band) {
        ", fill: _t.ink"
      } else if (is_total && total_fill) {
        paste0(', fill: rgb("', total_fill_color, '")')
      } else if (!is.null(highlight_cols) && j %in% highlight_cols) {
        paste0(', fill: rgb("', highlight_color, '")')
      } else {
        ""
      }
      inner <- paste0(
        '#text(font: "', cell_font, '", size: ', body_pt, ', fill: ', fill,
        ', weight: ', if (is_pill) '"medium"' else weight, ')[', val, ']'
      )
      if (is_pill) {
        inner <- paste0(
          '#box(fill: ', fill, '.transparentize(', if (on_band) "70%" else "90%", '), radius: 99pt, inset: (x: 4pt, y: 2.2pt), baseline: 2.2pt)[',
          if (on_band) sub(paste0("fill: ", fill), "fill: _t.rule-cool", inner, fixed = TRUE) else inner, ']'
        )
      } else if (is_signed && delta_style == "arrow") {
        v <- suppressWarnings(as.numeric(data[[j]][i]))
        arrow <- if (isTRUE(v > 0)) "\u{2191} " else if (isTRUE(v < 0)) "\u{2193} " else ""
        inner <- sub("[", paste0("[", arrow), inner, fixed = TRUE)
      } else if (is_signed && delta_style == "bar") {
        # A bar from the centre, as long as the value against the column's
        # largest, then the figure.
        v <- suppressWarnings(as.numeric(data[[j]][i]))
        vmax <- max(abs(suppressWarnings(as.numeric(data[[j]]))), na.rm = TRUE)
        frac <- if (is.finite(vmax) && vmax > 0) min(abs(v) / vmax, 1) else 0
        half <- 5
        bar <- paste0(
          '#box(width: ', 2 * half, 'mm, height: 2.4mm, baseline: 0.5mm)[',
          '#place(left + horizon, dx: ', half, 'mm - 0.25pt, line(angle: 90deg, length: 3.2mm, stroke: 0.5pt + _t.rule-cool))',
          '#place(left + horizon, dx: ', if (v >= 0) paste0(half, "mm") else paste0(half - frac * half, "mm"),
          ', rect(width: ', round(frac * half, 3), 'mm, height: 1.8mm, fill: ', fill, ', radius: 0.7pt))]#h(1.2mm)'
        )
        inner <- paste0(bar, inner)
      }
      p("    table.cell(align: ", col_aligns[j], cell_fill, ")[", inner, "],")
    }
    if (i < nr && !is_total) {
      p('    table.hline(stroke: 0.4pt + rgb("', row_divider_color, '")),')
    }
  }

  # One closing rule, then the footer: the source line as a quiet mono label
  # (or the 2.x stamp with caption_style = "stamp").
  if (!isTRUE(pane) || !is.null(caption)) {
    p("    table.hline(stroke: 0.5pt + ", rule_color, "),")
  }

  if (!is.null(caption)) {
    p("    table.footer(")
    p(
      "      table.cell(colspan: ",
      n,
      ", align: left, inset: ",
      inset_footer,
      ")[",
      pt_v(footer_top),
      if (caption_style == "stamp") {
        paste0(
          '#box(fill: ', typst_rgb(tokens[["primary"]]), ', inset: (x: 4mm, y: 1.6mm))[',
          '#text(font: "', fonts$mono, '", size: ', note_pt,
          ', weight: "medium", tracking: 0.16em, fill: ', typst_rgb(tokens[["pure-white"]]), ')[',
          '#upper[', esc(caption), ']]]'
        )
      } else {
        # v2: the caption is a mono label in plot.axis-text, no box
        paste0(
          '#text(font: "', fonts$mono, '", size: ', note_pt,
          ', weight: "regular", tracking: 0.08em, fill: ',
          typst_rgb(chanwe_tokens$plot$`axis-text`), ')[',
          '#upper[', esc(caption), ']]'
        )
      },
      '],'
    )
    p("    )")
  }

  p("  )")
  p("  ]")
  p("}")

  if (!is.null(header) || !is.null(footer)) {
    # The report's paragraph spacing (2.6em) must not leak between the card's
    # header, the table and the footer.
    L <- c("#block(width: 100%, breakable: false)[#set block(spacing: 0pt)", "#set par(spacing: 0pt, leading: 0.55em)", L, "]")
  }
  if (!is.null(header) && !is.null(card_title)) {
    L <- append(L, c(.kbl_header_card(header, header_fill, card_title, card_subtitle, card_eyebrow, tag, numeral, fonts, esc), "#v(2mm)"), after = 2)
  }
  if (!is.null(footer) && (!is.null(source) || !is.null(id))) {
    L <- append(L, .kbl_footer(footer, source, source_label, id, frame %||_% "simple", fonts, esc), after = length(L) - 1)
  }

  pad_fill <- if (!is.null(fill_val) && !isTRUE(pane)) paste0(", fill: ", fill_val) else ""

  # v2 pane (brand-v2 Q1 B): the table sits in a block with the 16px
  # surface radius (on the document's px scale: body_size / type.body pt per
  # px), a hairline and no shadow; clip keeps the tint header in the corners.
  if (isTRUE(pane)) {
    body_num <- suppressWarnings(as.numeric(sub("pt$", "", body_pt)))
    pt_per_px <- if (is.na(body_num)) 0.75 else body_num / chanwe_tokens$type$body
    radius_pt <- round(chanwe_tokens$radii$surface * pt_per_px, 2)
    L <- c(
      paste0(
        "#block(width: 100%, radius: ", radius_pt, "pt, clip: true, stroke: 0.5pt + ",
        typst_rgb(hairline), if (!is.null(fill_val)) paste0(", fill: ", fill_val) else "",
        ")["
      ),
      L,
      "]"
    )
  }

  if (padding > 0) {
    L <- c(
      paste0("#block(inset: (x: ", padding, "pt, y: 0pt)", pad_fill, ")["),
      L,
      "]"
    )
  }

  if (identical(frame, "shadow")) {
    # A soft, low shadow: stacked rounded rects behind the table, measured to
    # its size; no hairline.
    body_num <- suppressWarnings(as.numeric(sub("pt$", "", body_pt)))
    pt_per_px <- if (is.na(body_num)) 0.75 else body_num / chanwe_tokens$type$body
    radius_pt <- round(chanwe_tokens$radii$surface * pt_per_px, 2)
    L <- c(
      "#let _cw-card = block(width: 100%, radius: ", radius_pt, "pt, clip: true, fill: _t.pane)[",
      L, "]",
      "#layout(size => { let m = measure(_cw-card, width: size.width); block(width: 100%, height: m.height + 3pt, breakable: false, {",
      paste0("  for i in range(6) { place(top + left, dx: 0.2pt * (6 - i), dy: 0.6pt * (6 - i), rect(width: m.width - 0.4pt * (6 - i), height: m.height, radius: ",
             radius_pt, "pt + 1pt * (6 - i), fill: _t.ink.transparentize(100% - 1.1% * (i + 1)), stroke: none)) }"),
      "  place(top + left, _cw-card) }) })"
    )
    L[1] <- paste0(L[1], L[2], L[3]); L <- L[-(2:3)]
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

#' Signed Color Function for Chanwe Tables
#'
#' Returns a ready-made function for the \code{col_colors} argument of
#' \code{\link{chanwe_kbl}()}: positive values in the canonical Chanwe
#' positive green, negative values in the alert vermillion, values at the
#' threshold (and \code{NA}) in neutral ink. The same three tokens drive the
#' KPI scoreboard arrows and the poles of \code{\link{scale_color_chanwe_div}()},
#' so "went up / went down" reads identically across tables, charts, and
#' reports. All three pass WCAG 4.5:1 small-text contrast on every brand
#' surface (see \code{chanwe_palette("signed")}).
#'
#' @param threshold Baseline that separates positive from negative.
#'   Default \code{0}.
#' @param positive,negative,neutral Optional hex overrides for the three
#'   states. Defaults are the canonical signed tokens.
#' @param flip Set \code{TRUE} when smaller is better (e.g. costs, churn):
#'   values below the threshold get the positive color. May also be a
#'   logical \emph{vector}, recycled along the column, for tables that mix
#'   larger-is-better and smaller-is-better rows in one column — e.g.
#'   \code{flip = df$metric \%in\% c("Opex", "Churn")}. Default \code{FALSE}.
#'
#' @return A function taking a numeric vector and returning raw Typst color
#'   expressions, suitable for one entry of \code{col_colors}. Because
#'   \code{col_colors} functions receive the column's original (pre-\code{fmt})
#'   values, this works even when \code{fmt} renders the column as text.
#' @seealso [chanwe_kbl()], [scale_color_chanwe_div()], [chanwe_palette()]
#' @export
#'
#' @examples
#' fn <- chanwe_col_signed()
#' fn(c(2.5, -1.25, 0, NA))
#'
#' ## Smaller-is-better metric:
#' chanwe_col_signed(flip = TRUE)(c(-3, 4))
#'
#' ## Mixed-valence column — flip only the smaller-is-better rows:
#' df <- data.frame(metric = c("Revenue", "Churn"), qoq = c(2.1, -0.8))
#' chanwe_col_signed(flip = df$metric == "Churn")(df$qoq)
chanwe_col_signed <- function(
  threshold = 0,
  positive = NULL,
  negative = NULL,
  neutral = NULL,
  flip = FALSE
) {
  signed <- chanwe_get_signed()
  pos <- if (!is.null(positive)) positive else signed[["positive"]]
  neg <- if (!is.null(negative)) negative else signed[["negative"]]
  neu <- if (!is.null(neutral)) neutral else signed[["neutral"]]
  typst_rgb <- function(hex) paste0('rgb("', hex, '")')

  function(x) {
    x <- suppressWarnings(as.numeric(x))
    n <- length(x)
    fl <- rep_len(as.logical(flip), n)
    fl[is.na(fl)] <- FALSE
    above_col <- ifelse(fl, typst_rgb(neg), typst_rgb(pos))
    below_col <- ifelse(fl, typst_rgb(pos), typst_rgb(neg))
    out <- rep(typst_rgb(neu), n)
    above <- !is.na(x) & x > threshold
    below <- !is.na(x) & x < threshold
    out[above] <- above_col[above]
    out[below] <- below_col[below]
    # chanwe_kbl() draws a signed column as pills.
    attr(out, "chanwe_pill") <- TRUE
    out
  }
}


# ── the figure frame for tables (chanwer 3.2.0) ─────────────────────────────
# The header card and the footer of chanwe_figure(), in Typst, with the
# report's tokens (_t) and helpers (cw-dot).
.kbl_mono <- function(x, size, fill, esc) {
  paste0('#text(font: _t.font-mono, size: ', size, ', tracking: 0.12em, fill: ', fill, ')[#upper[', esc(x), ']]')
}
.kbl_header_card <- function(kind, fill, title, subtitle, eyebrow, tag, numeral, fonts, esc) {
  dark <- kind == "dark"; bare <- fill == "none" && !dark
  tcol <- if (dark) "_t.rule-cool" else "_t.fg"; scol <- if (dark) "_t.fg-subtle" else "_t.fg-muted"
  tb <- paste0(
    '#block(spacing: 0pt)[#text(font: _t.font-display, size: 11pt, weight: _t.weight-display, tracking: -0.04em, fill: ', tcol, ')[', esc(title), ']]',
    if (!is.null(subtitle)) paste0('#block(above: 1.6mm, spacing: 0pt)[#text(font: _t.font-sans, size: 7pt, fill: ', scol, ')[', esc(subtitle), ']]') else ""
  )
  eye <- function(col) if (is.null(eyebrow)) "" else paste0('#box(baseline: -0.2pt, cw-dot(_t.primary, size: 3pt))#h(1.4mm)', .kbl_mono(eyebrow, "5pt", col, esc))
  tg <- function(col) if (is.null(tag)) "" else .kbl_mono(tag, "4.8pt", col, esc)
  inner <- switch(kind,
    A = paste0('#block(width: 100%, fill: _t.ink, radius: 99pt, inset: (x: 2.6mm, y: 1.2mm), grid(columns: (1fr, auto), align: (left + horizon, right + horizon), [', eye("_t.rule-cool"), '], [', tg("_t.fg-subtle"), ']))#v(2.4mm, weak: false)', tb),
    C = paste0('#grid(columns: (auto, 1fr, auto), column-gutter: 3mm, align: (left + horizon, left + top, right + top), ',
               if (!is.null(numeral)) paste0('text(font: _t.font-serif-display, style: "italic", size: 28pt, fill: _t.primary, top-edge: "cap-height", bottom-edge: "baseline")[', esc(numeral), ']') else "[]",
               ', [', eye("_t.fg"), '#v(1.8mm, weak: false)', tb, '], [', tg("_t.fg-muted"), '])'),
    D = paste0('#grid(columns: (1fr, auto), column-gutter: 4mm, align: (left + horizon, left + top), [', tb,
               '], block(stroke: (left: 0.5pt + _t.rule-cool), inset: (left: 3.5mm, y: 0.4mm))[', '#block(spacing: 0pt)[', eye("_t.fg"), ']#block(above: 1.8mm, spacing: 0pt)[', tg("_t.fg-muted"), ']', '])'),
    dark = paste0('#grid(columns: (1fr, auto), align: (left + horizon, right + horizon), [', eye("_t.primary"), '], [', tg("_t.fg-subtle"), '])#v(2.4mm, weak: false)', tb)
  )
  box_fill <- if (dark) "_t.ink" else if (bare) "none" else "_t.tint"
  inset <- if (bare) "(x: 0mm, y: 0.6mm)" else "(x: 3.4mm, y: 3mm)"
  c(paste0('#pad(x: 2.4mm, top: 2.4mm, block(width: 100%, fill: ', box_fill, ', radius: 2.6mm, inset: ', inset, ')[#set par(spacing: 0pt, leading: 0.5em);', inner, '])'))
}
.kbl_footer <- function(kind, source, source_label, id, frame, fonts, esc) {
  src <- if (is.null(source)) "[]" else paste0('[', .kbl_mono(source_label, "4.6pt", "_t.fg-subtle", esc), '#h(2mm)', .kbl_mono(source, "4.6pt", "_t.fg-muted", esc), ']')
  if (kind == "rule") {
    idc <- if (is.null(id)) "[]" else paste0('box(fill: _t.white, radius: 99pt, inset: (x: 1.8mm, y: 0.7mm))[', .kbl_mono(id, "4.3pt", "_t.fg-muted", esc), ']')
    paste0('#block(width: 100%, stroke: (top: 0.5pt + _t.rule), inset: (x: 3.4mm, y: 1.4mm), grid(columns: (1fr, auto), align: (left + horizon, right + horizon), ', src, ', ', idc, '))')
  } else {
    idc <- if (is.null(id)) "[]" else paste0('[', .kbl_mono(id, "4.3pt", "_t.fg-muted", esc), ']')
    paste0('#', if (frame == "none") 'pad(top: 1.4mm, ' else '', 'block(width: 100%, fill: _t.tint, radius: ', if (frame == "none") "2mm" else "0pt",
           ', inset: (x: 3.4mm, y: 1.9mm), grid(columns: (1fr, auto), align: (left + horizon, right + horizon), ', src, ', ', idc, '))', if (frame == "none") ')' else '')
  }
}
