#' Chanwe Layout for plotly Charts (HTML)
#'
#' Applies the Chanwe header grammar and chart chrome to an existing
#' `plotly` object: eyebrow / title / subtitle block anchored top-left in
#' Archivo, Satoshi body font, JetBrains Mono axis ticks, no axis lines or
#' ticks, hairline y-grid, an ink hover card in mono (`hovermode = "x
#' unified"` by default), a thin cursor spike, no modebar, no drag-zoom, and
#' an optional `//`-prefixed caption.
#'
#' Discrete colours are not changed by this function -- pass
#' `colors = chanwe_palette("chart")` to `plotly::plot_ly()`. The layout
#' `colorway` is set to the chart palette for traces that do not carry an
#' explicit colour.
#'
#' @param p A `plotly` object.
#' @param title,subtitle,eyebrow Header block rendered top-left. Plain text;
#'   plotly's limited pseudo-HTML is applied internally.
#' @param caption Source note rendered bottom-left with a `//` prefix.
#' @param legend Logical. Show the legend (horizontal, bottom-right)?
#'   Default `FALSE` -- prefer direct labels via `plotly::add_annotations()`.
#' @param hovermode Passed to `plotly::layout()`. Default `"x unified"`.
#' @param bg Paper and plot background. Named shorthand accepted by
#'   [theme_chanwe()] or any hex string. Default `"white"`.
#'
#' @return The modified `plotly` object.
#' @export
#'
#' @examplesIf requireNamespace("plotly", quietly = TRUE)
#' p <- plotly::plot_ly(
#'   mtcars, x = ~wt, y = ~mpg, color = ~factor(cyl),
#'   colors = unname(chanwe_palette("chart"))[1:3],
#'   type = "scatter", mode = "markers"
#' )
#' p <- chanwe_plotly(
#'   p,
#'   title = "Fleet overview",
#'   eyebrow = "SECTION · EFFICIENCY",
#'   subtitle = "Weight against fuel economy.",
#'   caption = "Source · Motor Trend, 1974."
#' )
chanwe_plotly <- function(
  p,
  title = NULL,
  subtitle = NULL,
  eyebrow = NULL,
  caption = NULL,
  legend = FALSE,
  hovermode = "x unified",
  bg = "white"
) {
  chanwe_require_package("plotly")
  tk <- chanwe_html_tokens()
  bg <- chanwe_resolve_bg(bg)
  if (identical(bg, "transparent")) {
    bg <- "rgba(0,0,0,0)"
  }
  ax_font <- list(family = .cw_font_mono, size = 10.5, color = tk$fg_muted)

  title_html <- NULL
  if (!is.null(title) || !is.null(subtitle) || !is.null(eyebrow)) {
    parts <- c(
      if (!is.null(eyebrow)) {
        sprintf(
          "<span style='font-size:10px;color:%s'>\u2014\u2014 %s</span>",
          tk$accent, chanwe_html_escape(eyebrow)
        )
      },
      if (!is.null(title)) {
        sprintf(
          "<span style='font-size:19px;color:%s'>%s</span>",
          tk$ink, chanwe_html_escape(title)
        )
      },
      if (!is.null(subtitle)) {
        sprintf(
          "<span style='font-size:12px;color:%s'>%s</span>",
          tk$fg_muted, chanwe_html_escape(subtitle)
        )
      }
    )
    title_html <- paste(parts, collapse = "<br>")
  }

  # Bottom margin is built in pixel bands so nothing overlaps or clips:
  # ticks + axis title (48) | caption (30) | legend (34, container-anchored).
  top <- if (is.null(title_html)) 24 else 96
  base_b <- 48
  cap_h <- if (is.null(caption)) 0 else 30
  leg_h <- if (isTRUE(legend)) 34 else 0
  bottom <- base_b + cap_h + leg_h

  args <- list(
    p,
    font = list(family = .cw_font_sans, color = tk$fg_muted),
    colorway = unname(chanwe_palette("chart")),
    paper_bgcolor = bg,
    plot_bgcolor = bg,
    margin = list(l = 44, r = 24, t = top, b = bottom),
    showlegend = isTRUE(legend),
    legend = list(
      orientation = "h",
      x = 1,
      xanchor = "right",
      yref = "container",
      y = 0,
      yanchor = "bottom",
      font = ax_font
    ),
    hovermode = hovermode,
    hoverdistance = 40,
    hoverlabel = list(
      bgcolor = tk$ink,
      bordercolor = "rgba(0,0,0,0)",
      font = list(family = .cw_font_mono, size = 11, color = "#FFFFFF"),
      align = "left"
    ),
    dragmode = FALSE,
    xaxis = list(
      showgrid = FALSE,
      zeroline = FALSE,
      showline = FALSE,
      ticks = "",
      tickfont = ax_font,
      title = list(font = ax_font),
      showspikes = TRUE,
      spikemode = "across",
      spikesnap = "cursor",
      spikethickness = 1,
      spikecolor = tk$n300,
      spikedash = "solid"
    ),
    yaxis = list(
      gridcolor = "#ECECEC",
      gridwidth = 1,
      zeroline = FALSE,
      showline = FALSE,
      ticks = "",
      tickfont = ax_font,
      title = list(font = ax_font, standoff = 10)
    )
  )
  if (!is.null(title_html)) {
    args$title <- list(
      text = title_html,
      x = 0,
      xanchor = "left",
      xref = "paper",
      y = 0.97,
      yanchor = "top",
      font = list(family = .cw_font_display)
    )
  }
  p <- do.call(plotly::layout, args)

  if (!is.null(caption)) {
    p <- plotly::add_annotations(
      p,
      text = sprintf(
        "<span style='color:%s'>//</span>  %s",
        tk$accent, chanwe_html_escape(caption)
      ),
      xref = "paper",
      yref = "paper",
      x = 0,
      y = 0,
      xanchor = "left",
      yanchor = "top",
      yshift = -(base_b + 12),
      showarrow = FALSE,
      font = list(family = .cw_font_mono, size = 10, color = tk$fg_muted)
    )
  }

  p <- plotly::config(
    p,
    displayModeBar = FALSE,
    displaylogo = FALSE,
    scrollZoom = FALSE,
    responsive = TRUE
  )
  p$dependencies <- c(p$dependencies, chanwe_html_fonts_dependency())
  p
}
