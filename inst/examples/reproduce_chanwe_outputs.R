# Reproduce ChanWe-branded outputs

# PDF-accurate preview: renders at the same dimensions Quarto uses (fig-width / fig-height)
# and opens the PNG so you see exactly what will appear in the PDF.
#
# w / h: match your chunk's fig-width / fig-height (inches). Defaults mirror chanwe-typst.
# res:   200 dpi gives sharp preview without being huge.
pdf_preview <- function(p, w = 6.3, h = 3.9, res = 200) {
  tmp <- tempfile(fileext = ".png")
  ragg::agg_png(tmp, width = w, height = h, units = "in", res = res)
  print(p)
  dev.off()
  browseURL(tmp)
  invisible(tmp)
}

# library(chanwer)
library(ggplot2)
library(kableExtra)
library(gt)
library(magrittr)
library(grid)

devtools::load_all()
mt <- tibble::as_tibble(mtcars, rownames = "model") |>
  dplyr::mutate(
    cyl = factor(cyl),
    gear = factor(gear),
    am = factor(am, labels = c("Automatic", "Manual")),
    hp_band = cut(
      hp,
      breaks = c(-Inf, 110, 180, Inf),
      labels = c("Low", "Mid", "High")
    )
  )
chanwe_load_fonts()

ggplot(mt, aes(wt, mpg, color = hp_band)) +
  geom_point(size = 2.2, alpha = 0.88) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
  # facet_wrap(~am) +
  scale_color_chanwe_d() +
  theme_chanwe(bg_color = "beige") +
  labs(
    title = chanwe_title(
      "Performance profile by transmission",
      eyebrow = "TLDR;"
    ),
    subtitle = chanwe_subtitle("Faceted by transmission type"),
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    color = "HP band",
    caption = chanwe_caption("Source: Motor Trend, 1974")
  )

ggplot(mt, aes(wt, mpg, color = hp_band)) +
  geom_point(size = 2.2, alpha = 0.88) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
  # facet_wrap(~am) +
  scale_color_chanwe_d() +
  theme_chanwe(bg_color = "gray", plot_borders = "none") +
  labs(
    title = chanwe_title(
      "Performance profile by transmission",
      eyebrow = "TLDR;"
    ),
    subtitle = chanwe_subtitle("Faceted by transmission type"),
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    color = "HP band",
    caption = chanwe_caption("Source: Motor Trend, 1974")
  )

ggplot(mt, aes(wt, mpg, color = hp_band)) +
  geom_point(size = 2.2, alpha = 0.88) +
  geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
  # facet_wrap(~am) +
  scale_color_chanwe_d() +
  theme_chanwe(bg_color = "white") +
  labs(
    title = chanwe_title(
      "Performance profile by transmission",
      eyebrow = "TLDR;"
    ),
    subtitle = chanwe_subtitle("Faceted by transmission type"),
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    color = "HP band",
    caption = chanwe_caption("Source: Motor Trend, 1974")
  )


pdf_preview(
  ggplot(mt, aes(wt, mpg, color = hp_band)) +
    geom_point(size = 2.2, alpha = 0.88) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
    scale_color_chanwe_d() +
    theme_chanwe(bg_color = "beige") +
    labs(
      title = chanwe_title(
        "Performance profile by transmission",
        eyebrow = "TLDR;"
      ),
      subtitle = chanwe_subtitle("Faceted by transmission type"),
      x = "Weight (1000 lbs)",
      y = "Miles per gallon",
      color = "HP band",
      caption = chanwe_caption("Source: Motor Trend, 1974")
    )
)
