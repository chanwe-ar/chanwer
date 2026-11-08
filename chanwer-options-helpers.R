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
                     value = c(355, 228, round(last$value[last$serie == "Brutas"], 1), 46, 59, 74))
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

# Copy per chart type (round 5: each chart says what it measures, in what
# unit and over what period). The eyebrow names the topic, not the source: the
# source is in the footer. The header carries the period; the ID lives only in
# the footer.
COPY <- list(
  line    = list(title = "Reservas internacionales", subtitle = "Brutas y netas, USD miles de millones, ene-24 a dic-25",
                 eyebrow = "Sector externo · Reservas"),
  bar     = list(title = "Reservas por país", subtitle = "Reservas brutas, USD miles de millones, dic-25",
                 eyebrow = "Sector externo · Región"),
  column  = list(title = "Acumulación mensual", subtitle = "Variación de reservas brutas, USD miles de millones, 2025",
                 eyebrow = "Sector externo · Flujos"),
  scatter = list(title = "Reservas e inflación", subtitle = "Reservas brutas (USD miles de millones, escala log) e inflación mensual (%), dic-25",
                 eyebrow = "Sector externo · Región")
)
set_copy <- function(type) {
  TITLE <<- COPY[[type]]$title; SUBTITLE <<- COPY[[type]]$subtitle; EYEBROW <<- COPY[[type]]$eyebrow
}
set_copy("line")
PERIOD <- "Dic 2025"
STAMP <- "CHW · RM-07 · 2026"
MESES <- c("ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic")
fmt_mes <- function(x, year = TRUE) {
  m <- MESES[as.integer(format(x, "%m"))]
  if (year) paste0(m, "-", format(x, "%y")) else m
}

# ── dimensions: regular (round 2) and compact (round 3, the default). The
# compact header and footer keep every element and lose height: smaller type
# steps, tighter insets, a slimmer band and stamp.
DIMS <- list(
  regular = list(ip = 8, title = 11.5, gap = 1.5, sub = 6.6, sub_off = 11, sub_line = 8,
                 band_h = 11, band_y = 5, eye = 4.3, stamp = 4, numeral = 30,
                 h = c(A = 46, C = 42, D = 38, Dleg = 60, dark = 44),
                 ty = c(A = 27, C = 15, D = 6, dark = 16), wrap_t = 13, wrap_s = 8, kpi_top = 20,
                 foot_h = 15, foot_txt = 4, pill_h = 8, pill_txt = 3.7),
  # Compact type, but the tinted card keeps its air: 7.5pt inside, the band
  # 5.5pt from the card's edge, as much room under the subtitle as over the band.
  compact = list(ip = 7.5, title = 10, gap = 1.2, sub = 6, sub_off = 9, sub_line = 7,
                 band_h = 8.5, band_y = 5.5, eye = 3.9, stamp = 3.6, numeral = 24,
                 h = c(A = 40.5, C = 34, D = 30, Dleg = 49, dark = 35),
                 ty = c(A = 24, C = 11.5, D = 4.5, dark = 12), wrap_t = 11.2, wrap_s = 7, kpi_top = 17.5,
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

# ── header cards: one layout for every combination (round 4).
# A card has an optional band on top (A), then two columns: the left one holds
# the eyebrow (C, dark), the title and the subtitle, with the numeral before it
# (C); the right one holds, stacked from the top on one left edge, the meta
# (D: eyebrow and stamp; C and dark: the stamp), the legend and the KPI pane.
# A hairline divides the columns over the content's full height; the card is as
# tall as its taller column. Text wraps by measured width, at word boundaries.
wrap_lines <- function(text, fam, size, width) {
  words <- strsplit(text, " ")[[1]]
  lines <- character(0); cur <- ""
  for (w in words) {
    cand <- if (nzchar(cur)) paste(cur, w) else w
    if (nzchar(cur) && tw(cand, fam, size) > width) { lines <- c(lines, cur); cur <- w } else cur <- cand
  }
  c(lines, cur)
}
eyebrow_line <- function(x, y, col, label_col) {
  dot(x + 1.3, y, 1.3, P); mono(EYEBROW, x + 5.5, y, d$eye, label_col)
}
eyebrow_w <- function() tw(toupper(EYEBROW), F_MONO, d$eye) + 5.5
# The pane is as wide as its pills; three rows (unit, value, pills) with air
# between them. On a header with no fill it takes the tint, so it keeps an edge.
kpi_pills_w <- function() {
  sum(vapply(KPI$d, function(m) tw(toupper(paste(m[1], m[2])), F_MONO, 3.9) + 7.2, numeric(1))) + 2.5 * (length(KPI$d) - 1)
}
kpi_pane_w <- function() kpi_pills_w() + 14
kpi_pane_h <- function() 43
kpi_pane_at <- function(x0, top, h = kpi_pane_h(), fill = PAPER) {
  rr(x0, top, kpi_pane_w(), h, fill, r = 6)
  mono(KPI$unit, x0 + 7, top + 8.5, 3.7, MU)
  txt(KPI$value, x0 + 7, top + 20.5, F_DISP, 13, INK)
  kpi_pills(x0 + 7, top + h - 9)
}
# The pane as one row, when the right column has no room for it.
kpi_row_at <- function(x0, top, w, fill = PAPER) {
  h <- 18
  rr(x0, top, w, h, fill, r = 6)
  txt(KPI$value, x0 + 7, top + h / 2, F_DISP, 11.5, INK)
  x <- x0 + 7 + tw(KPI$value, F_DISP, 11.5) + 5
  mono(KPI$unit, x, top + h / 2 + .5, 3.7, MU)
  kpi_pills(x0 + w - 7 - kpi_pills_w(), top + h / 2)
  h
}
hdr_card <- function(kind, W, pad, legend = FALSE, kpi = FALSE, fill = "tint") {
  dark <- kind == "dark"
  bare <- !dark && fill == "none"
  x0 <- pad; w <- W - 2 * pad
  ip <- if (bare) 0 else d$ip
  tcol <- if (dark) COOL else INK; scol <- if (dark) SU else MU
  line_t <- d$title * 1.14; line_s <- d$sub * 1.45; slot <- d$eye + 4.6

  # ── the right column: what it holds, how wide and how tall
  right <- list()
  if (kind == "D") right <- c(right, list(list(type = "eyebrow", h = slot, w = eyebrow_w())))
  # The pane goes in the right column when the title keeps at least its longest
  # word on a line beside it; otherwise it becomes a row under the title block.
  kpi_row <- FALSE
  if (kpi) {
    nw0 <- if (kind == "C") tw("07", F_SERIF, d$numeral) + 6 else 0
    room <- w - 2 * ip - kpi_pane_w() - 18 - nw0
    longest <- max(vapply(strsplit(TITLE, " ")[[1]], function(x) tw(x, F_DISP, d$title), numeric(1)))
    kpi_row <- room < max(longest + 6, 118)
  }
  # C and dark: the stamp opens the right column only when the column has
  # something else to hold; alone, it rides on the eyebrow's line.
  stamp_inline <- kind %in% c("C", "dark") && !legend && !(kpi && !kpi_row)
  if (kind == "D" || (kind %in% c("C", "dark") && !stamp_inline))
    right <- c(right, list(list(type = "stamp", h = slot, w = tw(toupper(PERIOD), F_MONO, d$stamp))))
  if (legend) {
    if (kind == "D") {   # D's column already holds two lines: the keys share one
      kw <- sum(vapply(names(SERIES), function(k) tw(toupper(k), F_MONO, d$eye) + 6, numeric(1))) + 9 * (length(SERIES) - 1)
      right <- c(right, list(list(type = "keys", h = slot + 0.6, w = kw)))
    } else for (k in names(SERIES)) right <- c(right, list(list(type = "key", key = k, h = slot + 0.6, w = tw(toupper(k), F_MONO, d$eye) + 6)))
  }
  pane_fill <- if (bare) TINT else PAPER
  if (kpi && !kpi_row) right <- c(right, list(list(type = "pane", h = kpi_pane_h(), w = kpi_pane_w())))
  gap_group <- 3.5
  right_w <- if (length(right)) max(vapply(right, `[[`, numeric(1), "w")) else 0
  right_h <- if (length(right)) sum(vapply(right, `[[`, numeric(1), "h")) + gap_group * (kind != "A" && (legend || kpi) && length(right) > 1) else 0
  col_gap <- if (length(right)) 18 else 0      # 9 each side of the hairline

  # ── the left column
  nw <- if (kind == "C") tw("07", F_SERIF, d$numeral) + 6 else 0
  left_w <- w - 2 * ip - right_w - col_gap - nw
  t_lines <- wrap_lines(TITLE, F_DISP, d$title, left_w)
  s_lines <- wrap_lines(SUBTITLE, F_SANS, d$sub, left_w)
  has_eye <- kind %in% c("C", "dark")
  left_h <- (if (has_eye) slot + 1.5 else 0) + length(t_lines) * line_t + 1.5 + length(s_lines) * line_s

  # ── the card
  band <- kind == "A"
  bo <- if (bare) 0 else d$band_y
  band_block <- if (band) bo + d$band_h + (if (bare) 7 else 6.5) else 0
  row_h <- if (kpi_row) 18 + 6 else 0
  content_h <- max(left_h, right_h) + row_h
  h <- band_block + (if (band) 0 else ip) + content_h + ip + (if (bare) 1 else 0)
  if (!bare) rr(x0, pad, w, h, if (dark) INK else TINT, r = 7)
  if (dark) for (xx in seq(x0 + 5, x0 + w - 3, by = 7)) for (yy in seq(pad + 4, pad + h - 3, by = 7))
    dot(xx, yy, .26, grDevices::adjustcolor("#64748B", alpha.f = .45))

  if (band) {
    by <- pad + bo; bw <- w - 2 * bo
    rr(x0 + bo, by, bw, d$band_h, INK)
    eyebrow_line(x0 + bo + 5.5, by + d$band_h / 2, P, COOL)
    mono(PERIOD, -(pad + bo + 6), by + d$band_h / 2, d$stamp, SU, c("right", "center"))
  }
  top <- pad + (if (band) band_block else ip)

  # left column
  lx <- x0 + ip + nw
  if (kind == "C") txt("07", x0 + ip - 1, top + left_h / 2 + 1, F_SERIF, d$numeral, P)
  y <- top
  if (has_eye) {
    eyebrow_line(lx, y + slot / 2, P, if (dark) P else INK)
    if (stamp_inline) mono(PERIOD, -(pad + ip), y + slot / 2, d$stamp, MU, c("right", "center"))
    y <- y + slot + 1.5
  }
  for (l in t_lines) { txt(l, lx, y + line_t / 2, F_DISP, d$title, tcol); y <- y + line_t }
  y <- y + 1.5
  for (l in s_lines) { txt(l, lx, y + line_s / 2, F_SANS, d$sub, scol); y <- y + line_s }

  # right column, on one left edge, from the top of the content
  if (length(right)) {
    rx <- x0 + w - ip - right_w
    vline(rx - col_gap / 2, top + 1, top + content_h - row_h - 1, if (dark) "#434D5D" else COOL)
    y <- top
    prev <- NULL
    for (it in right) {
      if (!is.null(prev) && prev %in% c("eyebrow", "stamp") && it$type %in% c("key", "keys", "pane")) y <- y + gap_group
      if (it$type == "eyebrow") eyebrow_line(rx, y + it$h / 2, P, INK)
      if (it$type == "stamp") mono(PERIOD, rx, y + it$h / 2, d$stamp, MU)
      if (it$type == "key") {
        dot(rx + 1.6, y + it$h / 2, 1.6, SERIES[[it$key]])
        txt(toupper(it$key), rx + 6, y + it$h / 2, F_MONO, d$eye, if (dark) COOL else MU)
      }
      if (it$type == "keys") {
        kx <- rx
        for (k in names(SERIES)) {
          dot(kx + 1.6, y + it$h / 2, 1.6, SERIES[[k]])
          txt(toupper(k), kx + 6, y + it$h / 2, F_MONO, d$eye, if (dark) COOL else MU)
          kx <- kx + tw(toupper(k), F_MONO, d$eye) + 15
        }
      }
      if (it$type == "pane") kpi_pane_at(rx, y, it$h, fill = pane_fill)
      y <- y + it$h
      prev <- it$type
    }
  }
  if (kpi_row) kpi_row_at(x0 + ip, top + content_h - 18, w - 2 * ip, fill = pane_fill)
  pad + h
}

# ── KPI: A pane inside the header card, B strip, C rail ─────────────────────
# The KPI is computed from the series it sits on, so the pane and the end of
# the line always say the same number.
kpi_from <- function() {
  b <- res[res$serie == "Brutas", ]; v <- b$value; n <- length(v)
  # A change that rounds to zero is neither up nor down: it reads in slate.
  chg <- function(k) { x <- round((v[n] / v[n - k] - 1) * 100, 1)
    dir <- if (x > 0) "up" else if (x < 0) "down" else "flat"
    c(paste0(c(up = "↑ ", down = "↓ ", flat = "= ")[[dir]], formatC(abs(x), format = "f", digits = 1, decimal.mark = ","), " %"), dir) }
  list(value = format(round(v[n], 1), decimal.mark = ","), unit = "USD miles de M · dic-25",
       d = list(c("m/m", chg(1)), c("t/t", chg(3)), c("a/a", chg(12))))
}
KPI <- kpi_from()
kpi_pills <- function(x, y, stack = FALSE) {
  for (m in KPI$d) {
    col <- switch(m[3], up = GREEN, down = RED, SLATE[1])
    w <- pill(paste(m[1], m[2]), x, y, grDevices::adjustcolor(col, alpha.f = .12), col)
    if (stack) y <- y + 11 else x <- x + w + 2.5
  }
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
footer <- function(kind, W, H, pad, frame, radius = 9) {
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
    rr(0.5, y0, W - 1, fh - .5, TINT, r = radius)
    grid.rect(x = X(0.5), y = Y(y0), width = unit(W - 1, "pt"), height = unit(fh / 2, "pt"),
              just = c("left", "top"), gp = gpar(fill = TINT, col = NA))
    src(yc)
    mono(STAMP, -pad, yc, d$pill_txt, MU, c("right", "center"))
  }
}

# ── the body (round 5, polished). A: horizontal grid every 5, the main series
# with its end halo and value chip. B: the same grid, every series named at its
# end; no ink base on an axis that does not start at zero. Months in Spanish.
ink_label <- function(...) {
  geom_label(..., family = F_MONO, size = 1.5, fill = INK, colour = "white",
             label.r = unit(4, "pt"), label.padding = unit(2.3, "pt"))
}
base_theme <- function(grid = "y") {
  theme_chanwe(base_text_size = 6, pane = FALSE, legend_position = "none", grid = grid) +
    theme(plot.margin = margin(4, 2, 0, 0), plot.background = element_rect(fill = NA, colour = NA),
          panel.background = element_rect(fill = NA, colour = NA), axis.text = element_text(size = 4.3),
          axis.text.x = element_text(margin = margin(t = 3)))
}
num <- function(v) formatC(v, format = "f", digits = 1, decimal.mark = ",")
date_scale <- function(right = .17) {
  scale_x_date(labels = fmt_mes, breaks = seq(as.Date("2024-06-01"), as.Date("2025-12-01"), by = "6 months"),
               expand = expansion(mult = c(.01, right)))
}
y_scale <- function() scale_y_continuous(limits = c(24, 41), breaks = seq(25, 40, 5), expand = expansion(0))
body_plot <- function(body = "A", type = "line", style = "polished") {
  if (style == "editorial") return(body_editorial(type))
  if (type == "line") {
    p <- ggplot(res, aes(date, value, colour = serie)) + geom_line(linewidth = .45, lineend = "round")
    if (body == "A") {
      b <- last[last$serie == "Brutas", ]; o <- last[last$serie != "Brutas", ]
      p <- p + geom_point(data = b, size = 3.2, alpha = .18) + geom_point(data = b, size = 1.1) +
        ink_label(data = b, aes(label = num(value)), hjust = -0.22) +
        geom_point(data = o, size = .8) +
        geom_text(data = o, aes(label = num(value)), hjust = -.5, family = F_MONO, size = 1.4)
    } else {
      p <- p + geom_point(data = last, size = .8) +
        geom_text(data = last, aes(label = paste0(toupper(serie), "  ", num(value))),
                  hjust = 0, nudge_x = 14, family = F_MONO, size = 1.45)
    }
    return(p + scale_colour_manual(values = SERIES) + date_scale(if (body == "B") .27 else .17) + y_scale() +
      labs(x = NULL, y = NULL) + base_theme("y"))
  }
  if (type == "bar") {   # a ranking: every bar labelled, so no value axis and no grid
    dd <- region; dd$main <- dd$name == "Argentina"
    dd$name <- stats::reorder(dd$name, dd$value)
    off <- max(dd$value) * .025
    return(ggplot(dd, aes(value, name, fill = main)) +
      geom_chanwe_col(width = .64, orientation = "y", radius = 1.2) +
      geom_text(data = dd[!dd$main, ], aes(x = value + off, label = num(value)), hjust = 0, family = F_MONO, size = 1.4, colour = SLATE[1]) +
      ink_label(data = dd[dd$main, ], aes(x = value + off, label = num(value)), hjust = 0) +
      scale_fill_manual(values = c(`TRUE` = P, `FALSE` = SLATE[3]), guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0, .14))) + labs(x = NULL, y = NULL) +
      base_theme("none") + theme(axis.text.x = element_blank(),
                                 axis.text.y = element_text(size = 4.6, colour = INK, hjust = 1)))
  }
  if (type == "column") {  # columns over time: the last month is the main one; a real zero line
    dd <- monthly; dd$main <- dd$date == max(dd$date)
    return(ggplot(dd, aes(date, value, fill = main)) +
      geom_hline(yintercept = 0, colour = INK, linewidth = .3) +
      geom_chanwe_col(width = 20, radius = 1.2) +
      ink_label(data = dd[dd$main, ], aes(label = num(value)), vjust = -.4) +
      scale_fill_manual(values = c(`TRUE` = P, `FALSE` = SLATE[3]), guide = "none") +
      scale_x_date(labels = function(x) fmt_mes(x, FALSE), breaks = seq(as.Date("2025-01-01"), by = "2 months", length.out = 6)) +
      scale_y_continuous(expand = expansion(mult = c(0, .24))) + labs(x = NULL, y = NULL) + base_theme("y"))
  }
  if (type == "scatter") {  # axes named; the main point labelled in open space, with a leader
    dd <- scat; dd$main <- dd$name == "Arg"
    m <- dd[dd$main, ]
    return(ggplot(dd, aes(x, y)) +
      geom_point(data = dd[!dd$main, ], colour = SLATE[2], size = 1.4) +
      geom_text(data = dd[!dd$main, ], aes(label = toupper(name)), family = F_MONO, size = 1.3, colour = SLATE[1], vjust = -1.2) +
      geom_point(data = m, colour = P, size = 3.6, alpha = .18) + geom_point(data = m, colour = P, size = 1.5) +
      annotate("segment", x = m$x * 1.12, xend = m$x * 2.1, y = m$y - .12, yend = m$y - .55, colour = INK, linewidth = .2) +
      annotate("text", x = m$x * 2.2, y = m$y - .6, label = "ARGENTINA  4,8 %", hjust = 0, family = F_MONO, size = 1.5, colour = P) +
      annotate("text", x = 2.4, y = 6.55, label = "INFLACIÓN MENSUAL, %", hjust = 0, family = F_MONO, size = 1.25, colour = MU) +
      scale_x_log10(expand = expansion(mult = c(.05, .08))) +
      scale_y_continuous(limits = c(2, 6.6), expand = expansion(0)) +
      labs(x = "RESERVAS, USD MILES DE M (ESCALA LOG)", y = NULL) + base_theme("y") +
      theme(axis.title.x = element_text(size = 3.9, colour = MU, hjust = 0.5, margin = margin(t = 4))))
  }
}

# ── the editorial body (the independent review's direction): direct labels, no
# legend, the gap between the series encoded, one annotation with a leader in
# the editorial italic, and for a ranking the regional median.
body_editorial <- function(type) {
  if (type == "line") {
    w <- data.frame(date = res$date[res$serie == "Brutas"], b = res$value[res$serie == "Brutas"],
                    n = res$value[res$serie == "Netas"])
    gap <- w$b[nrow(w)] - w$n[nrow(w)]
    mid <- w[16, ]
    ev <- w[w$date == as.Date("2025-04-01"), ]
    return(ggplot() +
      geom_ribbon(data = w, aes(date, ymin = n, ymax = b), fill = TINT) +
      annotate("text", x = mid$date, y = (mid$b + mid$n) / 2, label = paste0("BRECHA ", num(gap)),
               family = F_MONO, size = 1.3, colour = MU) +
      geom_line(data = res, aes(date, value, colour = serie), linewidth = .5, lineend = "round") +
      annotate("segment", x = ev$date, xend = ev$date - 70, y = ev$b + .3, yend = ev$b + 3.2, colour = INK, linewidth = .2) +
      annotate("point", x = ev$date, y = ev$b, size = .9, colour = INK) +
      annotate("text", x = ev$date - 74, y = ev$b + 3.5, label = "Acuerdo FMI, abr-25", hjust = 1,
               family = F_ITAL, fontface = "italic", size = 2.3, colour = MU) +
      geom_point(data = last, aes(date, value, colour = serie), size = 1.2) +
      geom_text(data = last, aes(date, value, colour = serie, label = paste0(toupper(serie), "  ", num(value))),
                hjust = 0, nudge_x = 16, family = F_MONO, size = 1.5) +
      scale_colour_manual(values = SERIES) + date_scale(.27) + y_scale() + labs(x = NULL, y = NULL) + base_theme("y"))
  }
  if (type == "bar") {
    dd <- region; dd$main <- dd$name == "Argentina"
    dd$name <- stats::reorder(dd$name, dd$value)
    med <- stats::median(dd$value); off <- max(dd$value) * .025
    return(ggplot(dd, aes(value, name, fill = main)) +
      geom_vline(xintercept = med, colour = COOL, linewidth = .25, linetype = "22") +
      geom_chanwe_col(width = .64, orientation = "y", radius = 1.2) +
      annotate("segment", x = med, xend = med, y = 6.42, yend = 6.82, colour = P, linewidth = .6) +
      annotate("text", x = med + off * .6, y = 6.66, label = paste0("MEDIANA ", num(med)), hjust = 0, family = F_MONO, size = 1.3, colour = P) +
      geom_text(aes(x = value + off, label = num(value), colour = main), hjust = 0, family = F_MONO, size = 1.45) +
      scale_fill_manual(values = c(`TRUE` = P, `FALSE` = SLATE[3]), guide = "none") +
      scale_colour_manual(values = c(`TRUE` = P, `FALSE` = SLATE[1]), guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0, .12))) + scale_y_discrete(expand = expansion(add = c(.6, 1))) +
      labs(x = NULL, y = NULL) + base_theme("none") +
      theme(axis.text.x = element_blank(), axis.text.y = element_text(size = 4.6, colour = INK, hjust = 1)))
  }
  body_plot("A", type)
}

# ── a chart card ─────────────────────────────────────────────────────────────
card <- function(W, H, header = "A", kpi = "none", body = "A", type = "line", legend = "A", foot = "A", frame = "simple",
                 compact = TRUE, hfill = "tint", style = "polished") {
  set_copy(type)
  if (style == "editorial") return(card_editorial(W, H, type, kpi = kpi != "none"))
  d <<- if (compact) DIMS$compact else DIMS$regular
  pad <- if (compact) 8 else 10
  radius <- 9
  if (frame == "shadow") {   # a soft offset shadow, no hairline
    radius <- 10
    for (i in 6:1) rr(0.5 + i * .2, 1 + i * .55, W - 1 - i * .4, H - 3, grDevices::adjustcolor(INK, alpha.f = .011 * (7 - i)), r = 10 + i)
    rr(0.5, 0.5, W - 1, H - 3, PAPER, NA, r = radius)
    H <- H - 2.5
  } else if (frame == "simple") {
    rr(0.25, 0.25, W - .5, H - .5, PAPER, RULE, r = radius)
  } else {
    pad <- 1
  }
  # A legend only where colour encodes something the chart does not name: the
  # bars, columns and scatter label their main mark directly.
  if (type != "line") legend <- "none"
  y <- hdr_card(header, W, pad, legend = legend == "C", kpi = kpi == "A", fill = hfill)
  if (kpi == "B") y <- kpi_strip(pad, y + 4)
  y <- y + 5
  bottom <- H - d$foot_h - (if (legend == "A") 14 else 4)
  x0 <- pad
  if (kpi == "C") { kpi_rail(pad + 2, y, bottom - y); x0 <- pad + 62 }
  pushViewport(viewport(x = unit(x0, "pt"), y = Y(y), width = unit(W - x0 - pad, "pt"),
                        height = unit(bottom - y, "pt"), just = c("left", "top")))
  grid.draw(ggplotGrob(body_plot(body, type)))
  popViewport()
  if (legend == "A") legend_pill(W, bottom + 7, SERIES)
  footer(foot, W, H, pad, frame, radius)
}

# ── the editorial card: no frame, no bands, no pills. An ink hairline with the
# orange tab on top, the figure numeral hanging at the left, the eyebrow and the
# period on one line, title and subtitle; the KPI as plain type; the footer a
# hairline with the source and the ID.
card_editorial <- function(W, H, type = "line", kpi = FALSE) {
  d <<- DIMS$compact
  pad <- 2
  hline(pad, -pad, pad + .3, INK, .7)
  grid.rect(x = X(pad), y = Y(pad - .9), width = unit(18, "pt"), height = unit(2.4, "pt"),
            just = c("left", "top"), gp = gpar(fill = P, col = NA))
  y <- pad + 10
  nw <- tw("07", F_SERIF, 28) + 8
  txt("07", pad - 1, y + 11, F_SERIF, 28, P)
  x <- pad + nw
  eyebrow_line(x, y + 2, P, INK)
  mono(PERIOD, -pad, y + 2, d$stamp, MU, c("right", "center"))
  yy <- y + 9
  for (l in wrap_lines(TITLE, F_DISP, 11, W - x - pad)) { txt(l, x, yy + 6, F_DISP, 11, INK); yy <- yy + 12.5 }
  for (l in wrap_lines(SUBTITLE, F_SANS, 6.2, W - x - pad)) { txt(l, x, yy + 4.5, F_SANS, 6.2, MU); yy <- yy + 8.6 }
  if (kpi) {   # plain type: the value, its unit, the changes in their colour
    yy <- yy + 4
    txt(KPI$value, x, yy + 6, F_DISP, 13, INK)
    xx <- x + tw(KPI$value, F_DISP, 13) + 5
    mono(KPI$unit, xx, yy + 7, 3.7, MU); xx <- xx + tw(toupper(KPI$unit), F_MONO, 3.7) + 10
    for (m in KPI$d) {
      col <- switch(m[3], up = GREEN, down = RED, SLATE[1])
      lbl <- paste(m[2], m[1]); mono(lbl, xx, yy + 7, 4, col); xx <- xx + tw(toupper(lbl), F_MONO, 4) + 9
    }
    yy <- yy + 13
  }
  y <- yy + 6
  fh <- 13
  bottom <- H - fh - 4
  pushViewport(viewport(x = unit(pad, "pt"), y = Y(y), width = unit(W - 2 * pad, "pt"),
                        height = unit(bottom - y, "pt"), just = c("left", "top")))
  grid.draw(ggplotGrob(body_plot("A", type, style = "editorial")))
  popViewport()
  y0 <- H - fh
  hline(pad, -pad, y0, RULE, .5)
  mono("Fuente", pad, y0 + fh / 2, 3.7, SU); mono("BCRA · elaboración propia", pad + 19, y0 + fh / 2, 3.7, MU)
  mono(STAMP, -pad, y0 + fh / 2, 3.6, SU, c("right", "center"))
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

# Every header combination alone, for review: kinds × (plain, legend, KPI) ×
# (tint, no fill), each at the width of a half-page chart.
header_matrix <- function(kinds = c("A", "C", "D", "dark"), fills = c("tint", "none")) {
  grid.newpage()
  d <<- DIMS$compact
  W <- convertWidth(unit(1, "npc"), "pt", valueOnly = TRUE)
  colw <- (W - 14) / 2
  y <- 0
  cells <- list()
  for (k in kinds) for (f in (if (k == "dark") "tint" else fills)) for (j in 0:2) cells <- c(cells, list(list(k = k, f = f, j = j)))
  for (i in seq(1, length(cells), by = 2)) {
    row_h <- 0
    for (c in 0:1) {
      if (i + c > length(cells)) next
      cl <- cells[[i + c]]
      pushViewport(viewport(x = unit(c * (colw + 14), "pt"), y = Y(y), width = unit(colw, "pt"),
                            height = unit(160, "pt"), just = c("left", "top")))
      lab <- c("sola", "leyenda C", "KPI A")[cl$j + 1]
      txt(paste0(if (cl$k == "dark") "Obsidiana" else cl$k, if (cl$f == "none") " sin fondo" else "", " · ", lab), 2, 4, F_MONO, 4.6, MU)
      hh <- hdr_card(cl$k, colw, 10, legend = cl$j == 1, kpi = cl$j == 2, fill = cl$f)
      popViewport()
      row_h <- max(row_h, hh)
    }
    y <- y + row_h + 8
  }
}
