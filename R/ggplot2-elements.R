#' @importFrom ggplot2 element_grob
#' @importFrom grid makeContent heightDetails

# Internal separator for structured label encoding — unlikely in normal text
.CW_SEP <- "\x1F"
# Secondary separator for KPI field encoding (unit separator)
.CW_KPI_SEP <- "\x1E"
# Eyebrow rule prefix: six box-drawing dashes (─) plus a space
.CW_EYEBROW_RULE <- paste0(strrep("\u2500", 6), " ")

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
  # each metric encodes 4 fields: label, value, direction (arrow), valence (color)
  while (idx + 3L <= length(parts)) {
    dir <- suppressWarnings(as.integer(parts[idx + 2L]))
    val <- suppressWarnings(as.integer(parts[idx + 3L]))
    metrics <- c(
      metrics,
      list(list(
        label = parts[idx],
        value = parts[idx + 1L],
        dir = if (is.na(dir)) 0L else dir,
        valence = if (is.na(val)) 0L else val
      ))
    )
    idx <- idx + 4L
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
  family = "Schibsted Grotesk SemiBold",
  face = "bold",
  size = 18,
  colour = "#111319",
  hjust = 0,
  vjust = 1,
  eyebrow_family = "JetBrains Mono",
  eyebrow_size = 6,
  eyebrow_colour = "#FD3810",
  ink_colour = "#111319",
  rule_colour = "#CFD6DF",
  draw_bottom_line = FALSE,
  top_pad = 8,
  eyebrow_style = "band",
  band_text_colour = "#C6CDD6",
  band_stamp_colour = "#8A94A6",
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
      lineheight = 1.0, # tight leading at display size (Typst h1 uses 1.05)
      margin = ggplot2::margin(0, 0, 2, 0),
      debug = FALSE,
      inherit.blank = inherit.blank,
      eyebrow_family = eyebrow_family,
      eyebrow_size = eyebrow_size,
      eyebrow_colour = eyebrow_colour,
      ink_colour = ink_colour,
      rule_colour = rule_colour,
      draw_bottom_line = draw_bottom_line,
      top_pad = top_pad,
      eyebrow_style = eyebrow_style,
      band_text_colour = band_text_colour,
      band_stamp_colour = band_stamp_colour
    ),
    class = c("element_chanwe_title", "element_text", "element")
  )
}

new_element_chanwe_subtitle <- function(
  family = "Satoshi",
  italic_family = "Cormorant Garamond",
  size = 9,
  colour = "#475569",
  hjust = 0,
  vjust = 1,
  ink_colour = "#111319",
  rule_colour = "#CFD6DF",
  mono_family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  display_family = "Schibsted Grotesk SemiBold",
  kpi_label_colour = "#475569",
  gap_ln = 6,
  sub_bot = 20,
  sub_top = 3,
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
      margin = ggplot2::margin(1, 0, 20, 0),
      debug = FALSE,
      inherit.blank = inherit.blank,
      ink_colour = ink_colour,
      rule_colour = rule_colour,
      italic_family = italic_family,
      mono_family = mono_family,
      mono_thin_family = mono_thin_family,
      display_family = display_family,
      kpi_label_colour = kpi_label_colour,
      gap_ln = gap_ln,
      sub_bot = sub_bot,
      sub_top = sub_top,
      draw_middle = draw_middle
    ),
    class = c("element_chanwe_subtitle", "element_text", "element")
  )
}

new_element_chanwe_caption <- function(
  family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  size = 7,
  colour = "#475569",
  hjust = 0,
  vjust = 1,
  primary_colour = "#FD3810",
  ink_colour = "#111319",
  rule_colour = "#CFD6DF",
  stamp = FALSE,
  inherit.blank = FALSE
) {
  structure(
    list(
      stamp = stamp,
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
      ink_colour = ink_colour,
      rule_colour = rule_colour
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
#   t_h          title text (Schibsted Grotesk)
#   gap1         space between title and eyebrow (6pt, only when has_ey)
#   ey_h         eyebrow text (JetBrains Mono, only when has_ey)
#   top          top padding above eyebrow: top_pad (4pt compact / 8pt spacious)
#                or 0 when there is no eyebrow
#   gap2         gap between eyebrow/title and the top border line (draw_top)
#   [top line]   optional 0.4pt border (draw_top, from plot_borders option)
#
# ── Subtitle grob layout (bottom → top) ──────────────────────────────────────
#
# Three modes controlled by the presence of sub_text and kpi_data:
#
#   MODE A — text + optional note (no KPI):
#     sub_bot      gap below separator line to chart  (12pt compact / 20pt spacious)
#     [mid line]   0.4pt separator (always drawn, draw_middle=TRUE)
#     gap_n        gap between note and separator (3pt, only when has_n)
#     n_h          note text (italic Cormorant Garamond, only when has_n)
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
  top_pad = 8,
  rule_col = ink_col,
  band = FALSE,
  stamp_text = NULL,
  band_text_col = "#C6CDD6",
  band_stamp_col = "#8A94A6"
) {
  grid::gTree(
    band = band,
    stamp_text = stamp_text,
    band_text_col = band_text_col,
    band_stamp_col = band_stamp_col,
    title_text = title_text,
    eyebrow_text = eyebrow_text,
    draw_top = draw_top,
    title_gp = title_gp,
    eyebrow_gp = eyebrow_gp,
    ink_col = ink_col,
    rule_col = rule_col,
    margin_bottom = margin_bottom,
    draw_bottom_line = draw_bottom_line,
    top_pad = top_pad,
    cl = "cw_title_tree"
  )
}

.cw_title_heights <- function(x) {
  t_h <- .cw_str_h(x$title_text, x$title_gp)
  has_ey <- !is.null(x$eyebrow_text) # TRUE even when eyebrow text is "" (draws rule-only line)
  ey_h <- if (has_ey) .cw_str_h(paste0(.CW_EYEBROW_RULE, toupper(x$eyebrow_text %||_% "")), x$eyebrow_gp) else 0
  # The band (2026-11-07): the eyebrow on an obsidian pill across the header,
  # with a stamp at its right; 10pt of ink above and below the label.
  if (has_ey && isTRUE(x$band)) ey_h <- ey_h + 11
  top <- if (has_ey) (x$top_pad %||_% 8) else 0 # top padding above eyebrow
  bot <- (x$margin_bottom %||_% 2) # bottom padding — carries extra space when no subtitle
  gap1 <- if (has_ey) (if (isTRUE(x$band)) 12 else 8) else 0 # gap: title → eyebrow
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

# The title's drawn geometry, read by the subtitle when it draws the KPI pane
# (ggplot2 renders plot.title before plot.subtitle): the pane rises to the
# top of the title text, so the header reads as two columns.
.cw_state <- new.env(parent = emptyenv())

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
  if (d$has_ey && isTRUE(x$band)) {
    band_gp <- x$eyebrow_gp
    ch <- grid::gList(
      ch,
      grid::roundrectGrob(
        x = grid::unit(0, "npc"), y = grid::unit(ey_y, "pt"), width = grid::unit(1, "npc"),
        height = grid::unit(d$ey_h, "pt"), just = c("left", "center"), r = grid::unit(d$ey_h / 2, "pt"),
        gp = grid::gpar(fill = x$ink_col, col = NA)
      ),
      grid::circleGrob(
        x = grid::unit(11, "pt"), y = grid::unit(ey_y, "pt"), r = grid::unit(2, "pt"),
        gp = grid::gpar(fill = band_gp$col, col = NA)
      ),
      grid::textGrob(
        toupper(x$eyebrow_text), x = grid::unit(20, "pt"), y = grid::unit(ey_y, "pt"),
        just = c("left", "center"),
        gp = grid::gpar(fontfamily = band_gp$fontfamily, fontsize = band_gp$fontsize, col = x$band_text_col)
      ),
      if (!is.null(x$stamp_text) && nzchar(x$stamp_text)) grid::textGrob(
        toupper(x$stamp_text), x = grid::unit(1, "npc") - grid::unit(11, "pt"), y = grid::unit(ey_y, "pt"),
        just = c("right", "center"),
        gp = grid::gpar(fontfamily = band_gp$fontfamily, fontsize = band_gp$fontsize * 0.92, col = x$band_stamp_col)
      )
    )
  } else if (d$has_ey) {
    ch <- grid::gList(
      ch,
      # The eyebrow gesture: a short orange rule, then the mono label.
      grid::linesGrob(
        x = grid::unit(c(0, 14), "pt"),
        y = grid::unit(c(ey_y, ey_y), "pt"),
        gp = grid::gpar(col = x$eyebrow_gp$col, lwd = 1, lend = "butt")
      ),
      grid::textGrob(
        toupper(x$eyebrow_text),
        x = grid::unit(19, "pt"),
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
        gp = grid::gpar(col = x$rule_col, lwd = 0.4, lend = "square")
      )
    )
  }
  if (isTRUE(x$draw_bottom_line)) {
    ch <- grid::gList(
      ch,
      grid::linesGrob(
        x = grid::unit(c(0, 1), "npc"),
        y = grid::unit(c(bln_y, bln_y), "pt"),
        gp = grid::gpar(col = x$rule_col, lwd = 0.4, lend = "square")
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
  lift = 0,
  italic_family = "Cormorant Garamond",
  mono_family = "JetBrains Mono",
  mono_thin_family = "JetBrains Mono Thin",
  display_family = "Schibsted Grotesk SemiBold",
  kpi_label_colour = "#475569",
  gap_ln = 6,
  sub_bot = 20,
  sub_top = 3,
  rule_col = ink_col
) {
  grid::gTree(
    rule_col = rule_col,
    sub_text = sub_text,
    note_text = note_text,
    draw_middle = draw_middle,
    sub_gp = sub_gp,
    note_gp = note_gp,
    sep_gp = sep_gp,
    ink_col = ink_col,
    kpi_data = kpi_data,
    lift = lift,
    italic_family = italic_family,
    mono_family = mono_family,
    mono_thin_family = mono_thin_family,
    display_family = display_family,
    kpi_label_colour = kpi_label_colour,
    gap_ln = gap_ln,
    sub_bot = sub_bot,
    sub_top = sub_top,
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
  top <- if (!has_sub && has_kpi) 8 else (x$sub_top %||_% 3)
  gap_ln <- if (x$draw_middle && has_sub) (x$gap_ln %||_% 6) else 0
  ln_h <- if (x$draw_middle && (has_sub || has_kpi)) 0.3 else 0
  gap_n <- if (has_n) 3 else 0
  # The KPI pane (2026-11-07, option A): a slate pane at the right of the
  # header, spanning the subtitle row and what is below it. The subtitle text
  # sits at its left, on the pane's first row.
  kpi_pane_h <- if (has_kpi) 52 else 0
  kpi_bot_sep <- if (has_kpi) 12 else 0
  bot <- if (has_kpi) {
    max(0, kpi_pane_h - s_h - gap_ln - ln_h - gap_n - n_h) + kpi_bot_sep
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
    kpi_pane_h = kpi_pane_h,
    kpi_bot_sep = kpi_bot_sep,
    has_sub = has_sub,
    total = total
  )
}

# The KPI pane: the latest value with its label, unit and date, and the
# variations as pills, on the slate tint with the `pane` radius, anchored to
# the header's right edge. Widths are measured at draw time (grobwidth).
.cw_kpi_pane <- function(x, d) {
  kpi <- x$kpi_data
  mono_fam <- x$mono_family %||_% "JetBrains Mono"
  colors <- chanwe_get_colors()
  signed <- chanwe_get_signed()
  fg_muted <- x$kpi_label_colour %||_% colors[["fg-muted"]]
  pad <- 11
  gap_x <- 5
  # Up to the title's top when the title drew before us (two columns: the
  # title and subtitle at the left, the pane at the right).
  lift <- x$lift %||_% 0
  pane_top <- d$total + lift
  pane_bot <- d$kpi_bot_sep
  pane_h <- pane_top - pane_bot
  cy <- pane_bot + pane_h / 2
  pt <- function(v) grid::unit(v, "pt")
  w_of <- function(g) grid::convertWidth(grid::grobWidth(g), "pt", valueOnly = TRUE)

  # rows, from the top: label · value · pills
  label <- toupper(paste(Filter(nzchar, c(kpi$unit, kpi$date)), collapse = " \u00b7 "))
  lbl_gp <- grid::gpar(fontfamily = mono_fam, fontsize = 4.6, col = fg_muted)
  val_gp <- grid::gpar(fontfamily = x$display_family %||_% "Schibsted Grotesk SemiBold",
                       fontsize = 16, col = x$ink_col)
  pill_gp <- function(col) grid::gpar(fontfamily = mono_fam, fontsize = 5, col = col)

  lbl_g <- grid::textGrob(label, gp = lbl_gp)
  val_g <- grid::textGrob(kpi$value, gp = val_gp)
  pills <- lapply(kpi$metrics, function(m) {
    valence <- m$valence %||_% m$dir
    col <- if (valence > 0L) signed[["positive"]] else if (valence < 0L) signed[["negative"]] else signed[["neutral"]]
    arrow <- if (m$dir > 0L) "\u2191 " else if (m$dir < 0L) "\u2193 " else ""
    list(label = toupper(m$label), text = paste0(arrow, m$value), col = col,
         lg = grid::textGrob(toupper(m$label), gp = grid::gpar(fontfamily = mono_fam, fontsize = 4.4, col = col)),
         tg = grid::textGrob(paste0(arrow, m$value), gp = pill_gp(col)))
  })
  pill_pad <- 6
  pill_h <- 12
  pill_w <- vapply(pills, function(p) w_of(p$lg) + 3 + w_of(p$tg) + 2 * pill_pad, numeric(1))
  pills_w <- if (length(pills)) sum(pill_w) + gap_x * (length(pills) - 1) else 0
  inner_w <- max(w_of(lbl_g), w_of(val_g), pills_w)
  pane_w <- inner_w + 2 * pad
  x0 <- grid::unit(1, "npc") - pt(pane_w)
  xi <- x0 + pt(pad)

  out <- grid::gList(grid::roundrectGrob(
    x = x0, y = pt(pane_bot), width = pt(pane_w), height = pt(pane_h),
    just = c("left", "bottom"), r = pt(chanwe_tokens$radii$pane * 0.75),
    gp = grid::gpar(fill = colors[["tint"]], col = NA)
  ))
  # The three rows from the pane's top; the pills sit on its foot.
  y_lbl <- pane_top - 12
  y_val <- pane_top - 31
  y_pill <- pane_bot + 9 + pill_h / 2
  out <- grid::gList(out,
    grid::editGrob(lbl_g, x = xi, y = pt(y_lbl), just = c("left", "center")),
    grid::editGrob(val_g, x = xi, y = pt(y_val), just = c("left", "center")))
  cx <- 0
  for (i in seq_along(pills)) {
    p <- pills[[i]]
    px <- xi + pt(cx)
    out <- grid::gList(out,
      grid::roundrectGrob(x = px, y = pt(y_pill), width = pt(pill_w[i]), height = pt(pill_h),
        just = c("left", "center"), r = pt(pill_h / 2),
        gp = grid::gpar(fill = grDevices::adjustcolor(p$col, alpha.f = 0.1), col = NA)),
      grid::editGrob(p$lg, x = px + pt(pill_pad), y = pt(y_pill), just = c("left", "center"),
        gp = grid::gpar(fontfamily = mono_fam, fontsize = 4.4, col = grDevices::adjustcolor(p$col, alpha.f = 0.7))),
      grid::editGrob(p$tg, x = px + pt(pill_pad + w_of(p$lg) + 3), y = pt(y_pill), just = c("left", "center")))
    cx <- cx + pill_w[i] + gap_x
  }
  grid::gTree(children = out)
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
        gp = grid::gpar(col = x$rule_col, lwd = 0.4, lend = "square")
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
    ch <- grid::gList(ch, .cw_kpi_pane(x, d))
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
  ink_col,
  rule_col = ink_col,
  stamp_fill = "#FD3810",
  stamp = TRUE,
  stamp_text = NULL,
  lead_col = "#8A94A6"
) {
  grid::gTree(
    stamp = stamp,
    stamp_text = stamp_text,
    lead_col = lead_col,
    rule_col = rule_col,
    stamp_fill = stamp_fill,
    cap_text = cap_text,
    draw_bottom = draw_bottom,
    cap_gp = cap_gp,
    pfx_gp = pfx_gp,
    sep_gp = sep_gp,
    ink_col = ink_col,
    cl = "cw_caption_tree"
  )
}

# The caption is one quiet mono line under the plot (v2: JetBrains Mono at the
# compact size), with no rule of its own: the slate gridlines already close the
# panel, and a hairline here stacked up against `plot_borders`.
# `caption_style = "stamp"` restores the stamp of chanwer 2.x, a square orange
# box with white mono caps under a hairline.
.cw_caption_heights <- function(x) {
  c_h <- .cw_str_h(toupper(x$cap_text), x$cap_gp)
  fs <- x$cap_gp$fontsize %||_% 5
  stamp <- !isFALSE(x$stamp)
  pad_y <- if (stamp) fs * 0.9 else 0 # stamp inset, top and bottom
  box_h <- c_h + 2 * pad_y
  top <- 16 # space between the chart (or the legend) and the footer's rule
  bot <- 4 # bottom padding
  tln_h <- 0.4 # the footer's rule: what separates the figure from its source
  gap1 <- 8 # gap between the rule and the text
  gap2 <- if (x$draw_bottom) 6 else 0
  bln_h <- if (x$draw_bottom) 0.4 else 0
  total <- bot + bln_h + gap2 + box_h + gap1 + tln_h + top
  list(
    c_h = c_h,
    pad_y = pad_y,
    pad_x = if (stamp) fs * 2.2 else 0,
    box_h = box_h,
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
  # bot | bot_line | gap2 | stamp | gap1 | top_line | top_pad
  bln_y <- d$bot + d$bln_h / 2
  box_y <- d$bot + d$bln_h + d$gap2 + d$box_h / 2
  tln_y <- d$bot + d$bln_h + d$gap2 + d$box_h + d$gap1 + d$tln_h / 2

  # "Fuente · Motor Trend" splits at the first colon or middle dot: the word
  # in the subtle tone, the fact in the caption's own.
  parts <- if (!isFALSE(x$stamp)) NULL else regmatches(x$cap_text, regexec("^([^:\u00b7]{1,16})\\s*[:\u00b7]\\s*(.+)$", x$cap_text))[[1]]
  lead_g <- if (length(parts) == 3L) grid::textGrob(
    toupper(parts[2L]), x = grid::unit(0, "pt"), y = grid::unit(box_y, "pt"),
    just = c("left", "center"), gp = grid::gpar(fontfamily = x$cap_gp$fontfamily, fontsize = x$cap_gp$fontsize, col = x$lead_col %||_% "#8A94A6")
  )
  cap_x <- if (length(parts) == 3L) grid::unit(1, "grobwidth", lead_g) + grid::unit(x$cap_gp$fontsize * 0.9, "pt") else grid::unit(d$pad_x, "pt")
  cap_g <- grid::textGrob(
    toupper(if (length(parts) == 3L) parts[3L] else x$cap_text),
    x = cap_x,
    y = grid::unit(box_y, "pt"),
    just = c("left", "center"),
    gp = x$cap_gp
  )
  # The stamp sits in a flat white pill at the right (2026-11-07).
  stamp_g <- if (!is.null(x$stamp_text) && nzchar(x$stamp_text)) {
    fs <- x$cap_gp$fontsize
    pad <- fs * 1.1
    st <- grid::textGrob(
      toupper(x$stamp_text), x = grid::unit(1, "npc") - grid::unit(pad, "pt"), y = grid::unit(box_y, "pt"),
      just = c("right", "center"), gp = grid::gpar(fontfamily = x$cap_gp$fontfamily, fontsize = fs * 0.9, col = x$cap_gp$col)
    )
    pill <- grid::roundrectGrob(
      x = grid::unit(1, "npc"), y = grid::unit(box_y, "pt"), just = c("right", "center"),
      width = grid::unit(1, "grobwidth", st) + grid::unit(2 * pad, "pt"),
      height = grid::unit(fs * 2.1, "pt"), r = grid::unit(fs * 1.05, "pt"),
      gp = grid::gpar(fill = x$pill_fill %||_% "#FFFFFF", col = NA)
    )
    grid::gTree(children = grid::gList(pill, st))
  }
  box_g <- grid::rectGrob(
    x = grid::unit(0, "npc"),
    y = grid::unit(box_y, "pt"),
    width = grid::unit(1, "grobwidth", cap_g) + grid::unit(2 * d$pad_x, "pt"),
    height = grid::unit(d$box_h, "pt"),
    just = c("left", "center"),
    gp = grid::gpar(fill = x$stamp_fill, col = NA)
  )

  rule <- function(y) {
    grid::linesGrob(
      x = grid::unit(c(0, 1), "npc"),
      y = grid::unit(c(y, y), "pt"),
      gp = grid::gpar(col = x$rule_col, lwd = 0.4, lend = "square")
    )
  }
  ch <- grid::gList(
    if (!isFALSE(x$stamp)) box_g,
    lead_g,
    cap_g,
    stamp_g,
    rule(tln_y),
    if (x$draw_bottom) rule(bln_y)
  )
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
  ink <- element$ink_colour %||_% "#111319"

  parts <- strsplit(as.character(label), .CW_SEP, fixed = TRUE)[[1L]]
  has_eyebrow <- length(parts) >= 2L
  eyebrow_text <- if (has_eyebrow) parts[1L] else NULL
  title_text <- if (has_eyebrow) parts[2L] else parts[1L]
  stamp_text <- if (length(parts) >= 3L) parts[3L] else NULL

  title_gp <- grid::gpar(
    fontfamily = element$family %||_% "Schibsted Grotesk SemiBold",
    fontsize = element$size %||_% 18,
    fontface = element$face %||_% "bold",
    col = element$colour %||_% ink
  )
  eyebrow_gp <- grid::gpar(
    fontfamily = element$eyebrow_family %||_% "JetBrains Mono",
    fontsize = element$eyebrow_size %||_% 6,
    col = element$eyebrow_colour %||_% "#FD3810"
  )

  margin_bottom <- as.numeric(element$margin[3L] %||_% 2)
  tree <- .cw_title_tree(title_text, eyebrow_text, draw_top, title_gp, eyebrow_gp, ink,
                 margin_bottom = margin_bottom,
                 draw_bottom_line = isTRUE(element$draw_bottom_line),
                 top_pad = element$top_pad %||_% 8,
                 rule_col = element$rule_colour %||_% "#CFD6DF",
                 band = identical(element$eyebrow_style %||_% "band", "band"),
                 stamp_text = stamp_text,
                 band_text_col = element$band_text_colour %||_% "#C6CDD6",
                 band_stamp_col = element$band_stamp_colour %||_% "#8A94A6")
  # ggplot2 builds plot.title before plot.subtitle: hand the subtitle the
  # height of the title's text (and its bottom margin), so a KPI pane can
  # rise to the title's top and the header reads as two columns.
  d <- .cw_title_heights(tree)
  .cw_state$title_lift <- d$bot + d$t_h
  tree
}

#' @method element_grob element_chanwe_subtitle
#' @export
element_grob.element_chanwe_subtitle <- function(element, label = "", ...) {
  if (is.null(label) || identical(label, "")) {
    return(grid::nullGrob())
  }

  ink <- element$ink_colour %||_% "#111319"
  mono_fam <- element$mono_family %||_% "JetBrains Mono"
  mono_thin_fam <- element$mono_thin_family %||_% mono_fam
  italic_fam <- element$italic_family %||_% "Cormorant Garamond"
  kpi_label_colour <- element$kpi_label_colour %||_% "#475569"

  parts <- strsplit(as.character(label), .CW_SEP, fixed = TRUE)[[1L]]
  sub_text <- parts[1L]
  note_text <- if (length(parts) >= 2L && nzchar(parts[2L])) parts[2L] else NULL
  kpi_str <- if (length(parts) >= 3L && nzchar(parts[3L])) parts[3L] else NULL
  kpi_data <- .cw_parse_kpi(kpi_str)
  lift <- .cw_state$title_lift %||_% 0
  .cw_state$title_lift <- NULL

  sub_size <- element$size %||_% 9
  sub_gp <- grid::gpar(
    fontfamily = element$family %||_% "Satoshi",
    fontsize = sub_size,
    col = element$colour %||_% "#475569"
  )
  note_gp <- grid::gpar(
    fontfamily = italic_fam,
    fontsize = sub_size * 0.85,
    fontface = "italic",
    col = element$colour %||_% "#475569"
  )
  sep_gp <- grid::gpar(
    fontfamily = mono_fam,
    fontsize = sub_size * 0.65,
    col = element$rule_colour %||_% "#CFD6DF"
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
    lift = lift,
    italic_family = italic_fam,
    mono_family = mono_fam,
    mono_thin_family = mono_thin_fam,
    kpi_label_colour = kpi_label_colour,
    gap_ln = element$gap_ln %||_% 6,
    sub_bot = element$sub_bot %||_% 20,
    sub_top = element$sub_top %||_% 3,
    rule_col = element$rule_colour %||_% "#CFD6DF"
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
  ink <- element$ink_colour %||_% "#111319"
  primary <- element$primary_colour %||_% "#FD3810"
  cap_size <- element$size %||_% 9
  cap_parts <- strsplit(as.character(label), .CW_SEP, fixed = TRUE)[[1L]]
  label <- cap_parts[1L]
  stamp_text <- if (length(cap_parts) >= 2L) cap_parts[2L] else NULL

  rule <- element$rule_colour %||_% "#CFD6DF"
  # The chanwe-report figure-frame stamp: white mono caps on the primary
  # orange, in the medium mono weight so the small caps hold on the fill.
  stamp <- !isFALSE(element$stamp)
  mono_medium <- element$mono_medium_family %||_% "JetBrains Mono Medium"
  has_medium <- stamp && requireNamespace("systemfonts", quietly = TRUE) &&
    mono_medium %in% systemfonts::registry_fonts()$family
  cap_gp <- grid::gpar(
    fontfamily = if (has_medium) mono_medium else element$family %||_% "JetBrains Mono",
    fontsize = cap_size,
    col = element$colour %||_% "#FFFFFF"
  )
  pfx_gp <- grid::gpar(
    fontfamily = element$family %||_% "JetBrains Mono",
    fontsize = cap_size * 0.75,
    col = primary
  )
  sep_gp <- grid::gpar(
    fontfamily = element$family %||_% "JetBrains Mono",
    fontsize = cap_size,
    col = rule
  )

  .cw_caption_tree(
    as.character(label),
    draw_bottom,
    cap_gp,
    pfx_gp,
    sep_gp,
    ink,
    rule_col = rule,
    stamp_fill = primary,
    stamp = stamp,
    stamp_text = stamp_text,
    lead_col = element$lead_colour %||_% "#8A94A6"
  )
}

# Lightweight NULL-coalesce used only within this file
`%||_%` <- function(a, b) if (!is.null(a)) a else b


# ─────────────────────────────────────────────────────────────────────────────
# The plot's surface as a pane (2026-11-07): the `pane` radius and the `rule`
# hairline, so a chart reads like a chanwe_kbl() table or a KPI tile.
# ggplot2 4.0 elements are S7 objects, and it drops a plot.background that is
# not one: there the surface is an S7 subclass of element_rect (built once, on
# first use, so the package still loads with ggplot2 3.5).
.cw_surface_s7 <- new.env(parent = emptyenv())

new_element_chanwe_surface <- function(fill = "#F8FAFC", colour = "#E2E8F0", radius = 9, linewidth = 0.5) {
  if (utils::packageVersion("ggplot2") >= "4.0.0") {
    if (is.null(.cw_surface_s7$class)) {
      .cw_surface_s7$class <- S7::new_class(
        "element_chanwe_surface", parent = ggplot2::element_rect, package = NULL,
        properties = list(radius = S7::class_numeric),
        constructor = function(fill = NULL, colour = NULL, linewidth = NULL, radius = 9) {
          S7::new_object(
            ggplot2::element_rect(fill = fill, colour = colour, linewidth = linewidth),
            radius = radius
          )
        }
      )
    }
    return(.cw_surface_s7$class(fill = fill, colour = colour, linewidth = linewidth, radius = radius))
  }
  structure(
    list(fill = fill, colour = colour, linewidth = linewidth, linetype = 1, radius = radius,
         inherit.blank = FALSE),
    class = c("element_chanwe_surface", "element_rect", "element")
  )
}

#' @method element_grob element_chanwe_surface
#' @export
element_grob.element_chanwe_surface <- function(element, x = 0.5, y = 0.5, width = 1, height = 1, ...) {
  r <- element$radius %||_% 9
  grid::roundrectGrob(
    x = x, y = y, width = width, height = height,
    # a pill asks for more than half its height: grid caps it at half (snpc)
    r = if (r >= 99) grid::unit(0.5, "snpc") else grid::unit(r, "pt"),
    gp = grid::gpar(fill = element$fill, col = element$colour, lwd = (element$linewidth %||_% 0.5) * ggplot2::.pt)
  )
}
