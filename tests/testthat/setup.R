# Fonts are registered from the chanwe-report Quarto extension, which is not
# available in the test environment. Mark them as loaded so theme_chanwe()
# does not emit a "fonts directory not found" warning on every call.
options(chanwer.fonts_loaded = TRUE)
