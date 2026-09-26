-- chanwe-cards.lua — `.card-highlight` and `.card-highlight-set` Divs.
--
-- Shared by the report and the memo: both list this filter and both include
-- `chanwe-cards.typ`, which defines the Typst helpers the calls below use.
--
--   ::: {.card-highlight}                        wide, body only
--   ::: {.card-highlight eyebrow="…" title="…" accent="primary" color="light"}
--   ::: {.card-highlight-set color="light" cols="2"}
--     ::: {.card-highlight eyebrow="…" title="…"}  …  :::
--   :::
--
-- `accent` (the bar) takes primary · light · dark, like `color` (the panel),
-- which takes white · light · dark · primary. Runs top-down so a set consumes its own cards.

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

local function card_args(el)
  local parts = {}
  local eyebrow = attr(el, "eyebrow")
  if eyebrow then parts[#parts + 1] = "eyebrow: [" .. inline_md(eyebrow) .. "]" end
  local title = attr(el, "title")
  if title then parts[#parts + 1] = "title: [" .. inline_md(title) .. "]" end
  local accent = attr(el, "accent")
  if accent then parts[#parts + 1] = 'accent: "' .. accent .. '"' end
  return parts
end

local function Div(el)
  if el.classes:includes("card-highlight-set") then
    local color = attr(el, "color") or "light"
    local cols = attr(el, "cols")
    local items = {}
    for _, b in ipairs(el.content) do
      if b.t == "Div" and b.classes:includes("card-highlight") then
        local parts = card_args(b)
        parts[#parts + 1] = "body: [\n" .. typst_blocks(b.content) .. "\n]"
        items[#items + 1] = "(" .. table.concat(parts, ", ") .. ")"
      end
    end
    local call = '#card-highlight-set(color: "' .. color .. '", '
    if cols then call = call .. "cols: " .. cols .. ", " end
    call = call .. "(\n" .. table.concat(items, ",\n") .. ",\n))"
    return pandoc.RawBlock("typst", call)
  elseif el.classes:includes("card-highlight") then
    local parts = card_args(el)
    parts[#parts + 1] = 'color: "' .. (attr(el, "color") or "light") .. '"'
    local call = "#card-highlight(" .. table.concat(parts, ", ") .. ")[\n"
      .. typst_blocks(el.content) .. "\n]"
    return pandoc.RawBlock("typst", call)
  end
end

return {{traverse = "topdown", Div = Div}}
