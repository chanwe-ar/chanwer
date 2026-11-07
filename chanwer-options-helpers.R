# Helpers for chanwer-options.qmd: the option sheets for charts. Each sheet
# draws four cards (A is the current design) that differ in one part only.
# Prototype code for choosing a direction, not package API.

library(grid)
library(ggplot2)

cw <- chanwe_get_colors()
sg <- chanwe_get_signed()
P <- cw[["primary"]]; INK <- cw[["ink"]]; MU <- cw[["fg-muted"]]; SU <- cw[["fg-subtle"]]
RULE <- cw[["rule"]]; COOL <- cw[["rule-cool"]]; TINT <- "#EBF0F6"; WHITE <- "#FFFFFF"
PAPER <- "#F8FAFC"; GREEN <- sg[["positive"]]; RED <- sg[["negative"]]
F_DISP <- "Schibsted Grotesk SemiBold"; F_MONO <- "JetBrains Mono"; F_SANS <- "Satoshi"
F_SANSM <- "Satoshi Medium"; F_SERIF <- "Instrument Serif"; F_ITAL <- "Cormorant Garamond"

# ── data: monthly reserves, two series ──────────────────────────────────────
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
SERIES <- c(Brutas = P, Netas = MU)
last <- res[res$date == max(res$date), ]

# ── grid primitives (y measured from the top of the current viewport) ──────
X <- function(x) if (inherits(x, "unit")) x else if (x < 0) unit(1, "npc") - unit(-x, "pt") else unit(x, "pt")
Y <- function(y) unit(1, "npc") - unit(y, "pt")
gp_t <- function(fam, size, col) gpar(fontfamily = fam, fontsize = size, col = col)
txt <- function(lbl, x, y, fam, size, col, just = c("left", "center")) {
  grid.text(lbl, x = X(x), y = Y(y), just = just, gp = gp_t(fam, size, col))
}
tw <- function(lbl, fam, size) convertWidth(grobWidth(textGrob(lbl, gp = gp_t(fam, size, "black"))), "pt", valueOnly = TRUE)
rr <- function(x, y, w, h, fill, col = NA, r = h / 2, lwd = .5, just = c("left", "top")) {
  grid.roundrect(x = X(x), y = Y(y), width = unit(w, "pt"), height = unit(h, "pt"), just = just,
                 r = unit(r, "pt"), gp = gpar(fill = fill, col = col, lwd = lwd))
}
hline <- function(x0, x1, y, col = RULE, lwd = .5) {
  grid.lines(x = unit.c(X(x0), X(x1)), y = unit.c(Y(y), Y(y)), gp = gpar(col = col, lwd = lwd))
}
dot <- function(x, y, r, col) grid.circle(x = X(x), y = Y(y), r = unit(r, "pt"), gp = gpar(fill = col, col = NA))
mono <- function(lbl, x, y, size = 4.8, col = MU, just = c("left", "center")) txt(toupper(lbl), x, y, F_MONO, size, col, just)
# A pill sized to its text, from its left edge; returns its width in pt.
pill <- function(lbl, x, y, fill, col, size = 4.6, fam = F_MONO, stroke = NA, pad = 5, h = 10) {
  w <- tw(toupper(lbl), fam, size) + 2 * pad
  rr(x, y - h / 2, w, h, fill, stroke, lwd = .5)
  txt(toupper(lbl), x + pad, y, fam, size, col)
  w
}

TITLE <- "Reservas internacionales"
SUBTITLE <- "Brutas y netas, en USD mil millones."
EYEBROW <- "BCRA · Sector externo"
STAMP <- "CHW · RM-07 · 2026"

# ── headers: each draws from the top and returns its height ─────────────────
hdr_band <- function(W, pad, two_col = FALSE) {
  rr(pad, pad, W - 2 * pad, 13, INK)
  dot(pad + 8, pad + 6.5, 1.6, P)
  mono(EYEBROW, pad + 14, pad + 6.5, 4.6, COOL)
  mono(STAMP, -(pad + 8), pad + 6.5, 4.2, SU, c("right", "center"))
  if (two_col) {
    # Two columns: the title wraps beside the KPI pane.
    txt("Reservas", pad, pad + 27, F_DISP, 11, INK)
    txt("internacionales", pad, pad + 40, F_DISP, 11, INK)
    txt("Brutas y netas, en USD mil millones.", pad, pad + 53, F_SANS, 6, MU)
    return(pad + 64)
  }
  txt(TITLE, pad, pad + 27, F_DISP, 11, INK)
  txt(SUBTITLE, pad, pad + 38, F_SANS, 6, MU)
  pad + 44
}
hdr_rule <- function(W, pad) {
  hline(pad, pad + 12, pad + 5, P, 1)
  mono(EYEBROW, pad + 16, pad + 5, 4.6, P)
  mono(STAMP, -pad, pad + 5, 4.2, SU, c("right", "center"))
  txt(TITLE, pad, pad + 18, F_DISP, 11, INK)
  txt(SUBTITLE, pad, pad + 29, F_SANS, 6, MU)
  pad + 35
}
hdr_numeral <- function(W, pad) {
  txt("07", pad - 1, pad + 15, F_SERIF, 30, P)
  x <- pad + 34
  dot(x + 1.5, pad + 5, 1.5, P)
  mono(EYEBROW, x + 6, pad + 5, 4.6, INK)
  txt(TITLE, x, pad + 18, F_DISP, 11, INK)
  txt(SUBTITLE, x, pad + 29, F_SANS, 6, MU)
  mono(STAMP, -pad, pad + 5, 4.2, SU, c("right", "center"))
  pad + 35
}
hdr_split <- function(W, pad) {
  txt(TITLE, pad, pad + 8, F_DISP, 11, INK)
  txt(SUBTITLE, pad, pad + 19, F_SANS, 6, MU)
  xr <- W - pad
  grid.lines(x = unit.c(X(-(pad + 74)), X(-(pad + 74))), y = unit.c(Y(pad + 1), Y(pad + 22)), gp = gpar(col = RULE, lwd = .5))
  dot(W - pad - 66, pad + 5, 1.5, P)
  mono(EYEBROW, -(pad), pad + 5, 4.4, INK, c("right", "center"))
  mono(STAMP, -(pad), pad + 15, 4.2, SU, c("right", "center"))
  pad + 28
}

# ── KPI blocks ───────────────────────────────────────────────────────────────
KPI <- list(value = "39,5", unit = "USD MM · Dic 2025",
            d = list(c("MoM", "↑ 2,1 %", "up"), c("QoQ", "↓ 0,4 %", "down"), c("YoY", "↑ 17,8 %", "up")))
kpi_pills <- function(x, y, size = 4.2, gap = 3) {
  for (m in KPI$d) {
    col <- if (m[3] == "up") GREEN else RED
    fill <- grDevices::adjustcolor(col, alpha.f = .12)
    w <- pill(paste(m[1], m[2]), x, y, fill, col, size = size, pad = 4, h = 9)
    x <- x + w + gap
  }
  x
}
kpi_pane <- function(W, top, h) {   # right column, from the title row down
  w <- 118
  x0 <- W - 11 - w
  rr(x0, top, w, h, TINT, r = 8)
  mono(KPI$unit, x0 + 8, top + 8, 4, MU)
  txt(KPI$value, x0 + 8, top + 21, F_DISP, 14, INK)
  kpi_pills(x0 + 8, top + h - 9, 3.9, 2.5)
}
kpi_strip <- function(W, pad, y) {
  txt(KPI$value, pad, y + 7, F_DISP, 15, INK)
  x <- pad + tw(KPI$value, F_DISP, 15) + 5
  mono(KPI$unit, x, y + 9, 4, MU)
  x <- x + tw(toupper(KPI$unit), F_MONO, 4) + 8
  kpi_pills(x, y + 8)
  y + 18
}
kpi_rail <- function(x, y, h) {  # left column of the body
  txt(KPI$value, x, y + 12, F_DISP, 17, INK)
  mono(KPI$unit, x, y + 25, 3.9, MU)
  yy <- y + 38
  for (m in KPI$d) {
    col <- if (m[3] == "up") GREEN else RED
    pill(paste(m[1], m[2]), x, yy, grDevices::adjustcolor(col, alpha.f = .12), col, size = 4, pad = 4, h = 9)
    yy <- yy + 12
  }
  grid.lines(x = unit.c(X(x + 58), X(x + 58)), y = unit.c(Y(y + 2), Y(y + h - 2)), gp = gpar(col = RULE, lwd = .5))
}

# ── the plot body ────────────────────────────────────────────────────────────
body_plot <- function(style = "grid", legend = "pill", kpi = "none") {
  lims <- c(22, 42)
  p <- ggplot(res, aes(date, value, colour = serie))
  if (style == "bands") {
    bands <- data.frame(ymin = c(22, 30, 40), ymax = c(25, 35, 42))
    p <- p + geom_rect(data = bands, aes(xmin = -Inf, xmax = Inf, ymin = ymin, ymax = ymax),
                       inherit.aes = FALSE, fill = TINT, colour = NA)
  }
  if (style == "terminal") {
    fld <- expand.grid(date = seq(min(res$date), max(res$date), by = "month"), value = seq(22, 42, by = 1.25))
    p <- p + geom_point(data = fld, aes(date, value), inherit.aes = FALSE, colour = SU, alpha = .45, size = .12)
  }
  if (style == "annot") {
    p <- p +
      annotate("rect", xmin = as.Date("2024-09-01"), xmax = as.Date("2025-03-01"), ymin = -Inf, ymax = Inf, fill = TINT) +
      annotate("text", x = as.Date("2024-09-15"), y = 41.2, label = "ACUERDO FMI", hjust = 0, family = F_MONO, size = 1.4, colour = MU) +
      geom_hline(yintercept = 38, colour = INK, linewidth = .2, linetype = "22") +
      annotate("text", x = min(res$date), y = 38.9, label = "META · 38,0", hjust = 0, family = F_MONO, size = 1.4, colour = INK)
  }
  if (style == "minmax") {
    p <- p + geom_hline(yintercept = 22, colour = INK, linewidth = .3)
  }
  p <- p + geom_line(linewidth = if (style == "minmax") .5 else .45, lineend = "round")
  if (style == "terminal") p <- p + geom_point(size = .35)
  if (style == "annot") {
    p <- p + geom_area(data = res[res$serie == "Brutas", ], aes(date, value), inherit.aes = FALSE, fill = P, alpha = .06)
  }
  if (legend == "direct" || style == "minmax") {
    p <- p + geom_text(data = last, aes(label = paste0(toupper(serie), "  ", format(round(value, 1), decimal.mark = ","))),
                       hjust = 0, nudge_x = 12, family = F_MONO, size = 1.45, show.legend = FALSE)
  }
  if (kpi == "end" || style == "annot") {
    b <- last[last$serie == "Brutas", ]
    p <- p + geom_point(data = b, size = 2.6, alpha = .18) + geom_point(data = b, size = 1)
    if (kpi == "end") {
      p <- p + annotate("label", x = b$date - 40, y = b$value - 4.5,
                        label = "39,5   MoM ↑ 2,1 %   YoY ↑ 17,8 %", family = F_MONO, size = 1.5,
                        fill = INK, colour = "white", label.r = unit(5, "pt"),
                        label.padding = unit(3.2, "pt"), hjust = 1)
    }
  }
  right_exp <- if (legend == "direct" || style == "minmax") .2 else .02
  brk <- if (style == "minmax") c(22, 42) else c(25, 30, 35, 40)
  p <- p +
    scale_colour_manual(values = SERIES) +
    scale_x_date(date_labels = "%b %y", date_breaks = "6 months", expand = expansion(mult = c(.01, right_exp))) +
    scale_y_continuous(limits = lims, breaks = brk, expand = expansion(0)) +
    labs(x = NULL, y = NULL) +
    theme_chanwe(base_text_size = 6, pane = FALSE, legend_position = "none",
                 grid = if (style %in% c("bands", "minmax")) "none" else "y") +
    theme(plot.margin = margin(2, 2, 0, 0), plot.background = element_rect(fill = NA, colour = NA),
          panel.background = element_rect(fill = NA, colour = NA),
          axis.text = element_text(size = 4.4))
  if (style == "terminal") {
    p <- p + theme(panel.grid.major.y = element_line(colour = COOL, linewidth = .2, linetype = "22"),
                   axis.line.x = element_line(colour = COOL, linewidth = .25),
                   axis.ticks.x = element_line(colour = P, linewidth = .3),
                   axis.ticks.length.x = unit(2.4, "pt"))
  }
  if (style == "minmax") {
    p <- p + theme(panel.grid.major.y = element_line(colour = COOL, linewidth = .2))
  }
  p
}

# ── legends and footers ──────────────────────────────────────────────────────
legend_pill <- function(W, y) {
  labs_ <- c("BRUTAS", "NETAS")
  ws <- vapply(labs_, function(l) tw(l, F_MONO, 4.4), numeric(1))
  total <- sum(ws) + 2 * 8 + 10 + 14
  x0 <- (W - total) / 2
  rr(x0, y - 6, total, 12, NA, RULE)
  x <- x0 + 7
  for (i in seq_along(labs_)) {
    dot(x + 2, y, 2, SERIES[[i]]); txt(labs_[i], x + 6, y, F_MONO, 4.4, MU); x <- x + ws[i] + 14
  }
}
legend_header <- function(W, pad, y) {
  x <- W - pad
  for (i in rev(seq_along(SERIES))) {
    l <- toupper(names(SERIES)[i]); w <- tw(l, F_MONO, 4.4)
    txt(l, x - w, y, F_MONO, 4.4, MU); dot(x - w - 4, y, 2, SERIES[[i]]); x <- x - w - 14
  }
}
legend_inset <- function(x, y) {
  for (i in seq_along(SERIES)) {
    dot(x + 2, y, 2, SERIES[[i]]); txt(toupper(names(SERIES)[i]), x + 6, y, F_MONO, 4.4, INK)
    x <- x + tw(toupper(names(SERIES)[i]), F_MONO, 4.4) + 16
  }
}
FOOT_H <- c(rule = 22, tint = 22, notes = 30, mark = 18)
footer <- function(kind, W, H, pad) {
  y0 <- H - FOOT_H[[kind]]
  src <- function(y) { mono("Fuente", pad, y, 4.2, SU); mono("BCRA · elaboración propia", pad + 22, y, 4.2, MU) }
  if (kind == "rule") {
    hline(pad, -pad, y0 + 2, RULE)
    src(y0 + 12)
    w <- tw(STAMP, F_MONO, 3.9) + 10
    rr(W - pad - w, y0 + 7, w, 10, WHITE); txt(STAMP, W - pad - w + 5, y0 + 12, F_MONO, 3.9, MU)
  } else if (kind == "tint") {
    rr(0.25, y0, W - .5, FOOT_H[[kind]] - .25, TINT, r = 9)
    grid.rect(x = X(0.25), y = Y(y0), width = unit(W - .5, "pt"), height = unit(9, "pt"), just = c("left", "top"), gp = gpar(fill = TINT, col = NA))
    hline(0.25, -0.25, y0, RULE)
    src(y0 + 11)
    mono(STAMP, -pad, y0 + 11, 3.9, MU, c("right", "center"))
  } else if (kind == "notes") {
    hline(pad, -pad, y0 + 2, RULE)
    src(y0 + 10)
    mono(STAMP, -pad, y0 + 10, 3.9, SU, c("right", "center"))
    txt("Nota: las reservas netas descuentan swaps, encajes y obligaciones de corto plazo.", pad, y0 + 20, F_ITAL, 6, MU)
  } else if (kind == "mark") {
    src(y0 + 9)
    w <- tw("chanwe", F_SANSM, 8)
    txt("chanwe", -(pad + 4), y0 + 9, F_SANSM, 8, INK, c("right", "center"))
    dot(W - pad - 1.5, y0 + 10.5, 1.3, P)
  }
}

# ── a card: the whole chart ─────────────────────────────────────────────────
card <- function(W, H, header = "band", kpi = "none", body = "grid", legend = "pill", foot = "rule") {
  pad <- 11
  rr(0.25, 0.25, W - .5, H - .5, PAPER, RULE, r = 9)
  hdr_fun <- switch(header, band = hdr_band, rule = hdr_rule, numeral = hdr_numeral, split = hdr_split)
  y <- if (header == "band") hdr_fun(W, pad, two_col = kpi == "pane") else hdr_fun(W, pad)
  if (legend == "header") legend_header(W, pad, y - 9)
  if (kpi == "pane") kpi_pane(W, pad + 19, 45)
  if (kpi == "strip") y <- kpi_strip(W, pad, y + 2)
  y <- y + 6
  bottom <- H - FOOT_H[[foot]] - (if (legend == "pill") 18 else 2)
  x0 <- pad
  if (kpi == "rail") { kpi_rail(pad, y, bottom - y); x0 <- pad + 64 }
  pushViewport(viewport(x = unit(x0, "pt"), y = Y(y), width = unit(W - x0 - pad, "pt"), height = unit(bottom - y, "pt"), just = c("left", "top")))
  grid.draw(ggplotGrob(body_plot(body, legend, kpi)))
  popViewport()
  if (legend == "inset") legend_inset(x0 + 22, y + 6)
  if (legend == "pill") legend_pill(W, bottom + 8)
  footer(foot, W, H, pad)
}

# A sheet: four cards, two by two, each under its letter and name.
sheet <- function(options) {
  grid.newpage()
  lay <- grid.layout(2, 2, widths = unit(c(1, 1), "null"), heights = unit(c(1, 1), "null"))
  pushViewport(viewport(layout = lay))
  for (i in seq_along(options)) {
    o <- options[[i]]
    pushViewport(viewport(layout.pos.row = (i - 1) %/% 2 + 1, layout.pos.col = (i - 1) %% 2 + 1))
    pushViewport(viewport(x = .5, y = .5, width = unit(1, "npc") - unit(10, "pt"), height = unit(1, "npc") - unit(8, "pt")))
    vp_w <- convertWidth(unit(1, "npc"), "pt", valueOnly = TRUE)
    vp_h <- convertHeight(unit(1, "npc"), "pt", valueOnly = TRUE)
    dot(3, 5, 2.2, if (i == 1) INK else P)
    txt(paste0(LETTERS[i], " · ", o$name), 9, 5, F_MONO, 5.4, INK)
    pushViewport(viewport(x = 0, y = 0, width = unit(vp_w, "pt"), height = unit(vp_h - 13, "pt"), just = c("left", "bottom")))
    do.call(card, c(list(W = vp_w, H = vp_h - 13), o$args))
    popViewport(3)
  }
  popViewport()
}
