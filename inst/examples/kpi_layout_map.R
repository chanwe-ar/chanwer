# KPI layout diagnostic — run this chunk to see where every element sits.
# Y axis = pt from bottom of the subtitle grob (same coordinates as makeContent).
# Edit the values at the top to match ggplot2-elements.R and re-run.

# ── current parameters (mirror ggplot2-elements.R) ──────────────────────────
kpi_bot_sep  <- 16    # gap below bottom separator → chart
kpi_bot_ln_h <- 0.3  # bottom separator line thickness
kpi_bot_pad  <- 2     # gap: bottom separator → KPI content bottom
kpi_panel_h  <- 35    # KPI content height
kpi_top_pad  <- 4     # gap: KPI content top → subtitle separator

# within makeContent
kpi_center_y <- kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad + kpi_panel_h / 2

# element y-offsets (relative to kpi_center_y)
y_unit         <- kpi_center_y + 7
y_date         <- kpi_center_y - 2
y_hero         <- kpi_center_y
y_metric_label <- kpi_center_y + 5
y_metric_value <- kpi_center_y - 5

# column x-positions (npc, right edge of each column)
col_right <- 0.98
col_step  <- 0.18
n_metrics <- 3
col_x <- col_right - (n_metrics - seq_len(n_metrics)) * col_step
# → WOW: 0.62, MOM: 0.80, YOY: 0.98

# ── build diagram ────────────────────────────────────────────────────────────
total_h <- kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad + kpi_panel_h + kpi_top_pad

zones <- data.frame(
  ymin  = c(0, kpi_bot_sep, kpi_bot_sep + kpi_bot_ln_h,
             kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad,
             kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad + kpi_panel_h),
  ymax  = c(kpi_bot_sep,
             kpi_bot_sep + kpi_bot_ln_h,
             kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad,
             kpi_bot_sep + kpi_bot_ln_h + kpi_bot_pad + kpi_panel_h,
             total_h),
  fill  = c("#FDE8C8", "#555555", "#C8DFF5", "#D4EDD4", "#F5D4F5"),
  label = c(
    sprintf("kpi_bot_sep = %g pt", kpi_bot_sep),
    sprintf("kpi_bot_ln_h = %g pt", kpi_bot_ln_h),
    sprintf("kpi_bot_pad = %g pt", kpi_bot_pad),
    sprintf("kpi_panel_h = %g pt", kpi_panel_h),
    sprintf("kpi_top_pad = %g pt", kpi_top_pad)
  )
)
zones$ymid <- (zones$ymin + zones$ymax) / 2

pts <- data.frame(
  y     = c(y_hero, y_unit, y_date, y_metric_label, y_metric_value),
  label = c(
    sprintf("hero value  y = %.1f  (kpi_center_y)", y_hero),
    sprintf("unit        y = %.1f  (kpi_center_y + 7)", y_unit),
    sprintf("date        y = %.1f  (kpi_center_y - 2)", y_date),
    sprintf("mtc label   y = %.1f  (kpi_center_y + 5)", y_metric_label),
    sprintf("mtc value   y = %.1f  (kpi_center_y - 5)", y_metric_value)
  )
)

col_df <- data.frame(
  x     = col_x,
  label = sprintf("col %d right-edge\nx = %.2f npc", seq_len(n_metrics), col_x)
)

library(ggplot2)

ggplot() +
  # zone rectangles
  geom_rect(data = zones,
            aes(xmin = 0, xmax = 1, ymin = ymin, ymax = ymax, fill = fill),
            color = "white", linewidth = 0.4) +
  scale_fill_identity() +
  # zone labels (left side)
  geom_text(data = zones,
            aes(x = 0.02, y = ymid, label = label),
            hjust = 0, size = 2.8, family = "mono", color = "#1A1A1A") +
  # element dot + label (right side)
  geom_point(data = pts, aes(x = 0.62, y = y),
             shape = 21, fill = "#FB3D0E", color = "white", size = 2.5) +
  geom_text(data = pts, aes(x = 0.64, y = y, label = label),
            hjust = 0, size = 2.5, family = "mono", color = "#333333") +
  # column x-position lines
  geom_vline(xintercept = col_x, linetype = "dashed",
             color = "#2D7A4F", linewidth = 0.3) +
  geom_label(data = col_df, aes(x = x, y = 1, label = label),
             hjust = 1, vjust = 0, size = 2.2, family = "mono",
             fill = "#EAF6EE", color = "#2D7A4F", label.size = 0.2) +
  # kpi_center_y reference line
  geom_hline(yintercept = kpi_center_y, linetype = "dotted",
             color = "#FB3D0E", linewidth = 0.4) +
  annotate("text", x = 0.01, y = kpi_center_y + 0.8,
           label = sprintf("kpi_center_y = %.1f pt", kpi_center_y),
           hjust = 0, size = 2.5, color = "#FB3D0E", family = "mono") +
  scale_y_continuous(
    name   = "pt from bottom of subtitle grob",
    breaks = sort(unique(c(0, zones$ymin, zones$ymax, round(kpi_center_y, 1)))),
    expand = expansion(mult = 0.06)
  ) +
  scale_x_continuous(name = "npc (0 = left edge, 1 = right edge)",
                     breaks = c(0, col_x, 1),
                     labels = c("0", sprintf("%.2f", col_x), "1")) +
  labs(title = "KPI panel layout map",
       subtitle = "Green dashed = metric column right-edges  ·  Orange dotted = kpi_center_y  ·  Edit values at top of script") +
  theme_minimal(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold"),
    axis.text.x      = element_text(size = 7)
  )
