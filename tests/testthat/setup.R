# The brand fonts ship with the package (inst/fonts), so theme_chanwe()
# registers them on its first call without any warning. Tests that exercise
# chanwe_load_fonts() pass `path` explicitly, which bypasses the
# once-per-session cache.
