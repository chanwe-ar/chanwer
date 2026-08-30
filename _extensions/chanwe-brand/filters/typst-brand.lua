-- typst-brand.lua — map the chanwe-brand HTML devices onto their Typst
-- equivalents so the same source renders branded in both formats.
--   .great-quote div  -> #chanwe-great-quote[...]
--   .mark span        -> #chanwe-mark[...]
-- Both functions are defined in typst-template.typ.

if not quarto.doc.is_format("typst") then
  return {}
end

local function wrap_blocks(open, blocks, close)
  local out = pandoc.Blocks({ pandoc.RawBlock("typst", open) })
  out:extend(blocks)
  out:insert(pandoc.RawBlock("typst", close))
  return out
end

function Div(el)
  if el.classes:includes("great-quote") then
    return wrap_blocks("#chanwe-great-quote[", el.content, "]")
  end
  -- .chapter-cover is an HTML-only device; keep its body, drop the wrapper
  if el.classes:includes("chapter-cover") then
    local title = el.attributes["title"]
    local out = pandoc.Blocks({})
    if title then
      out:insert(pandoc.Header(1, pandoc.Inlines(pandoc.Str(title))))
    end
    out:extend(el.content)
    return out
  end
end

function Span(el)
  if el.classes:includes("mark") then
    local out = pandoc.Inlines({ pandoc.RawInline("typst", "#chanwe-mark[") })
    out:extend(el.content)
    out:insert(pandoc.RawInline("typst", "]"))
    return out
  end
end
