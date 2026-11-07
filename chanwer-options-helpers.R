# Helpers for chanwer-options.qmd, round 2: Ale's choices combined. A chart
# is a card: an outer frame (simple, shadow or none), a header card (A band,
# C numeral, D split, or the dark band), an optional KPI (A pane, B strip,
# C rail), the body (A grid with a "main" series, B extremes with direct
# labels), a legend (A flat pill, C in the header) and a flat footer (A rule
# with the stamp, B tint strip). Prototype code for choosing, not package API.

library(grid)
library(ggplot2)

cw <- chanwe_get_colors()
sg <- chanwe_get_signed()
P <- cw[["primary"]]; INK <- cw[["ink"]]; MU <- cw[["fg-muted"]]; SU <- cw[["fg-subtle"]]
RULE <- cw[["rule"]]; COOL <- cw[["rule-cool"]]; TINT <- "#EBF0F6"; WHITE <- "#FFFFFF"
PAPER <- "#F8FAFC"; GREEN <- sg[["positive"]]; RED <- sg[["negative"]]
EMPH <- if (!is.null(cw[["emphasis"]])) cw[["emphasis"]] else "#484848"
SLATE <- c("#475569", "#8A94A6", "#C6CDD6")
F_DISP <- "Schibsted Grotesk SemiBold"; F_MONO <- "JetBrains Mono"; F_SANS <- "Satoshi"
F_SERIF <- "Instrument Serif"; F_ITAL <- "Cormorant Garamond"

# ── data ─────────────────────────────────────────────────────────────────────
set.seed(7)
n <- 24
res <- data.frame(
  date = rep(seq(as.Date("2024-01-01"), by = "month", length.out = n), 2),
  serie = rep(c("Brutas", "Netas"), each = n),
  value = c(
    28 + seq_len(n) * 0.5 + 1.4 * sin(seq_len(n) / 2.3) + stats::runif(n, -.5, .5),
    24 + seq_len(n) * 0.27 + 1.0 * cos(seq_len(n) / 3.1) + stats::runif(n, -.4, .4)
  )
)
res$serie <- factor(res$serie, levels = c("Brutas", "Netas"))
SERIES <- c(Brutas = P, Netas = SLATE[1])
last <- res[res$date == max(res$date), ]
region <- data.frame(name = c("Brasil", "México", "Argentina", "Chile", "Colombia", "Perú"),
                     value = c(355, 228, 39.5, 46, 59, 74))
monthly <- data.frame(date = seq(as.Date("2025-01-01"), by = "month", length.out = 12),
                      value = c(1.2, 0.8, 1.6, 2.1, 1.4, 0.9, 1.7, 2.4, 1.9, 2.6, 2.2, 3.1))
scat <- data.frame(name = c("Arg", "Bra", "Chi", "Col", "Méx", "Per", "Uru", "Par", "Bol", "Ecu"),
                   x = c(39.5, 355, 46, 59, 228, 74, 17, 10, 3, 6),
                   y = c(4.8, 3.1, 4.4, 2.9, 3.6, 5.1, 3.9, 4.2, 6.1, 2.4))

# ── grid primitives (y from the top of the current viewport) ────────────────
X <- function(x) if (inherits(x, "unit")) x else if (x < 0) unit(1, "npc") - unit(-x, "pt") else unit(x, "pt")
Y <- function(y) unit(1, "npc") - unit(y, "pt")
gp_t <- function(fam, size, col, face = "plain") gpar(fontfamily = fam, fontsize = size, col = col, fontface = face)
txt <- function(lbl, x, y, fam, size, col, just = c("left", "center"), face = "plain") {
  grid.text(lbl, x = X(x), y = Y(y), just = just, gp = gp_t(fam, size, col, face))
}
tw <- function(lbl, fam, size, face = "plain") {
  convertWidth(grobWidth(textGrob(lbl, gp = gp_t(fam, size, "black", face))), "pt", valueOnly = TRUE)
}
rr <- function(x, y, w, h, fill, col = NA, r = h / 2, lwd = .5, just = c("left", "top")) {
  grid.roundrect(x = X(x), y = Y(y), width = unit(w, "pt"), height = unit(h, "pt"), just = just,
                 r = unit(r, "pt"), gp = gpar(fill = fill, col = col, lwd = lwd))
}
hline <- function(x0, x1, y, col = RULE, lwd = .5) {
  grid.lines(x = unit.c(X(x0), X(x1)), y = unit.c(Y(y), Y(y)), gp = gpar(col = col, lwd = lwd))
}
vline <- function(x, y0, y1, col = RULE, lwd = .5) {
  grid.lines(x = unit.c(X(x), X(x)), y = unit.c(Y(y0), Y(y1)), gp = gpar(col = col, lwd = lwd))
}
dot <- function(x, y, r, col) grid.circle(x = X(x), y = Y(y), r = unit(r, "pt"), gp = gpar(fill = col, col = NA))
mono <- function(lbl, x, y, size = 4.6, col = MU, just = c("left", "center")) txt(toupper(lbl), x, y, F_MONO, size, col, just)
pill <- function(lbl, x, y, fill, col, size = 3.9, pad = 3.6, h = 8.5, stroke = NA) {
  w <- tw(toupper(lbl), F_MONO, size) + 2 * pad
  rr(x, y - h / 2, w, h, fill, stroke)
  txt(toupper(lbl), x + pad, y, F_MONO, size, col)
  w
}

TITLE <- "Reservas internacionales"
SUBTITLE <- "Brutas y netas, en miles de millones de dólares"
EYEBROW <- "BCRA · Sector externo"
STAMP <- "CHW · RM-07 · 2026"

# ── dimensions: regular (round 2) and compact (round 3, the default). The
# compact header and footer keep every element and lose height: smaller type
# steps, tighter insets, a slimmer band and stamp.
DIMS <- list(
  regular = list(ip = 8, title = 11.5, gap = 1.5, sub = 6.6, sub_off = 11, sub_line = 8,
                 band_h = 11, band_y = 5, eye = 4.3, stamp = 4, numeral = 30,
                 h = c(A = 46, C = 42, D = 38, Dleg = 60, dark = 44),
                 ty = c(A = 27, C = 15, D = 6, dark = 16), wrap_t = 13, wrap_s = 8, kpi_top = 20,
                 foot_h = 15, foot_txt = 4, pill_h = 8, pill_txt = 3.7),
  compact = list(ip = 6, title = 10, gap = 1.2, sub = 6, sub_off = 9, sub_line = 7,
                 band_h = 8.5, band_y = 4, eye = 3.9, stamp = 3.6, numeral = 24,
                 h = c(A = 34, C = 30.5, D = 27, Dleg = 46, dark = 31.5),
                 ty = c(A = 20.5, C = 11.5, D = 4.5, dark = 12), wrap_t = 11.2, wrap_s = 7, kpi_top = 15,
                 foot_h = 11.5, foot_txt = 3.6, pill_h = 6.5, pill_txt = 3.3)
)
d <- DIMS$compact

# ── the title block: Schibsted at the display weight over the subtitle in
# Satoshi (fg-muted). Wraps to two lines beside a KPI pane. Returns the
# subtitle's y.
title_block <- function(x, y, wrap_w = Inf, on_dark = FALSE) {
  tcol <- if (on_dark) COOL else INK
  scol <- if (on_dark) SU else MU
  if (tw(TITLE, F_DISP, d$title) > wrap_w) {
    txt("Reservas", x, y, F_DISP, d$title, tcol)
    txt("internacionales", x, y + d$title + d$gap, F_DISP, d$title, tcol)
    y <- y + d$title + d$gap
  }
  else txt(TITLE, x, y, F_DISP, d$title, tcol)
  if (tw(SUBTITLE, F_SANS, d$sub) > wrap_w) {
    txt("Brutas y netas, en miles", x, y + d$sub_off, F_SANS, d$sub, scol)
    txt("de millones de dólares", x, y + d$sub_off + d$sub_line, F_SANS, d$sub, scol)
    return(y + d$sub_off + d$sub_line)
  }
  txt(SUBTITLE, x, y + d$sub_off, F_SANS, d$sub, scol)
  y + d$sub_off
}

# ── header cards. Each draws inside [pad, W - pad] from y = pad and returns the
# y where it ends. `right_w` reserves the KPI pane's column at the right.
hdr_card <- function(kind, W, pad, right_w = 0, legend = FALSE, fill = "tint") {
  x0 <- pad; w <- W - 2 * pad; ip <- d$ip
  dark <- kind == "dark"
  h <- if (kind == "D" && legend) d$h[["Dleg"]] else d$h[[kind]]
  nw <- d$numeral * 1.05
  # The width the title block gets, before drawing, so the card grows with it.
  avail <- w - 2 * ip - (if (right_w > 0) right_w + 8 else 0)
  if (legend && kind != "D") avail <- min(avail, w * 0.75 - 2 * ip)
  avail <- avail - switch(kind, C = nw, D = 84, 0)
  if (tw(TITLE, F_DISP, d$title) > avail) h <- h + d$wrap_t
  if (tw(SUBTITLE, F_SANS, d$sub) > avail) h <- h + d$wrap_s
  # The card's ground: the tint, or none (the header sits on the chart's own
  # surface, transparent). The dark card always has its ink.
  if (dark || fill != "none") rr(x0, pad, w, h, if (dark) INK else TINT, r = 7)
  bare <- !dark && fill == "none"
  if (bare) { ip <- 0; d$band_y <- 0 }
  if (dark) {  # the dot field of the report's band
    for (xx in seq(x0 + 5, x0 + w - 3, by = 7)) for (yy in seq(pad + 4, pad + h - 3, by = 7)) dot(xx, yy, .26, grDevices::adjustcolor("#64748B", alpha.f = .45))
  }
  inner_w <- w - 2 * ip - (if (right_w > 0) right_w + 8 else 0)
  # With the legend in the header, the card splits 75 / 25: the title block in
  # the first column, the series stacked in the second, after a hairline.
  leg_x <- NULL
  if (legend && kind != "D") {
    leg_x <- x0 + w * 0.75
    inner_w <- min(inner_w, leg_x - x0 - 2 * ip)
  }
  y <- pad + ip
  ey <- y + d$eye / 2 + .5
  if (kind == "A") {
    bh <- d$band_h; by <- pad + (if (bare) 0 else d$band_y)
    rr(x0 + d$band_y, by, w - 2 * d$band_y, bh, INK)
    dot(x0 + d$band_y + 6.5, by + bh / 2, 1.3, P)
    mono(EYEBROW, x0 + d$band_y + 11, by + bh / 2, d$eye, COOL)
    mono(STAMP, -(x0 + d$band_y + 6.5), by + bh / 2, d$stamp, SU, c("right", "center"))
    end <- title_block(x0 + ip, pad + d$ty[["A"]], inner_w)
  } else if (kind == "C") {
    txt("07", x0 + ip - 1, pad + h / 2 - (if (h > d$h[["C"]]) 4 else 0), F_SERIF, d$numeral, P)
    xt <- x0 + ip + nw
    dot(xt + 1.3, ey, 1.3, P); mono(EYEBROW, xt + 5.5, ey, d$eye, INK)
    mono(STAMP, -(x0 + ip), ey, d$stamp, SU, c("right", "center"))
    end <- title_block(xt, y + d$ty[["C"]], inner_w - nw)
  } else if (kind == "D") {
    end <- title_block(x0 + ip, y + d$ty[["D"]], inner_w - 84)
    xr <- W - pad - ip
    vline(xr - 82, y, y + d$h[["D"]] - 2 * ip, COOL)
    ew <- tw(toupper(EYEBROW), F_MONO, d$eye)
    dot(xr - ew - 4, ey, 1.3, P); mono(EYEBROW, xr, ey, d$eye, INK, c("right", "center"))
    mono(STAMP, xr, ey + d$eye + 5, d$stamp, SU, c("right", "center"))
  } else {
    dot(x0 + ip + 1.3, ey, 1.3, P); mono(EYEBROW, x0 + ip + 6, ey, d$eye, P)
    mono(STAMP, -(x0 + ip), ey, d$stamp, SU, c("right", "center"))
    end <- title_block(x0 + ip, y + d$ty[["dark"]], inner_w, on_dark = TRUE)
  }
  if (legend) {
    if (kind == "D") {
      # D already has a right column: the series go under its stamp.
      legend_stack(W - pad - ip - 76, y + d$h[["D"]] - ip + 2, dark)
    } else {
      top <- if (kind == "A") pad + d$kpi_top else y
      vline(leg_x, top, pad + h - ip, if (dark) "#434D5D" else COOL)
      legend_stack(leg_x + 8, (top + pad + h - ip) / 2 - 4.5 * (length(SERIES) - 1), dark)
    }
  }
  pad + h
}

# ── KPI: A pane inside the header card, B strip, C rail ─────────────────────
KPI <- list(value = "39,5", unit = "USD MM · Dic 2025",
            d = list(c("MoM", "↑ 2,1 %", "up"), c("QoQ", "↓ 0,4 %", "down"), c("YoY", "↑ 17,8 %", "up")))
kpi_pills <- function(x, y, stack = FALSE) {
  for (m in KPI$d) {
    col <- if (m[3] == "up") GREEN else RED
    w <- pill(paste(m[1], m[2]), x, y, grDevices::adjustcolor(col, alpha.f = .12), col)
    if (stack) y <- y + 11 else x <- x + w + 2.5
  }
}
KPI_PANE_W <- 112
kpi_pane <- function(W, pad, top, h) {
  x0 <- W - pad - 8 - KPI_PANE_W
  rr(x0, top, KPI_PANE_W, h, PAPER, r = 7)
  mono(KPI$unit, x0 + 7, top + 8, 3.8, MU)
  txt(KPI$value, x0 + 7, top + 20, F_DISP, 13, INK)
  kpi_pills(x0 + 7, top + h - 8)
}
kpi_strip <- function(pad, y) {
  txt(KPI$value, pad + 2, y + 7, F_DISP, 15, INK)
  x <- pad + 2 + tw(KPI$value, F_DISP, 15) + 5
  mono(KPI$unit, x, y + 9, 3.9, MU)
  kpi_pills(x + tw(toupper(KPI$unit), F_MONO, 3.9) + 8, y + 8)
  y + 17
}
kpi_rail <- function(x, y, h) {
  txt(KPI$value, x, y + 11, F_DISP, 16, INK)
  mono(KPI$unit, x, y + 23, 3.7, MU)
  kpi_pills(x, y + 35, stack = TRUE)
  vline(x + 56, y + 2, y + h - 2)
}

# ── legends: A one flat pill under the plot, C in the header card ───────────
legend_pill <- function(W, y, keys) {
  labs_ <- toupper(names(keys))
  ws <- vapply(labs_, function(l) tw(l, F_MONO, 4.1), numeric(1))
  total <- sum(ws) + 12 + 18 * (length(labs_) - 1) + 5.5 * length(labs_) - 6
  x0 <- (W - total) / 2
  rr(x0, y - 4.5, total, 9, NA, RULE)
  x <- x0 + 6
  for (i in seq_along(labs_)) {
    dot(x + 1.8, y, 1.8, keys[[i]]); txt(labs_[i], x + 5.5, y, F_MONO, 4.1, MU)
    x <- x + ws[i] + 18
  }
}
legend_stack <- function(x, y, dark = FALSE, keys = SERIES) {
  for (i in seq_along(keys)) {
    dot(x + 1.8, y, 1.8, keys[[i]])
    txt(toupper(names(keys)[i]), x + 6, y, F_MONO, d$eye, if (dark) COOL else MU)
    y <- y + 9
  }
}
legend_header <- function(xr, y, dark = FALSE, keys = SERIES) {
  x <- xr
  for (i in rev(seq_along(keys))) {
    l <- toupper(names(keys)[i]); w <- tw(l, F_MONO, 4.2)
    txt(l, x - w, y, F_MONO, 4.2, if (dark) COOL else MU); dot(x - w - 3.8, y, 1.8, keys[[i]])
    x <- x - w - 14
  }
}

# ── footers, both flat: A rule and the stamp pill, B tint strip ─────────────
footer <- function(kind, W, H, pad, frame) {
  fh <- d$foot_h
  y0 <- H - fh
  yc <- y0 + fh / 2
  src <- function(y) { mono("Fuente", pad, y, d$foot_txt, SU); mono("BCRA · elaboración propia", pad + d$foot_txt * 5, y, d$foot_txt, MU) }
  if (kind == "A") {
    hline(pad, -pad, y0, RULE)
    src(yc)
    w <- tw(STAMP, F_MONO, d$pill_txt) + 7
    rr(W - pad - w, yc - d$pill_h / 2, w, d$pill_h, WHITE)
    txt(STAMP, W - pad - w + 3.5, yc, F_MONO, d$pill_txt, MU)
  } else {
    if (frame == "none") {
      rr(pad, y0 + 1, W - 2 * pad, fh - 2, TINT, r = 5.5)
      src(yc); mono(STAMP, -(pad + 6), yc, d$pill_txt, MU, c("right", "center"))
      return(invisible())
    }
    rr(0.5, y0, W - 1, fh - .5, TINT, r = 9)
    grid.rect(x = X(0.5), y = Y(y0), width = unit(W - 1, "pt"), height = unit(fh / 2, "pt"),
              just = c("left", "top"), gp = gpar(fill = TINT, col = NA))
    src(yc)
    mono(STAMP, -pad, yc, d$pill_txt, MU, c("right", "center"))
  }
}

# ── the body. A: horizontal grid, and the main series carries the accent, a
# halo on its last point and its value in an ink pill (others in slate, their
# value in mono). B: extremes only, an ink base, each series named at its end.
ink_label <- function(...) {
  geom_label(..., family = F_MONO, size = 1.5, fill = INK, colour = "white",
             label.r = unit(4, "pt"), label.padding = unit(2.3, "pt"))
}
base_theme <- function(grid = "y") {
  theme_chanwe(base_text_size = 6, pane = FALSE, legend_position = "none", grid = grid) +
    theme(plot.margin = margin(2, 2, 0, 0), plot.background = element_rect(fill = NA, colour = NA),
          panel.background = element_rect(fill = NA, colour = NA), axis.text = element_text(size = 4.3))
}
num <- function(v) format(round(v, 1), decimal.mark = ",")
body_plot <- function(body = "A", type = "line") {
  if (type == "line") {
    p <- ggplot(res, aes(date, value, colour = serie))
    if (body == "B") p <- p + geom_hline(yintercept = 22, colour = INK, linewidth = .3)
    p <- p + geom_line(linewidth = .45, lineend = "round")
    if (body == "A") {
      b <- last[last$serie == "Brutas", ]; o <- last[last$serie != "Brutas", ]
      p <- p + geom_point(data = b, size = 3.2, alpha = .18) + geom_point(data = b, size = 1.1) +
        ink_label(data = b, aes(label = num(value)), hjust = -0.22) +
        geom_point(data = o, size = .8) +
        geom_text(data = o, aes(label = num(value)), hjust = -.5, family = F_MONO, size = 1.4)
    } else {
      p <- p + geom_text(data = last, aes(label = paste0(toupper(serie), "  ", num(value))),
                         hjust = 0, nudge_x = 12, family = F_MONO, size = 1.45)
    }
    p <- p + scale_colour_manual(values = SERIES) +
      scale_x_date(date_labels = "%b %y", breaks = seq(as.Date("2024-06-01"), as.Date("2025-12-01"), by = "6 months"),
                   expand = expansion(mult = c(.01, if (body == "B") .26 else .17))) +
      scale_y_continuous(limits = c(22, 42), breaks = if (body == "B") c(22, 42) else c(25, 30, 35, 40),
                         expand = expansion(0)) +
      labs(x = NULL, y = NULL) + base_theme(if (body == "B") "none" else "y")
    if (body == "B") p <- p + theme(panel.grid.major.y = element_line(colour = COOL, linewidth = .2))
    return(p)
  }
  if (type == "bar") {   # a ranking: the main bar in the accent, its value in the ink pill
    d <- region; d$main <- d$name == "Argentina"
    d$name <- stats::reorder(d$name, d$value)
    return(ggplot(d, aes(value, name, fill = main)) +
      geom_chanwe_col(width = .62, orientation = "y") +
      geom_text(data = d[!d$main, ], aes(label = num(value)), hjust = -.25, family = F_MONO, size = 1.4, colour = SLATE[1]) +
      ink_label(data = d[d$main, ], aes(label = num(value)), hjust = -.15) +
      scale_fill_manual(values = c(`TRUE` = P, `FALSE` = SLATE[3]), guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0, .16))) + labs(x = NULL, y = NULL) +
      base_theme("x") + theme(axis.text.y = element_text(size = 4.6, colour = INK)))
  }
  if (type == "column") {  # columns over time: the last month is the main one
    d <- monthly; d$main <- d$date == max(d$date)
    return(ggplot(d, aes(date, value, fill = main)) + geom_chanwe_col(width = 20) +
      ink_label(data = d[d$main, ], aes(label = num(value)), vjust = -.4) +
      scale_fill_manual(values = c(`TRUE` = P, `FALSE` = SLATE[3]), guide = "none") +
      scale_x_date(date_labels = "%b", date_breaks = "2 months") +
      scale_y_continuous(expand = expansion(mult = c(0, .24))) + labs(x = NULL, y = NULL) + base_theme("y"))
  }
  if (type == "scatter") {  # the main point: accent, halo and its name in the ink pill
    d <- scat; d$main <- d$name == "Arg"
    return(ggplot(d, aes(x, y)) +
      geom_point(data = d[!d$main, ], colour = SLATE[2], size = 1.4) +
      geom_text(data = d[!d$main, ], aes(label = toupper(name)), family = F_MONO, size = 1.3, colour = SLATE[1], vjust = -1.2) +
      geom_point(data = d[d$main, ], colour = P, size = 3.6, alpha = .18) +
      geom_point(data = d[d$main, ], colour = P, size = 1.5) +
      ink_label(data = d[d$main, ], aes(label = "ARGENTINA · 4,8 %"), hjust = -.12) +
      scale_x_log10(expand = expansion(mult = c(.05, .2))) + labs(x = NULL, y = NULL) + base_theme("y"))
  }
}

# ── a chart card ─────────────────────────────────────────────────────────────
card <- function(W, H, header = "A", kpi = "none", body = "A", type = "line", legend = "A", foot = "A", frame = "simple",
                 compact = TRUE, hfill = "tint") {
  d <<- if (compact) DIMS$compact else DIMS$regular
  pad <- if (compact) 8 else 10
  if (frame == "shadow") {   # a soft offset shadow, no hairline
    for (i in 6:1) rr(0.5 + i * .2, 1 + i * .55, W - 1 - i * .4, H - 3, grDevices::adjustcolor(INK, alpha.f = .011 * (7 - i)), r = 10 + i)
    rr(0.5, 0.5, W - 1, H - 3, PAPER, NA, r = 10)
    H <- H - 2.5
  } else if (frame == "simple") {
    rr(0.25, 0.25, W - .5, H - .5, PAPER, RULE, r = 9)
  } else {
    pad <- 1
  }
  is_line <- type == "line"
  keys <- if (is_line) SERIES else c(Argentina = P, Resto = SLATE[3])
  right_w <- if (kpi == "A") KPI_PANE_W else 0
  y <- hdr_card(header, W, pad, right_w, legend = legend == "C", fill = hfill)
  if (kpi == "A") {
    top <- pad + (if (header == "A") d$kpi_top else d$ip - 1)
    kpi_pane(W, pad, top, y - 7 - top)
  }
  if (kpi == "B") y <- kpi_strip(pad, y + 4)
  y <- y + 7
  bottom <- H - d$foot_h - (if (legend == "A") 14 else 4)
  x0 <- pad
  if (kpi == "C") { kpi_rail(pad + 2, y, bottom - y); x0 <- pad + 62 }
  pushViewport(viewport(x = unit(x0, "pt"), y = Y(y), width = unit(W - x0 - pad, "pt"),
                        height = unit(bottom - y, "pt"), just = c("left", "top")))
  grid.draw(ggplotGrob(body_plot(body, type)))
  popViewport()
  if (legend == "A") legend_pill(W, bottom + 7, keys)
  footer(foot, W, H, pad, frame)
}

# A sheet of cards, `ncol` per row, each under its name.
sheet <- function(options, ncol = 2) {
  grid.newpage()
  nrow <- ceiling(length(options) / ncol)
  pushViewport(viewport(layout = grid.layout(nrow, ncol)))
  for (i in seq_along(options)) {
    o <- options[[i]]
    pushViewport(viewport(layout.pos.row = (i - 1) %/% ncol + 1, layout.pos.col = (i - 1) %% ncol + 1))
    pushViewport(viewport(x = .5, y = .5, width = unit(1, "npc") - unit(10, "pt"), height = unit(1, "npc") - unit(8, "pt")))
    vp_w <- convertWidth(unit(1, "npc"), "pt", valueOnly = TRUE)
    vp_h <- convertHeight(unit(1, "npc"), "pt", valueOnly = TRUE)
    dot(3, 5, 2.2, if (isTRUE(o$default)) INK else P)
    txt(o$name, 9, 5, F_MONO, 5.4, INK)
    pushViewport(viewport(x = 0, y = 0, width = unit(vp_w, "pt"), height = unit(vp_h - 13, "pt"), just = c("left", "bottom")))
    do.call(card, c(list(W = vp_w, H = vp_h - 13), o$args))
    popViewport(3)
  }
  popViewport()
}

# One card filling the figure: a combination, drawn at the size of a
# half-width card and shown at full width, so it reads as a real chart.
one <- function(...) {
  grid.newpage()
  card(convertWidth(unit(1, "npc"), "pt", valueOnly = TRUE),
       convertHeight(unit(1, "npc"), "pt", valueOnly = TRUE), ...)
}
