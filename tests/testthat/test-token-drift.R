# T8.1 drift test: chanwer writes no colour of its own. Every hex string in
# the package source is a token of the generated chanwe_tokens
# (R/brand-tokens.R, synced from chanwe-brandbook tokens.json), and every
# colour the package hands out is a token or a tint built from one.

token_hexes <- function() {
  tk <- chanwe_tokens
  toupper(c(
    unlist(tk$colors), unlist(tk$colors_dark),
    unlist(tk$plot[vapply(tk$plot, is.character, logical(1))])
  ))
}

source_dir <- function() {
  candidates <- c(
    testthat::test_path("..", "..", "R"),
    file.path(system.file(package = "chanwer"), "R")
  )
  Find(function(d) dir.exists(d) && length(list.files(d, "\\.R$")), candidates)
}

test_that("R/brand-tokens.R is the generated file, untouched", {
  dir <- source_dir()
  skip_if(is.null(dir), "package sources not available")
  head <- readLines(file.path(dir, "brand-tokens.R"), n = 1L)
  expect_match(head, "Generated from brand/tokens/tokens.json", fixed = TRUE)
})

test_that("every hex string in the source is a token", {
  dir <- source_dir()
  skip_if(is.null(dir), "package sources not available")
  allowed <- token_hexes()
  files <- setdiff(list.files(dir, "\\.R$", full.names = TRUE), file.path(dir, "brand-tokens.R"))
  offenders <- character(0)
  for (f in files) {
    pd <- utils::getParseData(parse(f, keep.source = TRUE))
    strs <- pd$text[pd$token == "STR_CONST"]
    hexes <- unlist(regmatches(strs, gregexpr("#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?\\b", strs)))
    bad <- hexes[!toupper(hexes) %in% allowed]
    if (length(bad)) offenders <- c(offenders, paste0(basename(f), ": ", unique(bad)))
  }
  expect_identical(offenders, character(0))
})

test_that("the brand group is exactly the generated colours", {
  expect_identical(chanwe_palette("brand"), unlist(chanwe_tokens$colors))
})

test_that("named groups that carry roles are pure tokens", {
  allowed <- token_hexes()
  for (g in c("brand", "chart", "slate", "focus", "semantic", "signed", "core")) {
    vals <- toupper(chanwe_palette(g))
    expect_true(all(vals %in% allowed), info = g)
  }
})

test_that("every other colour is a tint built from a token", {
  allowed <- token_hexes()
  rgb_of <- function(x) grDevices::col2rgb(substr(x, 1L, 7L))
  # a tint lies on the segment between a token and white, another token or
  # itself with alpha: check that each colour is within rounding of a mix
  # of two tokens
  base <- unique(substr(allowed, 1L, 7L))
  m <- rgb_of(base)
  is_mix <- function(hex) {
    if (toupper(substr(hex, 1L, 7L)) %in% base) return(TRUE)
    p <- rgb_of(hex)[, 1]
    for (i in seq_along(base)) {
      a <- m[, i]
      d <- m - a
      t <- colSums(d * (p - a)) / pmax(colSums(d * d), 1e-9)
      t <- pmin(pmax(t, 0), 1)
      err <- sqrt(colSums((a + d * rep(t, each = 3) - p)^2))
      if (any(err <= 1.5)) return(TRUE)
    }
    FALSE
  }
  everything <- unique(toupper(c(
    chanwe_palette("all"),
    unlist(lapply(names(.chanwe_seq_ramps()), chanwe_seq_pal)),
    .chanwe_div_ramp(), .chanwe_div_ramp(cvd = TRUE),
    chanwe_focus_colors(letters[1:3], "a"),
    unlist(chanwe_html_tokens()[vapply(chanwe_html_tokens(), is.character, logical(1))])
  )))
  everything <- everything[grepl("^#", everything)]
  not_mix <- everything[!vapply(everything, is_mix, logical(1))]
  expect_identical(not_mix, character(0))
})
