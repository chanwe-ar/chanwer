#' ChanWe Theme for highcharter
#'
#' Creates a Highcharts theme list with ChanWe colors and typography.
#'
#' @param add_logo Logical. If `TRUE`, adds the gray ChanWe logo at the
#'   top-right of the chart area.
#' @param logo_width_px Width of the logo in pixels.
#' @param logo_height_px Height of the logo in pixels.
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
hc_theme_chanwe <- function(add_logo = TRUE,
                            logo_width_px = 56,
                            logo_height_px = 22) {
  chanwe_require_package("highcharter")

  colors <- chanwe_get_colors()
  logo_event <- NULL

  if (isTRUE(add_logo)) {
    logo_path <- chanwe_logo_path("Logo_Negro.png")
    logo_src <- chanwe_logo_src(logo_path)

    if (nzchar(logo_src)) {
      logo_event <- highcharter::JS(sprintf(
        "function(){
           if(!this.chanweLogo){
             this.chanweLogo = this.renderer.image('%s', this.chartWidth - %d, 10, %d, %d).add();
           }
         }",
        logo_src,
        as.integer(logo_width_px + 12),
        as.integer(logo_width_px),
        as.integer(logo_height_px)
      ))
    }
  }

  highcharter::hc_theme(
    colors = unname(chanwe_get_chart()),
    chart = list(
      backgroundColor = colors[["brand-white"]],
      style = list(
        fontFamily = "DM Sans",
        color = colors[["p13-gray-06"]]
      ),
      borderColor = colors[["brand-beige-soft"]],
      borderWidth = 1,
      borderRadius = 4,
      spacingTop = 28,
      spacingRight = 26,
      spacingBottom = 24,
      spacingLeft = 26,
      events = list(load = logo_event),
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
      gridLineColor = colors[["brand-beige-soft"]],
      gridLineWidth = 1,
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-06"]])),
      title = list(
        style = list(
          color = colors[["p13-gray-05"]],
          fontWeight = "700"
        )
      )
    ),
    yAxis = list(
      gridLineColor = colors[["brand-beige-soft"]],
      gridLineWidth = 1,
      lineColor = colors[["brand-beige-soft"]],
      tickColor = colors[["brand-beige-soft"]],
      labels = list(style = list(color = colors[["p13-gray-06"]])),
      title = list(
        style = list(
          color = colors[["p13-gray-05"]],
          fontWeight = "700"
        )
      )
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
      backgroundColor = colors[["brand-white"]],
      style = list(
        color = colors[["p13-gray-06"]],
        fontFamily = "DM Sans"
      ),
      shadow = FALSE
    ),
    plotOptions = list(
      series = list(
        dataLabels = list(
          style = list(
            color = colors[["p13-gray-06"]],
            textOutline = "none",
            fontWeight = "500"
          )
        ),
        marker = list(lineColor = colors[["brand-pure-white"]])
      )
    )
  )
}
