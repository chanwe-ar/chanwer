#' ChanWe Theme for reactable
#'
#' Returns a [reactable::reactableTheme()] object with ChanWe typography,
#' neutral surfaces, and orange accents.
#'
#' @return A reactable theme object.
#' @export
#'
#' @examples
#' if (requireNamespace("reactable", quietly = TRUE)) {
#'   tbl <- reactable::reactable(head(mtcars), theme = reactable_theme_chanwe())
#' }
reactable_theme_chanwe <- function() {
  chanwe_require_package("reactable")

  colors <- chanwe_get_colors()

  reactable::reactableTheme(
    color = colors[["p13-gray-05"]],
    backgroundColor = colors[["brand-pure-white"]],
    borderColor = colors[["brand-beige-soft"]],
    stripedColor = colors[["brand-beige"]],
    highlightColor = grDevices::adjustcolor(
      colors[["brand-orange"]],
      alpha.f = 0.08
    ),
    inputStyle = list(
      borderColor = colors[["brand-beige-soft"]],
      borderRadius = "4px",
      boxShadow = "none",
      fontFamily = "DM Sans"
    ),
    pageButtonHoverStyle = list(
      backgroundColor = colors[["p13-orange-09"]],
      color = colors[["brand-black"]],
      borderRadius = "4px"
    ),
    pageButtonActiveStyle = list(
      backgroundColor = colors[["brand-orange"]],
      color = colors[["brand-pure-white"]],
      borderRadius = "4px"
    ),
    style = list(
      fontFamily = "DM Sans",
      fontSize = "13.5px",
      lineHeight = "1.62",
      borderRadius = "4px",
      boxShadow = "none"
    ),
    tableStyle = list(
      borderCollapse = "separate",
      borderSpacing = 0
    ),
    headerStyle = list(
      background = colors[["brand-beige"]],
      color = colors[["brand-black"]],
      fontWeight = 800,
      borderTop = sprintf("1px solid %s", colors[["brand-orange"]]),
      borderBottom = sprintf("1px solid %s", colors[["brand-black"]])
    ),
    cellStyle = list(
      borderBottom = sprintf("1px solid %s", colors[["brand-beige-soft"]])
    ),
    rowStyle = list(
      "&:hover[aria-selected='false']" = list(
        backgroundColor = grDevices::adjustcolor(
          colors[["brand-orange"]],
          alpha.f = 0.05
        )
      )
    )
  )
}
