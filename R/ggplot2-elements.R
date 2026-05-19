#' @importFrom ggplot2 element_grob
#' @importFrom grid makeContent heightDetails widthDetails unit.c
#' @importFrom gtable gtable gtable_add_grob

# Internal separator for structured label encoding — unlikely in normal text
.CW_SEP <- "\x1F"
# Secondary separator for KPI field encoding (unit separator)
.CW_KPI_SEP <- "\x1E"

.cw_parse_kpi <- function(kpi_str) {
  if (is.null(kpi_str) || !nzchar(kpi_str)) {
    return(NULL)
  }
  parts <- strsplit(kpi_str, .CW_KPI_SEP, fixed = TRUE)[[1L]]
  if (length(parts) < 3L) {
    return(NULL)
  }
  metrics <- list()
  idx <- 4L
  while (idx + 2L <= length(parts)) {
    dir <- suppressWarnings(as.integer(parts[idx + 2L]))
    metrics <- c(
      metrics,
      list(list(
        label = parts[idx],
        value = parts[idx + 1L],
        dir = if (is.na(dir)) 0L else dir
      ))
    )
    idx <- idx + 3L
  }
  list(value = parts[1L], unit = parts[2L], date = parts[3L], metrics = metrics)
}

# ─── helpers ─────────────────────────────────────────────────────────────────

# Measure string height in pt by creating a textGrob with the given gpar
.cw_str_h <- function(text, gp) {
  grid::convertHeight(
    grid::unit(1, "grobheight", grid::textGrob(text, gp = gp)),
    "pt",
    valueOnly = TRUE
  )
}

# ─── element constructors ────────────────────────────────────────────────────

new_element_chanwe_title <- function(
  family = "Archivo",
  face = "bold",
  size = 18,
  colour = "#1A1A1A",
  hjust = 0,
  vjust = 1,
  eyebrow_family = "JetBrains Mono",
  eyebrow_size = 6,
  eyebrow_colour = "#FB3D0E",
  ink_colour = "#1A1A1A",
  draw_bottom_line = FALSE,
  top_pad = 8,
  inherit.blank = FALSE
) {
  structure(
    list(
      family = family,
      face = face,
      colour = colour,
      size = size,
      hjust = hjust,
      vjust = vjust,
      angle = 0,
      lineheight = 1.1,
      margin = ggplot2::margin(0, 0, 2, 0),
      debug = FALSE,
      inherit.blank = inherit.blank,
      eyebrow_family = eyebrow_family,
      eyebrow_size = eyebrow_size,
      eyebrow_colour = eyebrow_colour,
      ink_colour = ink_colour,
      draw_bottom_line = draw_bottom_line,
      top_pad = top_pad
    ),
    class = c("element_chanwe_title", "element_text", "element")
  )
}

new_element_chanwe_subtitle <- function(
  family = "Satoshi",
  size = 9,
  colour = "#555555",
  hjust = 0,
  vjust = 1,
  ink_colour = "#1A1A1A",
  mono_family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  kpi_label_colour = "#AEABA6",
  gap_ln = 6,
  sub_bot = 20,
  draw_middle = TRUE,
  inherit.blank = FALSE
) {
  structure(
    list(
      family = family,
      face = "plain",
      colour = colour,
      size = size,
      hjust = hjust,
      vjust = vjust,
      angle = 0,
      lineheight = 1.3,
      margin = ggplot2::margin(3, 0, 20, 0),
      debug = FALSE,
      inherit.blank = inherit.blank,
      ink_colour = ink_colour,
      mono_family = mono_family,
      mono_thin_family = mono_thin_family,
      kpi_label_colour = kpi_label_colour,
      gap_ln = gap_ln,
      sub_bot = sub_bot,
      draw_middle = draw_middle
    ),
    class = c("element_chanwe_subtitle", "element_text", "element")
  )
}

new_element_chanwe_caption <- function(
  family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  size = 7,
  colour = "#555555",
  hjust = 0,
  vjust = 1,
  primary_colour = "#FB3D0E",
  ink_colour = "#1A1A1A",
  inherit.blank = FALSE
) {
  structure(
    list(
      family = family,
      mono_thin_family = mono_thin_family,
      face = "plain",
      colour = colour,
      size = size,
      hjust = hjust,
      vjust = vjust,
      angle = 0,
      lineheight = 1.2,
      margin = ggplot2::margin(5, 0, 0, 0),
      debug = FALSE,
      inherit.blank = inherit.blank,
      primary_colour = primary_colour,
      ink_colour = ink_colour
    ),
    class = c("element_chanwe_caption", "element_text", "element")
  )
}

# ─── gTree builders (called from element_grob methods) ───────────────────────
#
# Coordinate system: y=0 is BOTTOM of the grob, y=total is TOP.
# ggplot2 places each label row so its top edge aligns visually at the top,
# so high y-values → top of the visible header area.
#
# Heights are computed once in .cw_*_heights() and reused by both
# heightDetails() (so ggplot2 allocates the correct row height) and
# makeContent() (so children are positioned correctly). Always keep them
# in sync — never hard-code a position in makeContent that wasn't derived
# from the heights list.
#
# ── Title grob layout (bottom → top) ─────────────────────────────────────────
#
#   bot          bottom padding; carries the gap to the chart (or subtitle).
#                = margin[3] from element — 2pt normally, 20pt when no subtitle.
#   [bottom line] optional 0.4pt separator (draw_bottom_line=TRUE, no-subtitle mode).
#                 positioned at bot−5pt from bottom so 15pt of bot sits below it.
#   t_h          title text (Archivo)
#   gap1         space between title and eyebrow (6pt, only when has_ey)
#   ey_h         eyebrow text (JetBrains Mono, only when has_ey)
#   top          top padding above eyebrow: top_pad (4pt compact / 8pt spacious)
#                or 0 when there is no eyebrow
#   gap2         gap between eyebrow/title and the top border line (draw_top)
#   [top line]   optional 0.1pt border (draw_top, from plot_borders option)
#
# ── Subtitle grob layout (bottom → top) ──────────────────────────────────────
#
# Three modes controlled by the presence of sub_text and kpi_data:
#
#   MODE A — text + optional note (no KPI):
#     sub_bot      gap below separator line to chart  (12pt compact / 20pt spacious)
#     [mid line]   0.4pt separator (always drawn, draw_middle=TRUE)
#     gap_n        gap between note and separator (3pt, only when has_n)
#     n_h          note text (italic Satoshi, only when has_n)
#     gap_ln       gap between subtitle text and separator (6pt compact / 14pt spacious)
#     s_h          subtitle text (Satoshi)
#     top (5pt)
#
#   MODE B — text + KPI scoreboard:
#     [KPI section occupies bot instead of sub_bot]:
#       kpi_bot_sep (16pt) + kpi_bot_ln_h (0.3pt) + kpi_bot_pad (2pt) +
#       kpi_panel_h (35pt) + kpi_top_pad (4pt)
#     [mid line]
#     gap_ln / s_h / top — same as MODE A
#
#   MODE C — KPI-only (sub_text is empty):
#     Same KPI bot section as MODE B, but s_h=0, gap_ln=0, ln_h=0, top=2pt.
#     The subtitle text row and its separator line are entirely skipped so the
#     KPI panel starts just 2pt below the top of the allocated row.

.cw_title_tree <- function(
  title_text,
  eyebrow_text,
  draw_top,
  title_gp,
  eyebrow_gp,
  ink_col,
  margin_bottom = 2,
  draw_bottom_line = FALSE,
  top_pad = 8
) {
  grid::gTree(
    title_text = title_text,
    eyebrow_text = eyebrow_text,
    draw_top = draw_top,
    title_gp = title_gp,
    eyebrow_gp = eyebrow_gp,
    ink_col = ink_col,
    margin_bottom = margin_bottom,
    draw_bottom_line = draw_bottom_line,
    top_pad = top_pad,
    cl = "cw_title_tree"
  )
}

.cw_title_heights <- function(x) {
  t_h <- .cw_str_h(x$title_text, x$title_gp)
  has_ey <- !is.null(x$eyebrow_text) && nzchar(x$eyebrow_text)
  ey_h <- if (has_ey) .cw_str_h(x$eyebrow_text, x$eyebrow_gp) else 0
  top <- if (has_ey) (x$top_pad %||_% 8) else 0 # top padding above eyebrow
  bot <- (x$margin_bottom %||_% 2) # bottom padding — carries extra space when no subtitle
  gap1 <- if (has_ey) 6 else 0 # gap: title → eyebrow
  gap2 <- if (x$draw_top && has_ey) {
    5
  } else if (x$draw_top) {
    3
  } else {
    0
  } # gap: eyebrow/title → line
  ln_h <- if (x$draw_top) 0.3 else 0
  bln_h <- if (isTRUE(x$draw_bottom_line)) 0.4 else 0
  total <- top + bot + t_h + gap1 + ey_h + gap2 + ln_h
  list(
    t_h = t_h,
    ey_h = ey_h,
    has_ey = has_ey,
    top = top,
    bot = bot,
    gap1 = gap1,
    gap2 = gap2,
    ln_h = ln_h,
    bln_h = bln_h,
    total = total
  )
}

#' @method makeContent cw_title_tree
#' @export
makeContent.cw_title_tree <- function(x) {
  d <- .cw_title_heights(x)
  # positions: y measured from BOTTOM of grob (y=0=bottom, y=total=top=visual top)
  title_y <- d$bot + d$t_h / 2
  ey_y <- d$bot + d$t_h + d$gap1 + d$ey_h / 2
  line_y <- d$total - d$top - d$ln_h / 2
  bln_y <- (d$bot - 10) + d$bln_h / 2 # 10pt above line to title text; rest is below line → chart gap

  ch <- grid::gList(
    grid::textGrob(
      x$title_text,
      x = grid::unit(0, "npc"),
      y = grid::unit(title_y, "pt"),
      just = c("left", "center"),
      gp = x$title_gp
    )
  )
  if (d$has_ey) {
    ch <- grid::gList(
      ch,
      grid::textGrob(
        paste0("──── ", toupper(x$eyebrow_text)),
        x = grid::unit(0, "npc"),
        y = grid::unit(ey_y, "pt"),
        just = c("left", "center"),
        gp = x$eyebrow_gp
      )
    )
  }
  if (x$draw_top) {
    ch <- grid::gList(
      ch,
      grid::linesGrob(
        x = grid::unit(c(0, 1), "npc"),
        y = grid::unit(c(line_y, line_y), "pt"),
        gp = grid::gpar(col = x$ink_col, lwd = 0.1, lend = "square")
      )
    )
  }
  if (isTRUE(x$draw_bottom_line)) {
    ch <- grid::gList(
      ch,
      grid::linesGrob(
        x = grid::unit(c(0, 1), "npc"),
        y = grid::unit(c(bln_y, bln_y), "pt"),
        gp = grid::gpar(col = x$ink_col, lwd = 0.4, lend = "square")
      )
    )
  }
  grid::setChildren(x, ch)
}

#' @method heightDetails cw_title_tree
#' @export
heightDetails.cw_title_tree <- function(x) {
  grid::unit(.cw_title_heights(x)$total, "pt")
}

# ─────────────────────────────────────────────────────────────────────────────

.cw_subtitle_tree <- function(
  sub_text,
  note_text,
  draw_middle,
  sub_gp,
  note_gp,
  sep_gp,
  ink_col,
  kpi_data = NULL,
  mono_family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  kpi_label_colour = "#AEABA6",
  gap_ln = 6,
  sub_bot = 20
) {
  grid::gTree(
    sub_text = sub_text,
    note_text = note_text,
    draw_middle = draw_middle,
    sub_gp = sub_gp,
    note_gp = note_gp,
    sep_gp = sep_gp,
    ink_col = ink_col,
    kpi_data = kpi_data,
    mono_family = mono_family,
    mono_thin_family = mono_thin_family,
    kpi_label_colour = kpi_label_colour,
    gap_ln = gap_ln,
    sub_bot = sub_bot,
    cl = "cw_subtitle_tree"
  )
}

.cw_subtitle_heights <- function(x) {
  has_kpi <- !is.null(x$kpi_data)
  has_sub <- nzchar(trimws(x$sub_text))
  # when KPI-only (no subtitle text), skip the text row — the separator line is kept
  s_h <- if (has_sub) .cw_str_h(x$sub_text, x$sub_gp) else 0
  # note is suppressed when KPI panel is present — the two don't stack
  has_n <- !is.null(x$note_text) && nzchar(x$note_text) && !has_kpi
  n_h <- if (has_n) .cw_str_h(x$note_text, x$note_gp) else 0
  top <- if (!has_sub && has_kpi) 8 else 5
  gap_ln <- if (x$draw_middle && has_sub) (x$gap_ln %||_% 6) else 0
  ln_h <- if (x$draw_middle && (has_sub || has_kpi)) 0.3 else 0
  gap_n <- if (has_n) 3 else 0
  # KPI panel section (sits in what would otherwise be the bottom padding)
  kpi_panel_h <- if (has_kpi) 35 else 0
  kpi_top_pad <- if (has_kpi) 4 else 0
  kpi_bot_pad <- if (has_kpi) 2 else 0
  kpi_bot_ln_h <- if (has_kpi) 0.3 else 0
  kpi_bot_sep <- if (has_kpi) 16 else 0
  bot <- if (has_kpi) {
    kpi_top_pad + kpi_panel_h + kpi_bot_pad + kpi_bot_ln_h + kpi_bot_sep
  } else {
    x$sub_bot %||_% 20
  }
  total <- top + s_h + gap_ln + ln_h + gap_n + n_h + bot
  list(
    s_h = s_h,
    n_h = n_h,
    has_n = has_n,
    has_kpi = has_kpi,
    top = top,
    bot = bot,
    gap_ln = gap_ln,
    ln_h = ln_h,
    gap_n = gap_n,
    kpi_panel_h = kpi_panel_h,
    kpi_top_pad = kpi_top_pad,
    kpi_bot_pad = kpi_bot_pad,
    kpi_bot_ln_h = kpi_bot_ln_h,
    kpi_bot_sep = kpi_bot_sep,
    has_sub = has_sub,
    total = total
  )
}

#' @method makeContent cw_subtitle_tree
#' @export
makeContent.cw_subtitle_tree <- function(x) {
  d <- .cw_subtitle_heights(x)
  # Build from bottom up:
  # [KPI section | bot] | note | gap_n | line | gap_ln | subtitle | top_pad
  note_y <- d$bot + d$n_h / 2
  line_y <- d$bot + d$n_h + d$gap_n + d$ln_h / 2
  sub_y <- d$bot + d$n_h + d$gap_n + d$ln_h + d$gap_ln + d$s_h / 2

  ch <- if (d$has_sub) {
    grid::gList(
      grid::textGrob(
        x$sub_text,
        x = grid::unit(0, "npc"),
        y = grid::unit(sub_y, "pt"),
        just = c("left", "center"),
        gp = x$sub_gp
      )
    )
  } else {
    grid::gList()
  }
  if (x$draw_middle) {
    ch <- grid::gList(
      ch,
      grid::linesGrob(
        x = grid::unit(c(0, 1), "npc"),
        y = grid::unit(c(line_y, line_y), "pt"),
        gp = grid::gpar(col = x$ink_col, lwd = 0.4, lend = "square")
      )
    )
  }
  if (d$has_n) {
    ch <- grid::gList(
      ch,
      grid::textGrob(
        x$note_text,
        x = grid::unit(0, "npc"),
        y = grid::unit(note_y, "pt"),
        just = c("left", "center"),
        gp = x$note_gp
      )
    )
  }

  if (d$has_kpi) {
    kpi <- x$kpi_data
    mono_fam <- x$mono_family %||_% "JetBrains Mono"
    ink <- x$ink_col
    fg_muted <- "#656460"
    subtle <- x$kpi_label_colour %||_% "#AEABA6"
    green <- "#2D7A4F"
    red <- "#B03A2E"

    # y-coordinates from bottom of the whole grob
    kpi_bot_ln_y <- d$kpi_bot_sep + d$kpi_bot_ln_h / 2
    kpi_center_y <- d$kpi_bot_sep +
      d$kpi_bot_ln_h +
      d$kpi_bot_pad +
      d$kpi_panel_h / 2

    # Bottom separator line (between KPI panel and chart)
    ch <- grid::gList(
      ch,
      grid::linesGrob(
        x = grid::unit(c(0, 1), "npc"),
        y = grid::unit(c(kpi_bot_ln_y, kpi_bot_ln_y), "pt"),
        gp = grid::gpar(col = x$ink_col, lwd = 0.4, lend = "square")
      )
    )

    # Hero value — Fraunces SemiBold Italic (weight 600), same weight as h1 heading
    val_gp <- grid::gpar(
      fontfamily = "Fraunces 9pt Regular",
      fontface = "italic",
      fontsize = 24,
      col = ink
    )
    val_g <- grid::textGrob(
      kpi$value,
      x = grid::unit(0, "npc"),
      y = grid::unit(kpi_center_y, "pt"),
      just = c("left", "center"),
      gp = val_gp
    )
    ch <- grid::gList(ch, val_g)

    # Unit + AS OF + date block, positioned right of the hero value
    side_x <- grid::unit(1, "grobwidth", val_g) + grid::unit(6, "pt")
    unit_gp <- grid::gpar(
      fontfamily = mono_fam,
      fontsize = 4.5,
      col = fg_muted
    )
    as_of_gp <- grid::gpar(
      fontfamily = mono_fam,
      fontsize = 4.5,
      col = fg_muted
    )
    date_gp <- grid::gpar(fontfamily = mono_fam, fontsize = 6.0, col = fg_muted)

    if (nzchar(kpi$unit)) {
      ch <- grid::gList(
        ch,
        grid::textGrob(
          kpi$unit,
          x = side_x,
          y = grid::unit(kpi_center_y + 7, "pt"),
          just = c("left", "center"),
          gp = unit_gp
        )
      )
    }
    if (nzchar(kpi$date)) {
      ch <- grid::gList(
        ch,
        grid::textGrob(
          kpi$date,
          x = side_x,
          y = grid::unit(kpi_center_y - 2, "pt"),
          just = c("left", "center"),
          gp = date_gp
        )
      )
    }

    # Metric columns — anchored to the right edge of the plot
    mono_thin <- x$mono_thin_family %||_% mono_fam
    n_metrics <- length(kpi$metrics)
    if (n_metrics > 0L) {
      col_right <- 0.99 # right anchor (right-edge of rightmost column)
      col_step <- 0.13 # spacing between column right-edges
      lbl_gp <- grid::gpar(
        fontfamily = mono_fam,
        fontsize = 4.,
        col = fg_muted
      )
      for (i in seq_along(kpi$metrics)) {
        m <- kpi$metrics[[i]]
        col_x <- col_right - (n_metrics - i) * col_step
        m_col <- if (m$dir > 0L) {
          green
        } else if (m$dir < 0L) {
          red
        } else {
          fg_muted
        }
        arrow <- if (m$dir > 0L) {
          "▲ "
        } else if (m$dir < 0L) {
          "▼ "
        } else {
          ""
        }
        val_m_gp <- grid::gpar(
          fontfamily = mono_fam,
          fontsize = 6.5,
          col = m_col
        )
        ch <- grid::gList(
          ch,
          grid::textGrob(
            toupper(m$label),
            x = grid::unit(col_x, "npc"),
            y = grid::unit(kpi_center_y - 4, "pt"),
            just = c("right", "center"),
            gp = lbl_gp
          ),
          grid::textGrob(
            paste0(arrow, m$value),
            x = grid::unit(col_x, "npc"),
            y = grid::unit(kpi_center_y - 10, "pt"),
            just = c("right", "center"),
            gp = val_m_gp
          )
        )
      }
    }
  }

  grid::setChildren(x, ch)
}

#' @method heightDetails cw_subtitle_tree
#' @export
heightDetails.cw_subtitle_tree <- function(x) {
  grid::unit(.cw_subtitle_heights(x)$total, "pt")
}

# ─────────────────────────────────────────────────────────────────────────────

.cw_caption_tree <- function(
  cap_text,
  draw_bottom,
  cap_gp,
  pfx_gp,
  sep_gp,
  ink_col
) {
  grid::gTree(
    cap_text = cap_text,
    draw_bottom = draw_bottom,
    cap_gp = cap_gp,
    pfx_gp = pfx_gp,
    sep_gp = sep_gp,
    ink_col = ink_col,
    cl = "cw_caption_tree"
  )
}

.cw_caption_heights <- function(x) {
  c_h <- .cw_str_h(x$cap_text, x$cap_gp)
  top <- 5 # top padding (matches margin t=5)
  bot <- 4 # bottom padding
  tln_h <- 0
  gap1 <- 0
  gap2 <- if (x$draw_bottom) 4 else 0
  bln_h <- if (x$draw_bottom) 0.3 else 0
  total <- bot + bln_h + gap2 + c_h + gap1 + tln_h + top
  list(
    c_h = c_h,
    top = top,
    bot = bot,
    tln_h = tln_h,
    gap1 = gap1,
    gap2 = gap2,
    bln_h = bln_h,
    total = total
  )
}

#' @method makeContent cw_caption_tree
#' @export
makeContent.cw_caption_tree <- function(x) {
  d <- .cw_caption_heights(x)
  # Build from bottom up:
  # bot | bot_line | gap2 | cap_text | gap1 | top_line | top_pad
  bln_y <- d$bot + d$bln_h / 2
  cap_y <- d$bot + d$bln_h + d$gap2 + d$c_h / 2
  tln_y <- d$bot + d$bln_h + d$gap2 + d$c_h + d$gap1 + d$tln_h / 2

  # "// " prefix + text on the same row
  pfx_str <- "//  "
  pfx_g <- grid::textGrob(
    pfx_str,
    x = grid::unit(0, "npc"),
    y = grid::unit(cap_y, "pt"),
    just = c("left", "center"),
    gp = x$pfx_gp
  )
  cap_g <- grid::textGrob(
    x$cap_text,
    x = grid::unit(1, "grobwidth", pfx_g) + grid::unit(3, "pt"),
    y = grid::unit(cap_y, "pt"),
    just = c("left", "center"),
    gp = x$cap_gp
  )

  ch <- grid::gList(pfx_g, cap_g)
  if (x$draw_bottom) {
    ch <- grid::gList(
      ch,
      grid::textGrob(
        strrep("─", 400),
        x = grid::unit(0, "npc"),
        y = grid::unit(bln_y, "pt"),
        just = c("left", "center"),
        gp = x$sep_gp
      )
    )
  }
  grid::setChildren(x, ch)
}

#' @method heightDetails cw_caption_tree
#' @export
heightDetails.cw_caption_tree <- function(x) {
  grid::unit(.cw_caption_heights(x)$total, "pt")
}

# ─── element_grob dispatch ───────────────────────────────────────────────────

#' @method element_grob element_chanwe_title
#' @export
element_grob.element_chanwe_title <- function(element, label = "", ...) {
  if (is.null(label) || identical(label, "")) {
    return(grid::nullGrob())
  }

  pb <- getOption("chanwer.plot_borders", default = "none")
  draw_top <- pb %in% c("top", "top_bottom", "complete")
  ink <- element$ink_colour %||_% "#1A1A1A"

  parts <- strsplit(as.character(label), .CW_SEP, fixed = TRUE)[[1L]]
  has_eyebrow <- length(parts) == 2L
  eyebrow_text <- if (has_eyebrow) parts[1L] else NULL
  title_text <- if (has_eyebrow) parts[2L] else parts[1L]

  title_gp <- grid::gpar(
    fontfamily = element$family %||_% "Archivo",
    fontsize = element$size %||_% 18,
    fontface = element$face %||_% "bold",
    col = element$colour %||_% ink
  )
  eyebrow_gp <- grid::gpar(
    fontfamily = element$eyebrow_family %||_% "JetBrains Mono",
    fontsize = element$eyebrow_size %||_% 6,
    col = element$eyebrow_colour %||_% "#FB3D0E"
  )

  margin_bottom <- as.numeric(element$margin[3L] %||_% 2)
  .cw_title_tree(title_text, eyebrow_text, draw_top, title_gp, eyebrow_gp, ink,
                 margin_bottom = margin_bottom,
                 draw_bottom_line = isTRUE(element$draw_bottom_line),
                 top_pad = element$top_pad %||_% 8)
}

#' @method element_grob element_chanwe_subtitle
#' @export
element_grob.element_chanwe_subtitle <- function(element, label = "", ...) {
  if (is.null(label) || identical(label, "")) {
    return(grid::nullGrob())
  }

  ink <- element$ink_colour %||_% "#1A1A1A"
  mono_fam <- element$mono_family %||_% "JetBrains Mono"
  mono_thin_fam <- element$mono_thin_family %||_% mono_fam
  kpi_label_colour <- element$kpi_label_colour %||_% "#AEABA6"

  parts <- strsplit(as.character(label), .CW_SEP, fixed = TRUE)[[1L]]
  sub_text <- parts[1L]
  note_text <- if (length(parts) >= 2L && nzchar(parts[2L])) parts[2L] else NULL
  kpi_str <- if (length(parts) >= 3L && nzchar(parts[3L])) parts[3L] else NULL
  kpi_data <- .cw_parse_kpi(kpi_str)

  sub_size <- element$size %||_% 9
  sub_gp <- grid::gpar(
    fontfamily = element$family %||_% "Satoshi",
    fontsize = sub_size,
    col = element$colour %||_% "#555555"
  )
  note_gp <- grid::gpar(
    fontfamily = element$family %||_% "Satoshi",
    fontsize = sub_size * 0.85,
    fontface = "italic",
    col = element$colour %||_% "#555555"
  )
  sep_gp <- grid::gpar(
    fontfamily = mono_fam,
    fontsize = sub_size * 0.65,
    col = ink
  )

  .cw_subtitle_tree(
    sub_text,
    note_text,
    draw_middle = isTRUE(element$draw_middle %||_% TRUE),
    sub_gp,
    note_gp,
    sep_gp,
    ink,
    kpi_data = kpi_data,
    mono_family = mono_fam,
    mono_thin_family = mono_thin_fam,
    kpi_label_colour = kpi_label_colour,
    gap_ln = element$gap_ln %||_% 6,
    sub_bot = element$sub_bot %||_% 20
  )
}

#' @method element_grob element_chanwe_caption
#' @export
element_grob.element_chanwe_caption <- function(element, label = "", ...) {
  if (is.null(label) || identical(label, "")) {
    return(grid::nullGrob())
  }

  pb <- getOption("chanwer.plot_borders", default = "none")
  draw_bottom <- pb %in% c("bottom", "top_bottom", "complete")
  ink <- element$ink_colour %||_% "#1A1A1A"
  primary <- element$primary_colour %||_% "#FB3D0E"
  cap_size <- element$size %||_% 9

  cap_gp <- grid::gpar(
    fontfamily = element$mono_thin_family %||_% "JetBrains Mono Thin",
    fontsize = cap_size,
    col = element$colour %||_% "#808080"
  )
  pfx_gp <- grid::gpar(
    fontfamily = element$mono_thin_family %||_% "JetBrains Mono Thin",
    fontsize = cap_size * 0.75,
    col = primary
  )
  sep_gp <- grid::gpar(
    fontfamily = element$family %||_% "JetBrains Mono",
    fontsize = cap_size,
    col = ink
  )

  .cw_caption_tree(
    as.character(label),
    draw_bottom,
    cap_gp,
    pfx_gp,
    sep_gp,
    ink
  )
}

# Lightweight NULL-coalesce used only within this file
`%||_%` <- function(a, b) if (!is.null(a)) a else b
