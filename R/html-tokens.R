# Shared building blocks for the HTML helpers: chanwe_gt(), chanwe_reactable()
# and chanwe_plotly(). They port the chanwe_kbl() header grammar (eyebrow /
# title / subtitle / `//` caption) to browser output so a table or chart
# looks the same in a Quarto HTML report as it does in the Typst PDF.
#
# Font stacks mirror the Typst templates: Archivo for display, Satoshi for
# body text, JetBrains Mono for eyebrows, column labels and figures. Every
# stack falls back to the current HTML stylesheet face (DM Sans) and then to
# the platform UI font.

.cw_font_sans <- "Satoshi, 'DM Sans', system-ui, -apple-system, sans-serif"
.cw_font_display <- "Archivo, system-ui, sans-serif"
.cw_font_mono <- paste0(
  "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
)

# Token bundle used by the HTML helpers. All values come from the brand
# token table so the HTML output stays aligned with chanwe_kbl() and the
# Typst templates.
chanwe_html_tokens <- function() {
  tk <- chanwe_get_colors()
  list(
    ink = tk[["typst-ink"]],
    fg = tk[["typst-fg"]],
    fg_muted = tk[["typst-fg-muted"]],
    fg_subtle = tk[["typst-fg-subtle"]],
    primary = tk[["typst-primary"]],
    primary_text = tk[["typst-primary-text"]],
    # pressed state one shade darker than the primary, mirroring the HTML
    # stylesheet's --cw-color-primary-active (brand-orange-950)
    primary_active = tk[["mb-orange-950"]],
    # eyebrows and the `//` caption prefix: the brand orange used for HTML
    # section numbers, shared with theme_chanwe() and chanwe_kbl()
    accent = tk[["brand-orange"]],
    n100 = tk[["typst-neutral-100"]],
    n200 = tk[["typst-neutral-200"]],
    n300 = tk[["typst-neutral-300"]],
    positive = tk[["signed-positive"]],
    negative = tk[["signed-negative"]],
    neutral = tk[["signed-neutral"]]
  )
}

# Minimal HTML escaping for user-supplied header strings.
chanwe_html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# Colour for a signed value: positive / negative / neutral brand tokens.
# Colour encodes valence, never the raw sign: `smaller_is_better = TRUE`
# flips the mapping (same rule as chanwe_col_signed()).
chanwe_signed_color <- function(x, tk, smaller_is_better = FALSE) {
  x <- suppressWarnings(as.numeric(x))
  pos <- if (smaller_is_better) tk$negative else tk$positive
  neg <- if (smaller_is_better) tk$positive else tk$negative
  out <- rep(tk$neutral, length(x))
  out[!is.na(x) & x > 0] <- pos
  out[!is.na(x) & x < 0] <- neg
  out
}

# Inline-styled header block (eyebrow / title / subtitle) as an htmltools tag.
# Used by chanwe_reactable(); chanwe_gt() builds the same structure inside the
# gt heading instead. Returns NULL when there is nothing to show.
#
# When `bg` is given the block carries the table background and the ink rule
# on its own top edge, so the widget reads as one card: rule, header, table.
# The 12px side inset matches the reactable cellPadding ("10px 12px") so the
# texts align with cell content.
chanwe_html_header_tag <- function(
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  bg = NULL
) {
  if (is.null(title) && is.null(subtitle) && is.null(eyebrow)) {
    return(NULL)
  }
  chanwe_require_package("htmltools")
  tk <- chanwe_html_tokens()
  tags <- htmltools::tags
  style <- if (is.null(bg)) {
    "padding: 4px 0 12px 0;"
  } else {
    sprintf(
      "background:%s; border-top:1px solid %s; padding: 10px 12px 12px;",
      bg, tk$ink
    )
  }
  tags$div(
    class = "chanwe-html-header",
    style = style,
    if (!is.null(eyebrow)) {
      tags$div(
        class = "chanwe-eyebrow",
        style = sprintf(
          paste0(
            "display:flex; align-items:center; gap:8px; ",
            "font: 500 10px/1.2 %s; letter-spacing:.18em; ",
            "text-transform:uppercase; color:%s; margin-bottom:8px;"
          ),
          .cw_font_mono, tk$accent
        ),
        tags$span(style = sprintf(
          "display:inline-block; width:22px; height:1px; background:%s;",
          tk$accent
        )),
        eyebrow
      )
    },
    if (!is.null(title)) {
      tags$div(
        class = "chanwe-title",
        style = sprintf(
          "font: 600 20px/1.1 %s; letter-spacing:-0.015em; color:%s;",
          .cw_font_display, tk$ink
        ),
        title
      )
    },
    if (!is.null(subtitle)) {
      tags$div(
        class = "chanwe-subtitle",
        style = sprintf(
          "font: 400 13px/1.45 %s; color:%s; padding-top:4px;",
          .cw_font_sans, tk$fg_muted
        ),
        subtitle
      )
    }
  )
}

# `//`-prefixed source line as an htmltools tag (chanwe_caption() for HTML).
# As with chanwe_html_header_tag(), a `bg` puts the line on the table
# background with the 12px side inset so the widget reads as one card.
chanwe_html_caption_tag <- function(caption, bg = NULL) {
  if (is.null(caption)) {
    return(NULL)
  }
  chanwe_require_package("htmltools")
  tk <- chanwe_html_tokens()
  tags <- htmltools::tags
  base_style <- sprintf(
    "font: 400 10.5px/1.4 %s; color:%s;",
    .cw_font_mono, tk$fg_muted
  )
  style <- if (is.null(bg)) {
    paste(base_style, "padding: 8px 0 0;")
  } else {
    # hairline above the caption: same neutral rule as under the column labels
    paste(base_style, sprintf(
      "background:%s; border-top:0.5px solid %s; padding: 12px 12px 10px;",
      bg, tk$n300
    ))
  }
  tags$div(
    class = "chanwe-html-caption",
    style = style,
    tags$span(style = sprintf("color:%s;", tk$accent), "//"),
    " ",
    caption
  )
}

# Web-font dependency (Satoshi from Fontshare; Archivo + JetBrains Mono from
# Google Fonts) attached to the htmlwidgets so the helpers render with the
# brand faces even when chanwe_reporting_css() is not loaded. Quarto requires
# widget dependencies to be disk-based, so the CDN links are injected through
# `head` and the (empty) file source points at the package's quarto dir.
chanwe_html_fonts_dependency <- function() {
  chanwe_require_package("htmltools")
  src <- system.file("quarto", package = "chanwer")
  if (!nzchar(src)) {
    src <- tempdir()
  }
  list(
    htmltools::htmlDependency(
      name = "chanwe-fonts",
      version = "1.0.0",
      src = c(file = src),
      all_files = FALSE,
      head = paste0(
        '<link rel="stylesheet" href="https://api.fontshare.com/v2/css',
        '?f%5B%5D=satoshi@400,500,700&amp;display=swap">',
        '<link rel="stylesheet" href="https://fonts.googleapis.com/css2',
        '?family=Archivo:wght@500;600;700',
        '&amp;family=JetBrains+Mono:wght@300;400;500&amp;display=swap">'
      )
    )
  )
}
