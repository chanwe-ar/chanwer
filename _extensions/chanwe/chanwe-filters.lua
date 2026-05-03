-- chanwe-filters.lua
-- Converts custom Quarto divs into raw Typst function calls.

local function attr(el, key, default)
  return el.attributes[key] or default or ""
end

local function escape_typst_str(s)
  return s:gsub('"', '\\"')
end

function Div(el)

  -- -------------------------------------------------------
  -- ::: {.chanwe-chapter-divider number="II" ...}
  -- -------------------------------------------------------
  if el.classes:includes("chanwe-chapter-divider") then
    local number  = attr(el, "number",  "01")
    local eyebrow = attr(el, "eyebrow", "")
    local title   = attr(el, "title",   "")
    local blurb   = attr(el, "blurb",   "")

    -- Emit metadata first (top-level, so query(<chanwe-part>) finds it reliably)
    local meta_raw = string.format(
      '#metadata((number: "%s", title: "%s", eyebrow: "%s")) <chanwe-part>',
      escape_typst_str(number),
      escape_typst_str(title),
      escape_typst_str(eyebrow)
    )
    local div_raw = string.format(
      '#chanwe-chapter-divider(\n  number: "%s",\n  eyebrow: "%s",\n  title: "%s",\n  blurb: "%s",\n)',
      escape_typst_str(number),
      escape_typst_str(eyebrow),
      escape_typst_str(title),
      escape_typst_str(blurb)
    )
    return {
      pandoc.RawBlock("typst", meta_raw),
      pandoc.RawBlock("typst", div_raw),
    }
  end

  -- -------------------------------------------------------
  -- ::: {.page-great-quote attribution="Name" source="Work"}
  -- -------------------------------------------------------
  if el.classes:includes("page-great-quote") then
    local attribution = attr(el, "attribution", "")
    local source      = attr(el, "source", "")
    local color       = attr(el, "color", "dark")
    local inner       = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local call = string.format('#page-great-quote(\n  color: "%s"', color)
    if attribution ~= "" then
      call = call .. string.format(',\n  attribution: "%s"', escape_typst_str(attribution))
    end
    if source ~= "" then
      call = call .. string.format(',\n  source: "%s"', escape_typst_str(source))
    end
    call = call .. "\n)[\n" .. inner .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.inset-great-quote attribution="Name" color="light"}
  -- -------------------------------------------------------
  if el.classes:includes("inset-great-quote") then
    local attribution = attr(el, "attribution", "")
    local source      = attr(el, "source", "")
    local color       = attr(el, "color", "dark")
    local inner       = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local call = string.format('#inset-great-quote(\n  color: "%s"', color)
    if attribution ~= "" then
      call = call .. string.format(',\n  attribution: "%s"', escape_typst_str(attribution))
    end
    if source ~= "" then
      call = call .. string.format(',\n  source: "%s"', escape_typst_str(source))
    end
    call = call .. "\n)[\n" .. inner .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.inset-great-figure eyebrow="..." title="..." layout="center" position="right" color="dark" source="..."}
  -- text paragraphs first, then a {=typst} raw block OR an R code chunk (last block = figure)
  -- -------------------------------------------------------
  if el.classes:includes("inset-great-figure") then
    local eyebrow  = attr(el, "eyebrow", "")
    local title    = attr(el, "title", "")
    local source   = attr(el, "source", "")
    local layout   = attr(el, "layout", "center")
    local position = attr(el, "position", "right")
    local color    = attr(el, "color", "dark")

    -- Collect all blocks; last block = figure (raw typst or R-rendered image)
    local all_blocks = {}
    for _, block in ipairs(el.content) do
      table.insert(all_blocks, block)
    end

    local plot_typst = ""
    local text_blocks = {}

    if #all_blocks > 0 then
      local last = all_blocks[#all_blocks]
      -- Use the last block as the figure
      if last.t == "RawBlock" and last.format == "typst" then
        plot_typst = last.text
      else
        plot_typst = pandoc.write(pandoc.Pandoc(pandoc.Blocks({last})), "typst")
      end
      for i = 1, #all_blocks - 1 do
        table.insert(text_blocks, all_blocks[i])
      end
    end

    local text_typst = pandoc.write(pandoc.Pandoc(pandoc.Blocks(text_blocks)), "typst")

    local call = "#inset-great-figure(\n"
    if eyebrow ~= "" then
      call = call .. string.format('  eyebrow: "%s",\n', escape_typst_str(eyebrow))
    end
    if title ~= "" then
      call = call .. string.format('  title: "%s",\n', escape_typst_str(title))
    end
    call = call .. string.format('  color: "%s",\n', color)
    call = call .. string.format('  layout: "%s",\n', layout)
    call = call .. string.format('  position: "%s",\n', position)
    if source ~= "" then
      call = call .. string.format('  source: "%s",\n', escape_typst_str(source))
    end
    call = call .. "  caption: [\n" .. text_typst .. "\n  ],\n"
    call = call .. ")[\n" .. plot_typst .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- :::: {.kpi-grid cols="4"}
  --   ::: {.kpi title="..." main="..." unit="..." ...} :::
  -- ::::
  -- -------------------------------------------------------
  if el.classes:includes("kpi-grid") then
    local cols = attr(el, "cols", "4")
    local rows = attr(el, "rows", "")
    local cards = {}

    for _, block in ipairs(el.content) do
      if block.t == "Div" and block.classes:includes("kpi") then
        local title           = attr(block, "title",           "")
        local main_val        = attr(block, "main",            "")
        local prefix          = attr(block, "prefix",          "")
        local unit            = attr(block, "unit",            "")
        local main_color      = attr(block, "main-color",      "ink")
        local secondary       = attr(block, "secondary",       "")
        local secondary_color = attr(block, "secondary-color", "primary")
        local direction       = attr(block, "direction",       "none")

        local card = string.format(
          'kpi-card(\n    title: "%s",\n    main: "%s",\n    prefix: "%s",\n    unit: "%s",\n    main-color: "%s",\n    secondary: "%s",\n    secondary-color: "%s",\n    direction: "%s",\n  )',
          escape_typst_str(title),
          escape_typst_str(main_val),
          escape_typst_str(prefix),
          escape_typst_str(unit),
          escape_typst_str(main_color),
          escape_typst_str(secondary),
          escape_typst_str(secondary_color),
          escape_typst_str(direction)
        )
        table.insert(cards, card)
      end
    end

    local rows_arg = ""
    if rows ~= "" then
      rows_arg = string.format(", rows: %s", rows)
    end
    local call = string.format('#kpi-grid(cols: %s%s, (\n  ', cols, rows_arg)
    call = call .. table.concat(cards, ",\n  ")
    call = call .. "\n))"
    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.great-findings}
  -- **Bold title** → item title; following paragraphs → item body
  -- -------------------------------------------------------
  if el.classes:includes("great-findings") then
    local number = attr(el, "number", "01")
    local title  = attr(el, "title",  "")
    local inner  = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local color  = attr(el, "color",  "white")
    local call = string.format(
      '#great-findings(\n  number: "%s",\n  title: "%s",\n  color: "%s",\n)[\n%s\n]',
      escape_typst_str(number),
      escape_typst_str(title),
      escape_typst_str(color),
      inner
    )
    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.inset-great-summary eyebrow="Executive Summary" title="..."}
  -- -------------------------------------------------------
  if el.classes:includes("inset-great-summary") then
    local eyebrow = attr(el, "eyebrow", "Executive Summary")
    local title   = attr(el, "title",   "")
    local color   = attr(el, "color",   "white")
    local inner   = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local call = "#inset-great-summary(\n"
    call = call .. string.format('  eyebrow: "%s",\n', escape_typst_str(eyebrow))
    if title ~= "" then
      call = call .. string.format('  title: "%s",\n', escape_typst_str(title))
    end
    call = call .. string.format('  color: "%s",\n', escape_typst_str(color))
    call = call .. ")[\n" .. inner .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.callout kind="note" title="Label"}
  -- -------------------------------------------------------
  if el.classes:includes("chanwe-callout") then
    local kind    = attr(el, "kind",    "note")
    local title   = attr(el, "title",   "")
    local eyebrow = attr(el, "eyebrow", "")

    local body_typst = "#callout(kind: \"" .. escape_typst_str(kind) .. "\""
    if eyebrow ~= "" then
      body_typst = body_typst .. ", eyebrow: \"" .. escape_typst_str(eyebrow) .. "\""
    end
    if title ~= "" then
      body_typst = body_typst .. ", title: \"" .. escape_typst_str(title) .. "\""
    end
    body_typst = body_typst .. ")[\n"

    local inner = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")
    body_typst = body_typst .. inner .. "\n]"

    return pandoc.RawBlock("typst", body_typst)
  end

end
