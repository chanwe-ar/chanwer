#' ChanWe Theme for highcharter
#'
#' Creates a Highcharts theme list with ChanWe colors and typography.
#'
#' @return A highcharter theme object suitable for
#'   [highcharter::hc_add_theme()].
#' @export
#'
#' @examples
#' if (requireNamespace("highcharter", quietly = TRUE)) {
#'   hc <- highcharter::hchart(
#'     mtcars,
#'     "scatter",
#'     highcharter::hcaes(wt, mpg)
#'   ) |>
#'     highcharter::hc_add_theme(hc_theme_chanwe())
#' }
hc_theme_chanwe <- function() {
  chanwe_require_package("highcharter")

  colors <- chanwe_get_colors()

  highcharter::hc_theme(
    colors = unname(chanwe_get_chart()),
    chart = list(
      backgroundColor = colors[["brand-pure-white"]],
      style = list(
        fontFamily = "DM Sans",
        color = colors[["p13-gray-05"]]
      ),
      borderColor = colors[["brand-beige-soft"]],
      borderWidth = 1,
      borderRadius = 4,
      shadow = FALSE
    ),
    title = list(
      style = list(
        color = colors[["brand-black"]],
        fontWeight = "900"
      )
    ),
    subtitle = list(
      style = list(
        color = colors[["p13-gray-06"]],
        fontWeight = "500"
      )
    ),
    xAxis = list(
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-05"]])),
      title = list(style = list(color = colors[["p13-gray-04"]]))
    ),
    yAxis = list(
      gridLineColor = colors[["brand-beige-soft"]],
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-05"]])),
      title = list(style = list(color = colors[["p13-gray-04"]]))
    ),
    legend = list(
      itemStyle = list(
        color = colors[["p13-gray-05"]],
        fontWeight = "600"
      ),
      itemHoverStyle = list(
        color = colors[["brand-orange"]]
      )
    ),
    tooltip = list(
      borderColor = colors[["brand-orange"]],
      backgroundColor = colors[["brand-pure-white"]],
      style = list(
        color = colors[["p13-gray-05"]],
        fontFamily = "DM Sans"
      ),
      shadow = FALSE
    ),
    plotOptions = list(
      series = list(
        dataLabels = list(
          style = list(
            color = colors[["p13-gray-05"]],
            textOutline = "none",
            fontWeight = "500"
          )
        ),
        marker = list(lineColor = colors[["brand-pure-white"]])
      )
    )
  )
}
