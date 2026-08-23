# Display every ChanWe color palette and scale
#
# Availability map:
#   chanwe_palette()            -> list(all = <130+ tokens>, groups = <20 groups>)
#   chanwe_palette("<group>")   -> named hex vector for one group
#   chanwe_preview_palette()    -> swatch grid of any group
#
# Groups: core, p13_orange, p13_gray, p14_accents,
#         p15_coral, p15_vermillion, p15_green, p15_magenta, p15_blue,
#         p15_yellow, p15_cyan, p15_mustard, p15_violet, p15_teal, p15_ink,
#         mb_orange, mb_dark, mb_beige, semantic, signed, chart
#
# Scales built on them:
#   scale_color_chanwe_d() / scale_fill_chanwe_d()     categorical / ordinal
#   scale_color_chanwe_c() / scale_fill_chanwe_c()     sequential magnitude
#   scale_color_chanwe_div() / scale_fill_chanwe_div() diverging polarity
#   chanwe_col_signed()                                signed values in tables

devtools::load_all(".")

library(ggplot2)

# ── 1. Browse the token inventory ────────────────────────────────────────────

str(chanwe_palette(), max.level = 2)   # everything: all tokens + all groups
chanwe_palette("chart")                # the categorical 8, CVD-validated order
chanwe_palette("signed")               # canonical positive / negative / neutral
chanwe_palette("semantic")             # roles incl. positive/negative/neutral

# Swatch grid for any group:
print(chanwe_preview_palette("chart"))
print(chanwe_preview_palette("signed"))
print(chanwe_preview_palette("p15_teal"))
print(chanwe_preview_palette("mb_orange"))

# ── 2. Categorical — identity (which series) ─────────────────────────────────
# Fixed slot order: coral, blue, teal, green, violet, magenta, mustard, ink.
# Scatter/bubble: keep to <= 3 series (all-pairs CVD cap).

mt <- dplyr::mutate(mtcars, cyl = factor(cyl), gear = factor(gear))

print(
  ggplot(mt, aes(wt, mpg, color = cyl)) +
    geom_point(size = 3) +
    scale_color_chanwe_d() +
    labs(title = chanwe_title("Categorical", eyebrow = "SCALES - IDENTITY")) +
    theme_chanwe(has_subtitle = FALSE)
)

# ── 3. Ordinal — ordered categories take a one-hue ramp ─────────────────────

print(
  ggplot(mt, aes(gear, fill = gear)) +
    geom_bar() +
    scale_fill_chanwe_d(palette = "p15_blue", reverse = TRUE) +
    labs(title = chanwe_title("Ordinal ramp", eyebrow = "SCALES - ORDER")) +
    theme_chanwe(has_subtitle = FALSE, legend_position = "none")
)

# ── 4. Sequential — magnitude (how much) ─────────────────────────────────────
# Named ramps: orange (default), coral, blue, teal, green, vermillion,
# magenta, violet, mustard, ink. Yellow/cyan deliberately excluded (too
# light to encode magnitude on the brand surfaces).

print(
  ggplot(mt, aes(wt, mpg, color = disp)) +
    geom_point(size = 3) +
    scale_color_chanwe_c(palette = "teal") +
    labs(title = chanwe_title("Sequential", eyebrow = "SCALES - MAGNITUDE")) +
    theme_chanwe(has_subtitle = FALSE)
)

# ── 5. Diverging — polarity around a baseline ────────────────────────────────
# Vermillion (negative) -> neutral -> green (positive); poles are the signed
# tokens. Use symmetric limits so zero lands on the neutral midpoint.

heat <- expand.grid(x = 1:8, y = 1:5)
heat$delta <- round(seq(-4, 4, length.out = nrow(heat)) + rnorm(nrow(heat), 0, 0.4), 1)
m <- max(abs(heat$delta))

print(
  ggplot(heat, aes(x, y, fill = delta)) +
    geom_tile(color = "#F7F7F7", linewidth = 1) +
    scale_fill_chanwe_div(limits = c(-m, m)) +
    labs(title = chanwe_title("Diverging", eyebrow = "SCALES - POLARITY")) +
    theme_chanwe(has_subtitle = FALSE)
)

# ── 6. Signed values in Typst tables ─────────────────────────────────────────
# Same three tokens as the KPI arrows and the diverging poles.

deltas <- data.frame(kpi = c("Sales", "Churn", "Costs"), qoq = c(3.2, -0.8, 1.1))

tbl <- chanwe_kbl(
  deltas,
  title = "Signed deltas",
  fmt = list(qoq = function(x) sprintf("%+.1f%%", x)),
  col_colors = list(qoq = chanwe_col_signed())
)
cat(as.character(tbl))

# Smaller-is-better metrics flip the mapping (a cost going down is positive):
chanwe_col_signed(flip = TRUE)(c(-3, 4))
