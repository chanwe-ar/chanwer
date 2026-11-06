-- The drawn orange dot that ends a main header, as on the covers and the
-- closing headlines: never a typed period. Main headers only (brand
-- decision, 2026-10-08):
--   - chanwe-brand-html: every H1;
--   - chanwe-slides: the chapter divider (`## Title {.chapter-slide}`).
-- H2 and below, topic dividers and ordinary slide titles end without it.
-- The Typst formats draw theirs in their heading rules (report and memo H1).
--
-- The dot is bound to the last word inside a `white-space: nowrap` span: as
-- a box of its own it gives the line breaker a break opportunity, and a
-- title that fills its column left the dot alone on the next line. It is a
-- span and not an `::after` for the same reason, and because Quarto appends
-- its anchor link inside the heading at runtime: an ::after would sit
-- behind it. Each format styles `.cw-title-end` and `.cw-title-dot`.
--
-- Shared by parent path, like chanwe-cards.lua: chanwe-brand lists it as
-- `../chanwe-report/chanwe-title-dot.lua`, and so does chanwe-slides.
local OPEN = '<span class="cw-title-end">'
local DOT = '<span class="cw-title-dot" aria-hidden="true"></span></span>'

local function is_main_header(el)
  if quarto.doc.is_format("revealjs") then
    return el.level == 2 and el.classes:includes("chapter-slide")
  end
  return quarto.doc.is_format("html") and el.level == 1
end

function Header(el)
  if not is_main_header(el) then
    return el
  end
  local content = el.content
  while #content > 0 and (content[#content].t == "Space" or content[#content].t == "SoftBreak") do
    content:remove(#content)
  end
  if #content == 0 then
    return el
  end
  -- Some formats list their filters twice (as an extension filter and under
  -- the format), so this can run twice: add the dot once.
  local last = content[#content]
  if last.t == "RawInline" and last.text == DOT then
    return el
  end
  content[#content] = pandoc.RawInline("html", OPEN)
  content:insert(last)
  content:insert(pandoc.RawInline("html", DOT))
  el.content = content
  return el
end
