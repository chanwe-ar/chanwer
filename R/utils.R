chanwe_require_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      sprintf("Package '%s' is required for this function.", pkg),
      call. = FALSE
    )
  }
}

chanwe_logo_path <- function(filename = "Logo_Color1.png") {
  installed <- system.file("assets", filename, package = "chanwer")
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  candidates <- c(
    file.path("inst/assets", filename),
    file.path("assets", filename),
    file.path("_extensions/assets", filename),
    file.path("_extensions/chanwe-brand/assets", filename)
  )
  existing <- candidates[file.exists(candidates)]

  if (!length(existing)) {
    return("")
  }

  normalizePath(existing[[1]], winslash = "/", mustWork = FALSE)
}

chanwe_logo_src <- function(path, embed = TRUE) {
  if (!nzchar(path)) {
    return("")
  }

  if (isTRUE(embed) && requireNamespace("knitr", quietly = TRUE)) {
    return(knitr::image_uri(path))
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

chanwe_png_dims <- function(path) {
  if (!nzchar(path) || !file.exists(path)) {
    return(NULL)
  }

  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  bytes <- readBin(con, what = "raw", n = 24)
  if (length(bytes) < 24) {
    return(NULL)
  }

  png_sig <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  if (!all(bytes[1:8] == png_sig)) {
    return(NULL)
  }
  if (!identical(rawToChar(bytes[13:16]), "IHDR")) {
    return(NULL)
  }

  width <- readBin(bytes[17:20], what = "integer", n = 1, size = 4, endian = "big")
  height <- readBin(bytes[21:24], what = "integer", n = 1, size = 4, endian = "big")
  if (is.na(width) || is.na(height) || width <= 0 || height <= 0) {
    return(NULL)
  }

  list(width = width, height = height)
}
