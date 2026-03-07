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

  src_root <- ""
  src_file <- tryCatch(
    utils::getSrcFilename(chanwe_logo_path, full.names = TRUE),
    error = function(...) ""
  )
  if (nzchar(src_file)) {
    src_root <- normalizePath(
      file.path(dirname(src_file), ".."),
      winslash = "/",
      mustWork = FALSE
    )
  }

  candidates <- c(
    if (nzchar(src_root)) file.path(src_root, "inst/assets", filename),
    if (nzchar(src_root)) file.path(src_root, "assets", filename),
    if (nzchar(src_root)) file.path(src_root, "_extensions/assets", filename),
    if (nzchar(src_root)) file.path(src_root, "_extensions/chanwe-brand/assets", filename),
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

  if (isTRUE(embed) && file.exists(path)) {
    ext <- tolower(tools::file_ext(path))
    mime <- switch(
      ext,
      png = "image/png",
      jpg = "image/jpeg",
      jpeg = "image/jpeg",
      gif = "image/gif",
      svg = "image/svg+xml",
      "application/octet-stream"
    )

    bytes <- readBin(path, what = "raw", n = file.info(path)$size)
    encoded <- chanwe_base64_encode(bytes)
    if (nzchar(encoded)) {
      return(paste0("data:", mime, ";base64,", encoded))
    }
  }

  normalizePath(path, winslash = "/", mustWork = FALSE)
}

chanwe_base64_encode <- function(bytes) {
  if (!length(bytes)) {
    return("")
  }

  alphabet <- c(LETTERS, letters, as.character(0:9), "+", "/")
  values <- as.integer(bytes)
  pad <- (3L - (length(values) %% 3L)) %% 3L
  if (pad > 0L) {
    values <- c(values, rep.int(0L, pad))
  }

  triplets <- matrix(values, ncol = 3L, byrow = TRUE)
  idx1 <- bitwShiftR(triplets[, 1L], 2L)
  idx2 <- bitwOr(
    bitwShiftL(bitwAnd(triplets[, 1L], 0x03L), 4L),
    bitwShiftR(triplets[, 2L], 4L)
  )
  idx3 <- bitwOr(
    bitwShiftL(bitwAnd(triplets[, 2L], 0x0FL), 2L),
    bitwShiftR(triplets[, 3L], 6L)
  )
  idx4 <- bitwAnd(triplets[, 3L], 0x3FL)

  out <- c(
    rbind(
      alphabet[idx1 + 1L],
      alphabet[idx2 + 1L],
      alphabet[idx3 + 1L],
      alphabet[idx4 + 1L]
    )
  )

  if (pad > 0L) {
    out[(length(out) - pad + 1L):length(out)] <- "="
  }

  paste0(out, collapse = "")
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
