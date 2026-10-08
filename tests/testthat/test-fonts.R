test_that("every brand font file ships with the package", {
  dir <- chanwe_fonts_dir()
  files <- unique(unlist(.chanwe_font_files, use.names = FALSE))

  expect_true(all(file.exists(file.path(dir, files))))
  # retired families are not bundled
  expect_length(list.files(dir, pattern = "^(Inter|Archivo|Raleway)", recursive = TRUE), 0L)
})

test_that("chanwe_load_fonts registers the brand trio from the bundled files", {
  skip_if_not_installed("systemfonts")
  dir <- chanwe_fonts_dir()

  expect_no_warning(out <- chanwe_load_fonts(path = dir))
  expect_identical(out, dir)

  reg <- systemfonts::registry_fonts()
  installed <- unique(systemfonts::system_fonts()$family)
  # every family is registered, or served by an installed font of that name
  expect_true(all(names(.chanwe_font_files) %in% c(reg$family, installed)))
  expect_false(any(c("Inter", "Inter Light", "Inter Medium") %in% reg$family))

  # the file a family name resolves to on the ragg / svglite devices
  resolved <- function(family, weight = "normal", italic = FALSE) {
    basename(systemfonts::match_fonts(family, italic = italic, weight = weight)$path)
  }
  expected <- list(
    c("Satoshi", "normal", "Satoshi-Regular.ttf"),
    c("Satoshi", "bold", "Satoshi-Bold.ttf"),
    c("Satoshi Light", "normal", "Satoshi-Light.ttf"),
    c("Schibsted Grotesk SemiBold", "normal", "SchibstedGrotesk-SemiBold.ttf"),
    c("JetBrains Mono Medium", "normal", "JetBrainsMono-Medium.ttf")
  )
  for (e in expected) {
    if (e[[1]] %in% installed) next
    expect_identical(resolved(e[[1]], e[[2]]), e[[3]], info = e[[1]])
  }
  if (!"Cormorant Garamond" %in% installed) {
    expect_identical(
      resolved("Cormorant Garamond", italic = TRUE),
      "CormorantGaramond-Italic-wght.ttf"
    )
  }
})

test_that("chanwe_load_fonts warns about missing files instead of skipping them", {
  skip_if_not_installed("systemfonts")
  dir <- tempfile("chanwer-fonts-")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  keep <- setdiff(
    unique(unlist(.chanwe_font_files, use.names = FALSE)),
    c("Satoshi-Bold.ttf", "JetBrainsMono-Thin.ttf")
  )
  file.copy(file.path(chanwe_fonts_dir(), keep), dir)

  w <- expect_warning(chanwe_load_fonts(path = dir), class = "chanwer_missing_font")
  expect_match(conditionMessage(w), "2 brand font file(s) not found", fixed = TRUE)
  expect_match(conditionMessage(w), "Satoshi-Bold.ttf", fixed = TRUE)
  expect_match(conditionMessage(w), "JetBrainsMono-Thin.ttf", fixed = TRUE)
  expect_match(conditionMessage(w), "JetBrains Mono Thin", fixed = TRUE)

  # the family with only its bold missing is still registered, bold falling
  # back to the regular file of that folder
  reg <- systemfonts::registry_fonts()
  bold <- reg$path[reg$family == "Satoshi" & reg$style == "Bold"][[1]]
  expect_identical(normalizePath(bold), normalizePath(file.path(dir, "Satoshi-Regular.ttf")))

  # restore the complete registration for the tests that follow
  suppressWarnings(chanwe_load_fonts(path = chanwe_fonts_dir()))
})

test_that("chanwe_load_fonts warns when the folder does not exist", {
  skip_if_not_installed("systemfonts")
  expect_warning(
    chanwe_load_fonts(path = file.path(tempdir(), "no-such-fonts")),
    "fonts directory not found"
  )
})

test_that("Inter as base_family is deprecated and maps to Satoshi", {
  expect_warning(th <- theme_chanwe(base_family = "Inter"), "deprecated")
  expect_identical(th$text$family, "Satoshi")
  expect_identical(th$plot.subtitle$family, "Satoshi")

  expect_warning(
    th_light <- theme_chanwe(base_family = "Inter Light"),
    "Satoshi Light"
  )
  expect_identical(th_light$text$family, "Satoshi Light")

  # any other family passes through untouched, without a warning
  expect_no_warning(th_other <- theme_chanwe(base_family = "Satoshi Medium"))
  expect_identical(th_other$text$family, "Satoshi Medium")
})
