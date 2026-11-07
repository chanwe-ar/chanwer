-- chanwe-site.lua — the blocks of chanwe.ar's home, as Divs.
--
--   ::: {.chapter-label number="07"}          Resultados                    :::
--   ::: {.statement-rows}   one paragraph per row, numbered on its own      :::
--   ::: {.proof-card figure="x2" label="Margen por SKU" kicker="Retail" title="…"} body :::
--   ::: {.photo-hero kicker="…" title="…" lede="…"}                         :::
--   ::: {.giant-word caption="…"}                                           :::
--
-- Shared by the report, the book and chanwe-brand-html. Typst calls the helpers
-- in chanwe-site.typ; HTML keeps a Div that chanwe-brand-rules.scss draws.

local function attr(el, key)
  local v = el.attributes[key]
  if v == nil or v == "" then return nil end
  return v
end

local function inline_md(value)
  local out = pandoc.write(pandoc.read(value, "markdown"), "typst")
  return (out:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function typst_blocks(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), "typst")
end

local function typst_string(value)
  return '"' .. value:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function arg(parts, name, value)
  if value then parts[#parts + 1] = name .. ": [" .. inline_md(value) .. "]" end
end

local function inlines(value)
  return pandoc.read(value, "markdown").blocks[1].content
end

local function html_text(class, value)
  return pandoc.Div({ pandoc.Plain(inlines(value)) }, pandoc.Attr("", { class }))
end

local function as_typst(el)
  if el.classes:includes("chapter-label") then
    local n = attr(el, "number")
    return pandoc.RawBlock("typst", "#chanwe-chapter-label(" ..
      (n and ("number: " .. typst_string(n)) or "") .. ")[" .. typst_blocks(el.content) .. "]")
  elseif el.classes:includes("statement-rows") then
    local items = {}
    for _, b in ipairs(el.content) do
      items[#items + 1] = "[" .. typst_blocks({ b }) .. "]"
    end
    return pandoc.RawBlock("typst", "#chanwe-statement-rows((" .. table.concat(items, ",\n") .. ",))")
  elseif el.classes:includes("proof-card") then
    local parts = {}
    arg(parts, "figure", attr(el, "figure"))
    arg(parts, "label", attr(el, "label"))
    arg(parts, "kicker", attr(el, "kicker"))
    arg(parts, "title", attr(el, "title"))
    return pandoc.RawBlock("typst", "#chanwe-proof-card(" .. table.concat(parts, ", ") .. ")[" .. typst_blocks(el.content) .. "]")
  elseif el.classes:includes("photo-hero") then
    local parts = {}
    local kicker = attr(el, "kicker")
    if kicker then parts[#parts + 1] = "kicker: " .. typst_string(kicker) end
    arg(parts, "title", attr(el, "title"))
    arg(parts, "lede", attr(el, "lede"))
    return pandoc.RawBlock("typst", "#chanwe-photo-hero(" .. table.concat(parts, ", ") .. ")")
  elseif el.classes:includes("giant-word") then
    local parts = {}
    local caption = attr(el, "caption")
    if caption then parts[#parts + 1] = "caption: " .. typst_string(caption) end
    return pandoc.RawBlock("typst", "#chanwe-giant-word(" .. table.concat(parts, ", ") .. ")")
  end
end

local function as_html(el)
  if el.classes:includes("statement-rows") then
    local rows = {}
    for i, b in ipairs(el.content) do
      local n = (i < 10 and "0" or "") .. tostring(i)
      rows[#rows + 1] = pandoc.Div({
        pandoc.RawBlock("html", '<div class="cw-statement__n" aria-hidden="true">' .. n .. "</div>"),
        pandoc.Div({ b }, pandoc.Attr("", { "cw-statement__text" })),
      }, pandoc.Attr("", { "cw-statement" }))
    end
    el.content = rows
    return el
  elseif el.classes:includes("chapter-label") then
    local n = attr(el, "number")
    if n then
      table.insert(el.content, 1, pandoc.RawBlock("html", '<span class="cw-chapter-label__n">/ ' .. pandoc.utils.stringify(n) .. "</span>"))
    end
    return el
  elseif el.classes:includes("proof-card") then
    local left, right = {}, {}
    if attr(el, "figure") then left[#left + 1] = html_text("cw-proof__figure", attr(el, "figure")) end
    if attr(el, "label") then left[#left + 1] = html_text("cw-proof__label", attr(el, "label")) end
    if attr(el, "kicker") then right[#right + 1] = html_text("cw-proof__label", attr(el, "kicker")) end
    if attr(el, "title") then right[#right + 1] = html_text("cw-proof__title", attr(el, "title")) end
    for _, b in ipairs(el.content) do right[#right + 1] = b end
    el.content = { pandoc.Div(left, pandoc.Attr("", { "cw-proof__side" })), pandoc.Div(right, pandoc.Attr("", { "cw-proof__main" })) }
    return el
  elseif el.classes:includes("photo-hero") then
    local c = {}
    if attr(el, "kicker") then c[#c + 1] = html_text("cw-hero__pill", attr(el, "kicker")) end
    if attr(el, "title") then
      -- The dot is inline with the last word, so no space opens before it.
      local title = inlines(attr(el, "title"))
      title:insert(pandoc.RawInline("html", '<span class="cw-giant__dot" aria-hidden="true"></span>'))
      c[#c + 1] = pandoc.Div({ pandoc.Plain(title) }, pandoc.Attr("", { "cw-hero__title" }))
    end
    if attr(el, "lede") then c[#c + 1] = html_text("cw-hero__lede", attr(el, "lede")) end
    el.content = c
    return el
  elseif el.classes:includes("giant-word") then
    local c = { pandoc.RawBlock("html", '<div class="cw-giant__word" role="img" aria-label="chanwe"></div>') }
    if attr(el, "caption") then c[#c + 1] = html_text("cw-proof__label", attr(el, "caption")) end
    el.content = c
    return el
  end
end

return {
  {
    Div = function(el)
      if quarto.doc.is_format("typst") then return as_typst(el) end
      if quarto.doc.is_format("html") then
        -- The HTML rewrite is not idempotent, so a second pass must not redo it.
        if el.attributes["data-cw-site"] then return nil end
        local out = as_html(el)
        if out then out.attributes["data-cw-site"] = "1" end
        return out
      end
    end,
  },
}
