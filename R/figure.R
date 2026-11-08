# chanwe_figure(): the frame around a chart (chanwer 3.2.0, the options rounds
# of 2026-11-07/08). A figure is a ggplot body inside a header card, an
# optional KPI, a legend and a footer, on an outer frame; or, in the editorial
# style, inside a rule, a hanging numeral and a footer line. Drawn with grid,
# so it prints in knitr/Quarto and saves with chanwe_save().

# ── tokens and fonts ─────────────────────────────────────────────────────────
.cwf_colors <- function() {
  cw <- chanwe_get_colors(); sg <- chanwe_get_signed()
  list(P = cw[["primary"]], INK = cw[["ink"]], MU = cw[["fg-muted"]], SU = cw[["fg-subtle"]],
       RULE = cw[["rule"]], COOL = cw[["rule-cool"]], TINT = cw[["surface-slate"]], WHITE = cw[["pure-white"]],
       PAPER = cw[["callout-surface"]] %||_% "#F8FAFC", GREEN = sg[["positive"]], RED = sg[["negative"]],
       NEUTRAL = sg[["neutral"]], INKFG = cw[["ink-fg"]] %||_% "#64748B", RULEINK = cw[["rule-ink"]] %||_% "#434D5D")
}
.cwf_fonts <- function() {
  list(DISP = "Schibsted Grotesk SemiBold", MONO = "JetBrains Mono", SANS = "Satoshi",
       SERIF = "Instrument Serif", ITAL = "Cormorant Garamond")
}
# Compact dimensions in pt, for a figure drawn about 255pt wide and shown at
# full text width (the size the options document was judged at). `scale`
# multiplies them for figures drawn at their real size.
.cwf_dims <- function(scale = 1) {
  d <- list(ip = 7.5, title = 10, gap = 1.2, sub = 6, sub_line = 7, band_h = 8.5, band_y = 5.5,
            eye = 3.9, stamp = 3.6, numeral = 24, foot_h = 11.5, foot_txt = 3.6, pill_h = 6.5,
            pill_txt = 3.3, pad = 8, radius = 9, kpi_h = 43, pill = 3.9)
  lapply(d, function(v) v * scale)
}

# ── grid primitives; y is measured from the top of the current viewport ─────
.cwf_state <- new.env(parent = emptyenv())
.cwf_state$k <- 1
.cwf_u <- function(v) grid::unit(v * .cwf_state$k, "pt")
.cwf_X <- function(x) if (inherits(x, "unit")) x else if (x < 0) grid::unit(1, "npc") - .cwf_u(-x) else .cwf_u(x)
.cwf_Y <- function(y) grid::unit(1, "npc") - .cwf_u(y)
.cwf_gp <- function(fam, size, col, face = "plain") grid::gpar(fontfamily = fam, fontsize = size * .cwf_state$k, col = col, fontface = face)
.cwf_txt <- function(lbl, x, y, fam, size, col, just = c("left", "center"), face = "plain") {
  grid::grid.text(lbl, x = .cwf_X(x), y = .cwf_Y(y), just = just, gp = .cwf_gp(fam, size, col, face))
}
.cwf_tw <- function(lbl, fam, size) {
  grid::convertWidth(grid::grobWidth(grid::textGrob(lbl, gp = .cwf_gp(fam, size, "black"))), "pt", valueOnly = TRUE) / .cwf_state$k
}
.cwf_rr <- function(x, y, w, h, fill, col = NA, r = h / 2, lwd = .5) {
  grid::grid.roundrect(x = .cwf_X(x), y = .cwf_Y(y), width = .cwf_u(w), height = .cwf_u(h),
                       just = c("left", "top"), r = .cwf_u(r), gp = grid::gpar(fill = fill, col = col, lwd = lwd * .cwf_state$k))
}
.cwf_hline <- function(x0, x1, y, col, lwd = .5) {
  grid::grid.lines(x = grid::unit.c(.cwf_X(x0), .cwf_X(x1)), y = grid::unit.c(.cwf_Y(y), .cwf_Y(y)), gp = grid::gpar(col = col, lwd = lwd * .cwf_state$k))
}
.cwf_vline <- function(x, y0, y1, col, lwd = .5) {
  grid::grid.lines(x = grid::unit.c(.cwf_X(x), .cwf_X(x)), y = grid::unit.c(.cwf_Y(y0), .cwf_Y(y1)), gp = grid::gpar(col = col, lwd = lwd * .cwf_state$k))
}
.cwf_dot <- function(x, y, r, col) grid::grid.circle(x = .cwf_X(x), y = .cwf_Y(y), r = .cwf_u(r), gp = grid::gpar(fill = col, col = NA))
.cwf_mono <- function(lbl, x, y, size, col, just = c("left", "center")) .cwf_txt(toupper(lbl), x, y, .cwf_fonts()$MONO, size, col, just)
.cwf_wrap <- function(text, fam, size, width) {
  words <- strsplit(text, " ")[[1]]
  lines <- character(0); cur <- ""
  for (w in words) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (nzchar(cur) && .cwf_tw(cand, fam, size) > width) { lines <- c(lines, cur); cur <- w } else cur <- cand
  }
  c(lines, cur)
}

# ── KPI ──────────────────────────────────────────────────────────────────────
# A KPI is a chanwe_kpi() string; it is parsed into the value, its unit and
# period, and the changes (label, value, direction, valence).
.cwf_kpi <- function(kpi) {
  if (is.null(kpi)) return(NULL)
  k <- if (is.list(kpi)) kpi else .cw_parse_kpi(kpi)
  if (is.null(k)) return(NULL)
  k$unit_line <- paste(Filter(nzchar, c(k$unit, k$date)), collapse = " · ")
  k
}
.cwf_change_col <- function(m, C) {
  v <- m$valence %||_% m$dir
  if (v > 0) C$GREEN else if (v < 0) C$RED else C$NEUTRAL
}
.cwf_change_lbl <- function(m) {
  arrow <- if (m$dir > 0) "↑ " else if (m$dir < 0) "↓ " else "= "
  paste(m$label, paste0(arrow, m$value))
}
.cwf_pills_w <- function(k, d) {
  F <- .cwf_fonts()
  sum(vapply(k$metrics, function(m) .cwf_tw(toupper(.cwf_change_lbl(m)), F$MONO, d$pill) + 7.2, numeric(1))) +
    2.5 * (length(k$metrics) - 1)
}
.cwf_pills <- function(k, x, y, d, C, stack = FALSE) {
  F <- .cwf_fonts()
  for (m in k$metrics) {
    col <- .cwf_change_col(m, C); lbl <- toupper(.cwf_change_lbl(m))
    w <- .cwf_tw(lbl, F$MONO, d$pill) + 7.2
    .cwf_rr(x, y - 4.25, w, 8.5, grDevices::adjustcolor(col, alpha.f = .12))
    .cwf_txt(lbl, x + 3.6, y, F$MONO, d$pill, col)
    if (stack) y <- y + 11 else x <- x + w + 2.5
  }
}
.cwf_kpi_pane <- function(k, x0, top, h, d, C, fill) {
  F <- .cwf_fonts()
  w <- .cwf_pills_w(k, d) + 14
  .cwf_rr(x0, top, w, h, fill, r = 6)
  .cwf_mono(k$unit_line, x0 + 7, top + 8.5, 3.7, C$MU)
  .cwf_txt(k$value, x0 + 7, top + 20.5, F$DISP, 13, C$INK)
  .cwf_pills(k, x0 + 7, top + h - 9, d, C)
}
.cwf_kpi_row <- function(k, x0, top, w, d, C, fill) {
  F <- .cwf_fonts()
  h <- 18
  .cwf_rr(x0, top, w, h, fill, r = 6)
  .cwf_txt(k$value, x0 + 7, top + h / 2, F$DISP, 11.5, C$INK)
  x <- x0 + 7 + .cwf_tw(k$value, F$DISP, 11.5) + 5
  .cwf_mono(k$unit_line, x, top + h / 2 + .5, 3.7, C$MU)
  .cwf_pills(k, x0 + w - 7 - .cwf_pills_w(k, d), top + h / 2, d, C)
}

# ── the header card: one composition rule for every kind ────────────────────
# Two columns: the left one holds the eyebrow (C, dark), the title and the
# subtitle, with the numeral before it (C); the right one, stacked on one left
# edge from the top and only when it holds something, the eyebrow (D), the tag,
# the legend and the KPI pane. A hairline divides them over the content's full
# height. A tag alone rides on the eyebrow's line. The KPI pane drops to a row
# under the title when the title needs the width.
.cwf_header <- function(s, W, pad, d, C) {
  F <- .cwf_fonts()
  kind <- s$header; dark <- kind == "dark"; bare <- !dark && s$header_fill == "none"
  x0 <- pad; w <- W - 2 * pad
  ip <- if (bare) 0 else d$ip
  tcol <- if (dark) C$COOL else C$INK; scol <- if (dark) C$SU else C$MU
  line_t <- d$title * 1.14; line_s <- d$sub * 1.45; slot <- d$eye + 4.6
  legend <- s$legend == "header" && length(s$keys) > 0
  k <- s$kpi; kpi <- !is.null(k) && s$kpi_position == "pane"
  eyebrow_w <- if (!is.null(s$eyebrow)) .cwf_tw(toupper(s$eyebrow), F$MONO, d$eye) + 5.5 else 0
  tag_w <- if (!is.null(s$tag)) .cwf_tw(toupper(s$tag), F$MONO, d$stamp) else 0
  kpi_row <- FALSE
  if (kpi) {
    nw0 <- if (kind == "C" && !is.null(s$numeral)) .cwf_tw(s$numeral, F$SERIF, d$numeral) + 6 else 0
    room <- w - 2 * ip - (.cwf_pills_w(k, d) + 14) - 18 - nw0
    longest <- max(vapply(strsplit(s$title, " ")[[1]], function(x) .cwf_tw(x, F$DISP, d$title), numeric(1)))
    kpi_row <- room < max(longest + 6, 118)
  }
  tag_inline <- kind %in% c("C", "dark") && !legend && !(kpi && !kpi_row)
  right <- list()
  if (kind == "D" && !is.null(s$eyebrow)) right <- c(right, list(list(type = "eyebrow", h = slot, w = eyebrow_w)))
  if (!is.null(s$tag) && (kind == "D" || (kind %in% c("C", "dark") && !tag_inline)))
    right <- c(right, list(list(type = "tag", h = slot, w = tag_w)))
  if (legend) {
    if (kind == "D") {
      kw <- sum(vapply(names(s$keys), function(n) .cwf_tw(toupper(n), F$MONO, d$eye) + 6, numeric(1))) + 9 * (length(s$keys) - 1)
      right <- c(right, list(list(type = "keys", h = slot + .6, w = kw)))
    } else for (n in names(s$keys)) right <- c(right, list(list(type = "key", key = n, h = slot + .6, w = .cwf_tw(toupper(n), F$MONO, d$eye) + 6)))
  }
  if (kpi && !kpi_row) right <- c(right, list(list(type = "pane", h = d$kpi_h, w = .cwf_pills_w(k, d) + 14)))
  gap_group <- 3.5
  right_w <- if (length(right)) max(vapply(right, `[[`, numeric(1), "w")) else 0
  right_h <- if (length(right)) sum(vapply(right, `[[`, numeric(1), "h")) + gap_group * (kind != "A" && (legend || kpi) && length(right) > 1) else 0
  col_gap <- if (length(right)) 18 else 0
  nw <- if (kind == "C" && !is.null(s$numeral)) .cwf_tw(s$numeral, F$SERIF, d$numeral) + 6 else 0
  left_w <- w - 2 * ip - right_w - col_gap - nw
  t_lines <- .cwf_wrap(s$title, F$DISP, d$title, left_w)
  s_lines <- if (!is.null(s$subtitle)) .cwf_wrap(s$subtitle, F$SANS, d$sub, left_w) else character(0)
  has_eye <- kind %in% c("C", "dark") && !is.null(s$eyebrow)
  left_h <- (if (has_eye) slot + 1.5 else 0) + length(t_lines) * line_t + (if (length(s_lines)) 1.5 + length(s_lines) * line_s else 0)
  band <- kind == "A"
  bo <- if (bare) 0 else d$band_y
  band_block <- if (band) bo + d$band_h + (if (bare) 7 else 6.5) else 0
  row_h <- if (kpi_row) 18 + 6 else 0
  content_h <- max(left_h, right_h) + row_h
  h <- band_block + (if (band) 0 else ip) + content_h + ip + (if (bare) 1 else 0)
  if (!bare) .cwf_rr(x0, pad, w, h, if (dark) C$INK else C$TINT, r = 7)
  if (dark) {
    for (xx in seq(x0 + 5, x0 + w - 3, by = 7)) for (yy in seq(pad + 4, pad + h - 3, by = 7))
      .cwf_dot(xx, yy, .26, grDevices::adjustcolor(C$INKFG, alpha.f = .45))
  }
  eyebrow_line <- function(x, y, label_col) {
    .cwf_dot(x + 1.3, y, 1.3, C$P); .cwf_mono(s$eyebrow, x + 5.5, y, d$eye, label_col)
  }
  if (band) {
    by <- pad + bo
    .cwf_rr(x0 + bo, by, w - 2 * bo, d$band_h, C$INK)
    if (!is.null(s$eyebrow)) eyebrow_line(x0 + bo + 5.5, by + d$band_h / 2, C$COOL)
    if (!is.null(s$tag)) .cwf_mono(s$tag, -(pad + bo + 6), by + d$band_h / 2, d$stamp, C$SU, c("right", "center"))
  }
  top <- pad + (if (band) band_block else ip)
  lx <- x0 + ip + nw
  if (kind == "C" && !is.null(s$numeral)) .cwf_txt(s$numeral, x0 + ip - 1, top + left_h / 2 + 1, F$SERIF, d$numeral, C$P)
  y <- top
  if (has_eye) {
    eyebrow_line(lx, y + slot / 2, if (dark) C$P else C$INK)
    if (tag_inline && !is.null(s$tag)) .cwf_mono(s$tag, -(pad + ip), y + slot / 2, d$stamp, if (dark) C$SU else C$MU, c("right", "center"))
    y <- y + slot + 1.5
  }
  for (l in t_lines) { .cwf_txt(l, lx, y + line_t / 2, F$DISP, d$title, tcol); y <- y + line_t }
  if (length(s_lines)) y <- y + 1.5
  for (l in s_lines) { .cwf_txt(l, lx, y + line_s / 2, F$SANS, d$sub, scol); y <- y + line_s }
  if (length(right)) {
    rx <- x0 + w - ip - right_w
    .cwf_vline(rx - col_gap / 2, top + 1, top + content_h - row_h - 1, if (dark) C$RULEINK else C$COOL)
    y <- top; prev <- NULL
    for (it in right) {
      if (!is.null(prev) && prev %in% c("eyebrow", "tag") && it$type %in% c("key", "keys", "pane")) y <- y + gap_group
      if (it$type == "eyebrow") eyebrow_line(rx, y + it$h / 2, C$INK)
      if (it$type == "tag") .cwf_mono(s$tag, rx, y + it$h / 2, d$stamp, if (dark) C$SU else C$MU)
      if (it$type == "key") {
        .cwf_dot(rx + 1.6, y + it$h / 2, 1.6, s$keys[[it$key]])
        .cwf_txt(toupper(it$key), rx + 6, y + it$h / 2, F$MONO, d$eye, if (dark) C$COOL else C$MU)
      }
      if (it$type == "keys") {
        kx <- rx
        for (n in names(s$keys)) {
          .cwf_dot(kx + 1.6, y + it$h / 2, 1.6, s$keys[[n]])
          .cwf_txt(toupper(n), kx + 6, y + it$h / 2, F$MONO, d$eye, if (dark) C$COOL else C$MU)
          kx <- kx + .cwf_tw(toupper(n), F$MONO, d$eye) + 15
        }
      }
      if (it$type == "pane") .cwf_kpi_pane(k, rx, y, it$h, d, C, if (bare) C$TINT else C$PAPER)
      y <- y + it$h; prev <- it$type
    }
  }
  if (kpi_row) .cwf_kpi_row(k, x0 + ip, top + content_h - 18, w - 2 * ip, d, C, if (bare) C$TINT else C$PAPER)
  pad + h
}

.cwf_kpi_strip <- function(k, pad, y, d, C) {
  F <- .cwf_fonts()
  .cwf_txt(k$value, pad + 2, y + 7, F$DISP, 15, C$INK)
  x <- pad + 2 + .cwf_tw(k$value, F$DISP, 15) + 5
  .cwf_mono(k$unit_line, x, y + 9, 3.9, C$MU)
  .cwf_pills(k, x + .cwf_tw(toupper(k$unit_line), F$MONO, 3.9) + 8, y + 8, d, C)
  y + 17
}
.cwf_kpi_rail <- function(k, x, y, h, d, C) {
  F <- .cwf_fonts()
  .cwf_txt(k$value, x, y + 11, F$DISP, 16, C$INK)
  .cwf_mono(k$unit_line, x, y + 23, 3.7, C$MU)
  .cwf_pills(k, x, y + 35, d, C, stack = TRUE)
  .cwf_vline(x + 56, y + 2, y + h - 2, C$RULE)
}
.cwf_legend_pill <- function(keys, W, y, C) {
  F <- .cwf_fonts()
  labs_ <- toupper(names(keys))
  ws <- vapply(labs_, function(l) .cwf_tw(l, F$MONO, 4.1), numeric(1))
  total <- sum(ws) + 12 + 18 * (length(labs_) - 1) + 5.5 * length(labs_) - 6
  x0 <- (W - total) / 2
  .cwf_rr(x0, y - 4.5, total, 9, NA, C$RULE)
  x <- x0 + 6
  for (i in seq_along(labs_)) {
    .cwf_dot(x + 1.8, y, 1.8, keys[[i]]); .cwf_txt(labs_[i], x + 5.5, y, F$MONO, 4.1, C$MU)
    x <- x + ws[i] + 18
  }
}
.cwf_footer <- function(s, W, H, pad, d, C, radius) {
  fh <- d$foot_h; y0 <- H - fh; yc <- y0 + fh / 2
  src <- function(y) {
    if (is.null(s$source)) return(invisible())
    .cwf_mono(s$source_label, pad, y, d$foot_txt, C$SU)
    .cwf_mono(s$source, pad + .cwf_tw(toupper(s$source_label), .cwf_fonts()$MONO, d$foot_txt) + 5, y, d$foot_txt, C$MU)
  }
  if (s$footer == "rule") {
    .cwf_hline(pad, -pad, y0, C$RULE)
    src(yc)
    if (!is.null(s$id)) {
      w <- .cwf_tw(toupper(s$id), .cwf_fonts()$MONO, d$pill_txt) + 7
      .cwf_rr(W - pad - w, yc - d$pill_h / 2, w, d$pill_h, C$WHITE)
      .cwf_mono(s$id, W - pad - w + 3.5, yc, d$pill_txt, C$MU)
    }
  } else {
    if (s$frame == "none") {
      .cwf_rr(pad, y0 + 1, W - 2 * pad, fh - 2, C$TINT, r = 5.5)
    } else {
      .cwf_rr(0.5, y0, W - 1, fh - .5, C$TINT, r = radius)
      grid::grid.rect(x = .cwf_X(0.5), y = .cwf_Y(y0), width = .cwf_u(W - 1), height = .cwf_u(fh / 2),
                      just = c("left", "top"), gp = grid::gpar(fill = C$TINT, col = NA))
    }
    src(yc)
    if (!is.null(s$id)) .cwf_mono(s$id, -(pad + (if (s$frame == "none") 6 else 0)), yc, d$pill_txt, C$MU, c("right", "center"))
  }
}

# The plot inside the frame: its own title, subtitle, caption and legend are
# the frame's, and its surface is the card's.
.cwf_body <- function(plot) {
  plot + ggplot2::theme(
    plot.title = ggplot2::element_blank(), plot.subtitle = ggplot2::element_blank(),
    plot.caption = ggplot2::element_blank(), legend.position = "none",
    plot.background = ggplot2::element_rect(fill = NA, colour = NA),
    panel.background = ggplot2::element_rect(fill = NA, colour = NA),
    plot.margin = ggplot2::margin(4, 2, 0, 0)
  )
}

# The keys of a plot's colour (or fill) legend, as a named vector.
.cwf_keys <- function(plot) {
  for (aes in c("colour", "fill")) {
    g <- tryCatch(ggplot2::get_guide_data(plot, aes), error = function(e) NULL)
    if (!is.null(g) && nrow(g) > 0 && aes %in% names(g)) return(stats::setNames(as.character(g[[aes]]), as.character(g$.label)))
  }
  NULL
}

.cwf_draw_card <- function(s, W, H) {
  C <- .cwf_colors(); d <- .cwf_dims(1)
  pad <- d$pad; radius <- d$radius
  if (s$frame == "shadow") {
    radius <- d$radius + 1
    for (i in 6:1) .cwf_rr(0.5 + i * .2, 1 + i * .55, W - 1 - i * .4, H - 3,
                           grDevices::adjustcolor(C$INK, alpha.f = .011 * (7 - i)), r = radius + i)
    .cwf_rr(0.5, 0.5, W - 1, H - 3, C$PAPER, NA, r = radius)
    H <- H - 2.5
  } else if (s$frame == "simple") {
    .cwf_rr(0.25, 0.25, W - .5, H - .5, C$PAPER, C$RULE, r = radius)
  } else {
    pad <- 1
  }
  y <- .cwf_header(s, W, pad, d, C)
  if (!is.null(s$kpi) && s$kpi_position == "strip") y <- .cwf_kpi_strip(s$kpi, pad, y + 4, d, C)
  y <- y + 5
  pill_legend <- s$legend == "pill" && length(s$keys) > 0
  bottom <- H - d$foot_h - (if (pill_legend) 14 else 4)
  x0 <- pad
  if (!is.null(s$kpi) && s$kpi_position == "rail") { .cwf_kpi_rail(s$kpi, pad + 2, y, bottom - y, d, C); x0 <- pad + 62 }
  grid::pushViewport(grid::viewport(x = .cwf_u(x0), y = .cwf_Y(y), width = .cwf_u(W - x0 - pad),
                                    height = .cwf_u(bottom - y), just = c("left", "top")))
  grid::grid.draw(ggplot2::ggplotGrob(.cwf_body(s$plot)))
  grid::popViewport()
  if (pill_legend) .cwf_legend_pill(s$keys, W, bottom + 7, C)
  .cwf_footer(s, W, H, pad, d, C, radius)
}

# The editorial style: no frame, no bands, no pills. An ink rule with the
# orange tab on top, the numeral hanging at the left, the eyebrow and the tag
# on one line, the title and subtitle; the KPI as plain type; the footer a
# rule with the source and the ID.
.cwf_draw_editorial <- function(s, W, H) {
  C <- .cwf_colors(); d <- .cwf_dims(1); F <- .cwf_fonts()
  pad <- 2
  .cwf_hline(pad, -pad, pad + .3, C$INK, .7)
  grid::grid.rect(x = .cwf_X(pad), y = .cwf_Y(pad - .9), width = .cwf_u(18), height = .cwf_u(2.4),
                  just = c("left", "top"), gp = grid::gpar(fill = C$P, col = NA))
  y <- pad + 10
  x <- pad
  if (!is.null(s$numeral)) {
    .cwf_txt(s$numeral, pad - 1, y + 11, F$SERIF, 28, C$P)
    x <- pad + .cwf_tw(s$numeral, F$SERIF, 28) + 8
  }
  if (!is.null(s$eyebrow)) { .cwf_dot(x + 1.3, y + 2, 1.3, C$P); .cwf_mono(s$eyebrow, x + 5.5, y + 2, d$eye, C$INK) }
  if (!is.null(s$tag)) .cwf_mono(s$tag, -pad, y + 2, d$stamp, C$MU, c("right", "center"))
  yy <- y + 9
  for (l in .cwf_wrap(s$title, F$DISP, 11, W - x - pad)) { .cwf_txt(l, x, yy + 6, F$DISP, 11, C$INK); yy <- yy + 12.5 }
  if (!is.null(s$subtitle)) for (l in .cwf_wrap(s$subtitle, F$SANS, 6.2, W - x - pad)) { .cwf_txt(l, x, yy + 4.5, F$SANS, 6.2, C$MU); yy <- yy + 8.6 }
  k <- s$kpi
  if (!is.null(k)) {
    yy <- yy + 4
    .cwf_txt(k$value, x, yy + 6, F$DISP, 13, C$INK)
    xx <- x + .cwf_tw(k$value, F$DISP, 13) + 5
    .cwf_mono(k$unit_line, xx, yy + 7, 3.7, C$MU); xx <- xx + .cwf_tw(toupper(k$unit_line), F$MONO, 3.7) + 10
    for (m in k$metrics) {
      lbl <- toupper(.cwf_change_lbl(m)); .cwf_mono(lbl, xx, yy + 7, 4, .cwf_change_col(m, C)); xx <- xx + .cwf_tw(lbl, F$MONO, 4) + 9
    }
    yy <- yy + 13
  }
  y <- yy + 6
  fh <- 13; bottom <- H - fh - 4
  grid::pushViewport(grid::viewport(x = .cwf_u(pad), y = .cwf_Y(y), width = .cwf_u(W - 2 * pad),
                                    height = .cwf_u(bottom - y), just = c("left", "top")))
  grid::grid.draw(ggplot2::ggplotGrob(.cwf_body(s$plot)))
  grid::popViewport()
  y0 <- H - fh
  .cwf_hline(pad, -pad, y0, C$RULE, .5)
  if (!is.null(s$source)) {
    .cwf_mono(s$source_label, pad, y0 + fh / 2, 3.7, C$SU)
    .cwf_mono(s$source, pad + .cwf_tw(toupper(s$source_label), F$MONO, 3.7) + 5, y0 + fh / 2, 3.7, C$MU)
  }
  if (!is.null(s$id)) .cwf_mono(s$id, -pad, y0 + fh / 2, 3.6, C$SU, c("right", "center"))
}

#' Chanwe Figure Frame
#'
#' Draws a ggplot inside the Chanwe figure frame: a header card (a title, a
#' subtitle, an eyebrow naming the topic and a tag naming the section), an
#' optional KPI, a legend, and a footer with the source and the document ID, on
#' an outer frame. Or, with `style = "editorial"`, inside an ink rule with the
#' orange tab, a hanging figure numeral, plain-type KPI and a footer rule.
#'
#' The plot keeps its body: theme it with [theme_chanwe()] and write the
#' marks; the frame replaces its title, subtitle, caption and legend.
#'
#' **The header** follows one composition rule. Two columns: the eyebrow
#' (kinds C and dark), the title and the subtitle at the left, with the numeral
#' before them in C; at the right, stacked from the top on one edge, the
#' eyebrow (D), the tag, the legend and the KPI pane, after a hairline. The
#' right column exists only when it holds something; a tag alone rides on the
#' eyebrow's line. The KPI pane drops to a row under the title when the title
#' needs the width. The ID lives only in the footer; the header carries the
#' `tag` (a section, a series, a period).
#'
#' @param plot A ggplot.
#' @param title,subtitle The title, and a subtitle that says what is measured,
#'   in what unit and over what period.
#' @param eyebrow The topic, as a mono label after the orange dot
#'   (`"Sector externo · Reservas"`).
#' @param tag The section or series, at the right of the header
#'   (`"Monitor macro · 3.2"`). Not the ID: that goes to `id`.
#' @param numeral The figure number in Instrument Serif, for `header = "C"`
#'   and the editorial style (`"07"`).
#' @param kpi A [chanwe_kpi()] string.
#' @param kpi_position `"pane"` (in the header's right column, or a row under
#'   the title when the width is short), `"strip"` (a line under the header) or
#'   `"rail"` (a column at the left of the plot).
#' @param header `"A"` (the obsidian band with the eyebrow and the tag),
#'   `"C"` (the numeral), `"D"` (two columns) or `"dark"` (an obsidian card).
#' @param header_fill `"tint"` or `"none"`. With a frame, `"none"` avoids a
#'   card inside a card; without a frame, `"tint"` closes the piece.
#' @param legend `"pill"` (one pill under the plot), `"header"` (in the
#'   header's right column) or `"none"`. Use `"none"` when the plot labels its
#'   series directly.
#' @param keys Named colours for the legend. Default: read from the plot's
#'   colour or fill legend.
#' @param source,source_label The source, after its label (`"Fuente"`).
#' @param id The document ID, at the right of the footer.
#' @param footer `"rule"` (a hairline, the ID in a white pill) or `"tint"` (a
#'   tinted strip).
#' @param frame `"simple"` (the `rule` hairline and the pane radius),
#'   `"shadow"` or `"none"`.
#' @param style `"card"` or `"editorial"`.
#' @param scale Multiplies every dimension of the frame. Default `NULL`: the
#'   frame follows the figure's width (1 at 3.54 in, 2 at 7.08 in), so it keeps
#'   its proportions at any size.
#' @return An object of class `chanwe_figure`; it draws when printed. Save it
#'   with [chanwe_save()].
#' @seealso [chanwe_save()], [annotate_chanwe_main()], [chanwe_kpi()],
#'   [chanwe_kbl()] for tables with the same header and footer.
#' @export
#' @examples
#' \dontrun{
#' p <- ggplot2::ggplot(economics, ggplot2::aes(date, unemploy)) +
#'   ggplot2::geom_line(colour = chanwe_get_colors()[["primary"]]) +
#'   theme_chanwe(pane = FALSE)
#' chanwe_figure(p, title = "Desempleo", subtitle = "Personas, miles, 1967-2015",
#'               eyebrow = "Mercado laboral", tag = "Monitor · 2.1",
#'               source = "BLS", id = "CHW · ML-02 · 2026")
#' }
chanwe_figure <- function(plot, title, subtitle = NULL, eyebrow = NULL, tag = NULL, numeral = NULL,
                          kpi = NULL, kpi_position = c("pane", "strip", "rail"),
                          header = c("A", "C", "D", "dark"), header_fill = c("tint", "none"),
                          legend = c("pill", "header", "none"), keys = NULL,
                          source = NULL, source_label = "Fuente", id = NULL,
                          footer = c("rule", "tint"), frame = c("simple", "shadow", "none"),
                          style = c("card", "editorial"), scale = NULL) {
  stopifnot(inherits(plot, "ggplot"))
  spec <- list(
    plot = plot, title = title, subtitle = subtitle, eyebrow = eyebrow, tag = tag, numeral = numeral,
    kpi = .cwf_kpi(kpi), kpi_position = match.arg(kpi_position),
    header = match.arg(header), header_fill = match.arg(header_fill),
    legend = match.arg(legend), keys = keys %||_% .cwf_keys(plot),
    source = source, source_label = source_label, id = id,
    footer = match.arg(footer), frame = match.arg(frame), style = match.arg(style), scale = scale
  )
  structure(spec, class = "chanwe_figure")
}

#' @export
print.chanwe_figure <- function(x, ...) {
  grid::grid.newpage()
  W <- grid::convertWidth(grid::unit(1, "npc"), "pt", valueOnly = TRUE)
  H <- grid::convertHeight(grid::unit(1, "npc"), "pt", valueOnly = TRUE)
  # Every dimension is written in pt at scale 1 (a 255pt-wide figure); the
  # primitives multiply by k, so the frame keeps its proportions at any size.
  k <- x$scale %||_% (W / 255)
  .cwf_state$k <- k
  W <- W / k; H <- H / k
  if (identical(x$style, "editorial")) .cwf_draw_editorial(x, W, H) else .cwf_draw_card(x, W, H)
  invisible(x)
}

#' Save a Chanwe Figure
#'
#' Writes a [chanwe_figure()] (or any ggplot) to PNG, PDF or SVG with the
#' brand fonts. PNG goes through ragg; PDF through cairo; SVG through svglite.
#'
#' @param x A `chanwe_figure` or a ggplot.
#' @param file The output path; the extension picks the device.
#' @param width,height In inches. Default 7.08 x 5.5, a full text width.
#' @param dpi For PNG.
#' @return `file`, invisibly.
#' @export
chanwe_save <- function(x, file, width = 7.08, height = 5.5, dpi = 300) {
  chanwe_load_fonts()
  ext <- tolower(tools::file_ext(file))
  if (ext == "png") {
    chanwe_require_package("ragg")
    ragg::agg_png(file, width = width, height = height, units = "in", res = dpi)
  } else if (ext == "pdf") {
    grDevices::cairo_pdf(file, width = width, height = height)
  } else if (ext == "svg") {
    chanwe_require_package("svglite")
    svglite::svglite(file, width = width, height = height)
  } else stop("chanwe_save(): use .png, .pdf or .svg", call. = FALSE)
  on.exit(grDevices::dev.off())
  print(x)
  invisible(file)
}
