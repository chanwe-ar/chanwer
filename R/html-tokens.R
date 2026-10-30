# Shared building blocks for the HTML helpers: chanwe_gt(), chanwe_reactable()
# and chanwe_highchart(). They port the chanwe_kbl() header grammar (eyebrow /
# title / subtitle / stamp caption) to browser output so a table or chart
# looks the same in a Quarto HTML report as it does in the Typst PDF.
#
# Font stacks follow chanwe-brandbook tokens.json `font`: Satoshi for body
# text, Schibsted Grotesk for display, JetBrains Mono for eyebrows, column
# labels and figures. The fallbacks are the token stacks' system fonts;
# Inter, retired, is left out. Multi-word names are left unquoted (valid
# CSS) so the stacks can sit inside single- or double-quoted style
# attributes. The faces themselves come from chanwe_html_fonts_dependency().

.cw_font_sans <- paste0(
  "Satoshi, -apple-system, BlinkMacSystemFont, Segoe UI, Arial, sans-serif"
)
.cw_font_display <- "Schibsted Grotesk, Helvetica Neue, Arial, sans-serif"
.cw_font_mono <- paste0(
  "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
)

# Token bundle used by the HTML helpers. All values come from the brand
# token table so the HTML output stays aligned with chanwe_kbl() and the
# Typst templates.
chanwe_html_tokens <- function() {
  tk <- chanwe_get_colors()
  list(
    ink = tk[["ink"]],
    fg = tk[["fg"]],
    fg_muted = tk[["fg-muted"]],
    fg_subtle = tk[["fg-subtle"]],
    primary = tk[["primary"]],
    primary_text = tk[["primary-text"]],
    # pressed state: brand.yml aliases primary-active to primary (one orange)
    primary_active = tk[["primary-active"]],
    # eyebrows and the caption stamp: the brand orange used for HTML
    # section numbers, shared with theme_chanwe() and chanwe_kbl()
    accent = tk[["primary"]],
    n100 = tk[["surface-sunken"]],
    n200 = tk[["rule"]],
    n300 = tk[["neutral-300"]],
    # Rules follow the chanwe-report figure frame: slate, never ink.
    # `rule` for the structural lines (above the header, under the column
    # labels, above the caption), `rule_row` for the lighter row dividers.
    rule = tk[["border-cool"]],
    rule_row = tk[["rule"]],
    positive = tk[["signed-positive"]],
    negative = tk[["signed-negative"]],
    neutral = tk[["signed-neutral"]],
    # v2 (brand-v2.md): the tint (text colour at 7%) for table headers and
    # hover, the pane hairline, the plot tokens and the radii in px.
    tint = tk[["tint"]],
    pane = tk[["pane"]],
    hairline = tk[["rule"]],
    focus = chanwe_tokens$plot$focus,
    grid = chanwe_tokens$plot$grid,
    axis_text = chanwe_tokens$plot$`axis-text`,
    title = chanwe_tokens$plot$title,
    white = tk[["pure-white"]],
    radius_surface = chanwe_tokens$radii$surface,
    radius_pill = chanwe_tokens$radii$pill,
    bar_radius = chanwe_tokens$plot$`bar-radius`,
    type = chanwe_tokens$type
  )
}

# The caption style every helper takes by default: "mono" (v2) or "stamp"
# (the orange stamp of chanwer 2.x). Set options(chanwer.caption_style =
# "stamp") to keep the old look everywhere.
chanwe_caption_style <- function(style = NULL) {
  style <- style %||_% getOption("chanwer.caption_style", "mono")
  match.arg(style, c("mono", "stamp"))
}

# Inline style of the caption. v2 ("mono"): a JetBrains Mono label at the
# compact size (type.caption) in plot.axis-text, spaced capitals. "stamp":
# the chanwe-report figure-frame stamp of chanwer 2.x, a square primary box
# with white mono caps. Double quotes only, so it can sit inside a
# single-quoted style attribute (highcharter).
chanwe_html_stamp_style <- function(style = NULL) {
  tk <- chanwe_html_tokens()
  mono <- gsub("'", "\"", .cw_font_mono, fixed = TRUE)
  if (chanwe_caption_style(style) == "stamp") {
    return(sprintf(
      paste0(
        "display:inline-block; background:%s; color:%s; ",
        "font: 500 9px/1.2 %s; letter-spacing:.16em; ",
        "text-transform:uppercase; padding:5px 14px; border-radius:0;"
      ),
      tk$primary, tk$white, mono
    ))
  }
  sprintf(
    paste0(
      "display:inline-block; color:%s; font: 400 %spx/1.3 %s; ",
      "letter-spacing:.08em; text-transform:uppercase;"
    ),
    tk$axis_text, tk$type$caption, mono
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
# When `bg` is given the block carries the table background and the slate
# rule on its own top edge, so the widget reads as one card: rule, header, table.
# The 12px side inset matches the reactable cellPadding ("10px 12px") so the
# texts align with cell content.
chanwe_html_header_tag <- function(
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  bg = NULL
) {
  # with a `bg`, the block is the top of a v2 pane (16px top corners, the
  # hairline on three sides); the table below it continues the pane
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
      paste0(
        "background:%1$s; border:1px solid %2$s; border-bottom:none; ",
        "border-radius:%3$spx %3$spx 0 0; padding: 14px 16px 12px;"
      ),
      bg, tk$hairline, tk$radius_surface
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

# Source line as an htmltools tag (chanwe_caption() for HTML), styled as the
# chanwe-report figure-frame stamp: a square primary box with white mono caps,
# under a slate hairline.
# As with chanwe_html_header_tag(), a `bg` puts the line on the table
# background with the 12px side inset so the widget reads as one card.
chanwe_html_caption_tag <- function(caption, bg = NULL, caption_style = NULL) {
  if (is.null(caption)) {
    return(NULL)
  }
  chanwe_require_package("htmltools")
  tk <- chanwe_html_tokens()
  tags <- htmltools::tags
  style <- if (is.null(bg)) {
    "padding: 8px 0 0;"
  } else {
    # the foot of the v2 pane: hairline on every side, 16px bottom corners
    sprintf(
      paste0(
        "background:%1$s; border:1px solid %2$s; ",
        "border-radius:0 0 %3$spx %3$spx; padding: 10px 16px 12px;"
      ),
      bg, tk$hairline, tk$radius_surface
    )
  }
  tags$div(
    class = "chanwe-html-caption",
    style = style,
    tags$span(class = "chanwe-stamp", style = chanwe_html_stamp_style(caption_style), caption)
  )
}

# Web-font dependency attached to the htmlwidgets (chanwe_reactable(),
# chanwe_highchart()) so they render in the brand faces even when the page
# does not load them. It is the WOFF2 the package ships in inst/fonts/web
# (the brandbook's brand/fonts/web files, Satoshi, Schibsted Grotesk and
# JetBrains Mono) with a local @font-face stylesheet: no Google Fonts or other
# CDN request, so a report renders the same offline, and a self-contained
# Quarto/R Markdown file carries the fonts inside it. Quarto requires widget
# dependencies to be disk-based, which a packaged folder is.
chanwe_html_fonts_dependency <- function() {
  chanwe_require_package("htmltools")
  list(
    htmltools::htmlDependency(
      name = "chanwe-fonts",
      version = "3.0.0",
      src = c(file = chanwe_fonts_dir("web")),
      stylesheet = "chanwe-fonts.css",
      all_files = TRUE
    )
  )
}

# Folder of the bundled fonts (inst/fonts), or one of its subfolders.
chanwe_fonts_dir <- function(...) {
  dir <- system.file("fonts", ..., package = "chanwer")
  if (!nzchar(dir)) {
    stop(
      "The brand fonts bundled with chanwer were not found; reinstall chanwer.",
      call. = FALSE
    )
  }
  dir
}
