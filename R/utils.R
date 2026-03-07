chanwe_require_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      sprintf("Package '%s' is required for this function.", pkg),
      call. = FALSE
    )
  }
}
