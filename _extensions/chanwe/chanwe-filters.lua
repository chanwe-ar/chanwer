-- chanwe-filters.lua
-- Converts custom Quarto divs into raw Typst function calls.

local function attr(el, key, default)
  return el.attributes[key] or default or ""
end

local function escape_typst_str(s)
  return s:gsub('"', '\\"')
end

local function Div(el)

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
  -- ::: {.chapter-cover title="..." blurb="..."}  (alias for chanwe-chapter-divider)
  -- -------------------------------------------------------
  if el.classes:includes("chapter-cover") then
    local number  = attr(el, "number",  "01")
    local eyebrow = attr(el, "eyebrow", "")
    local title   = attr(el, "title",   "")
    local blurb   = attr(el, "blurb",   "")
    if blurb == "" then
      blurb = pandoc.utils.stringify(el.content)
    end

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
    local caption = attr(el, "caption", "")
    local source  = attr(el, "source", "")
    local color   = attr(el, "color", "dark")
    local inner   = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local call = string.format('#page-great-quote(\n  color: "%s"', color)
    if caption ~= "" then
      call = call .. string.format(',\n  caption: "%s"', escape_typst_str(caption))
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
    local caption = attr(el, "caption", "")
    local source  = attr(el, "source", "")
    local color   = attr(el, "color", "dark")
    local inner   = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    local call = string.format('#inset-great-quote(\n  color: "%s"', color)
    if caption ~= "" then
      call = call .. string.format(',\n  caption: "%s"', escape_typst_str(caption))
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
  -- :::: {.great-findings-grid color="light"}
  --   ::: {.great-findings number="01" title="..."} ... :::
  -- ::::
  -- -------------------------------------------------------
  if el.classes:includes("great-findings-grid") then
    local color = attr(el, "color", "white")
    local parts = {}

    for _, block in ipairs(el.content) do
      if block.t == "Div" and block.classes:includes("great-findings") then
        local number = attr(block, "number", "01")
        local title  = attr(block, "title",  "")
        local inner  = pandoc.write(pandoc.Pandoc(pandoc.Blocks(block.content)), "typst")

        table.insert(parts, string.format(
          '#great-findings-item(\n  number: "%s",\n  title: "%s",\n)[\n%s\n]',
          escape_typst_str(number),
          escape_typst_str(title),
          inner
        ))
      end
    end

    local sep = "\n#line(length: 100%, stroke: 0.5pt + _t.border)\n"
    local call = string.format('#great-findings-grid(color: "%s")[\n', escape_typst_str(color))
    call = call .. table.concat(parts, sep)
    call = call .. "\n]"
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
  -- ::: {.chanwe-executive-summary eyebrow="..." title="..." takeaway="..."
  --       left-label-1="AREA" left-value-1="Research" left-sub-1="Economia & Finanzas"
  --       left-label-2="AUTOR" left-value-2="..." left-sub-2="..."}
  -- Renders a full standalone page identical to the abstract layout.
  -- meta-rows are pulled from doc state unless left-label-* attrs are set.
  -- -------------------------------------------------------
  if el.classes:includes("chanwe-executive-summary") then
    local eyebrow  = attr(el, "eyebrow",  "Executive Summary")
    local title    = attr(el, "title",    "")
    local takeaway = attr(el, "takeaway", "")
    local color    = attr(el, "color",    "")
    local inner    = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")

    -- build custom meta array if any left-label-N attrs are set
    local meta_entries = {}
    for i = 1, 3 do
      local lbl = attr(el, "left-label-" .. i, "")
      local val = attr(el, "left-value-" .. i, "")
      local sub = attr(el, "left-sub-"   .. i, "")
      if lbl ~= "" then
        if sub ~= "" then
          table.insert(meta_entries, string.format('("%s", "%s", "%s")',
            escape_typst_str(lbl), escape_typst_str(val), escape_typst_str(sub)))
        else
          table.insert(meta_entries, string.format('("%s", "%s")',
            escape_typst_str(lbl), escape_typst_str(val)))
        end
      end
    end

    local call = "#chanwe-exec-summary-page(\n"
    call = call .. string.format('  eyebrow: "%s",\n', escape_typst_str(eyebrow))
    if title ~= "" then
      call = call .. string.format('  title: [%s],\n', escape_typst_str(title))
    end
    if takeaway ~= "" then
      call = call .. string.format('  takeaway: "%s",\n', escape_typst_str(takeaway))
    end
    if color ~= "" then
      call = call .. string.format('  color: "%s",\n', escape_typst_str(color))
    end
    if #meta_entries > 0 then
      call = call .. "  meta: (" .. table.concat(meta_entries, ", ") .. ",),\n"
    end
    call = call .. ")[\n" .. inner .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- :::: {.zone-highlight color="beige"}  ...  ::::
  -- -------------------------------------------------------
  if el.classes:includes("zone-highlight") then
    local color  = attr(el, "color",  "white")
    local margin = attr(el, "margin", "")
    local above  = attr(el, "above",  "")
    local below  = attr(el, "below",  "")
    local inner  = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")
    local call = string.format('#zone-highlight(color: "%s"', escape_typst_str(color))
    if margin ~= "" then
      call = call .. string.format(", margin: %smm", escape_typst_str(margin))
    end
    if above ~= "" then
      call = call .. string.format(", above: %smm", escape_typst_str(above))
    end
    if below ~= "" then
      call = call .. string.format(", below: %smm", escape_typst_str(below))
    end
    call = call .. ")[\n" .. inner .. "\n]"
    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- :::: {.chanwe-double-exec-summary}
  --   ::: {.exec-top  eyebrow="…" title="…" takeaway="…" color="beige"
  --         left-label-1="…" left-value-1="…" left-sub-1="…" (up to 3)}
  --   ::: {.exec-bottom …}
  -- ::::
  -- -------------------------------------------------------
  if el.classes:includes("chanwe-double-exec-summary") then
    local top_div, bot_div = nil, nil
    for _, block in ipairs(el.content) do
      if block.t == "Div" then
        if block.classes:includes("exec-top") then
          top_div = block
        elseif block.classes:includes("exec-bottom") then
          bot_div = block
        end
      end
    end

    -- Returns { args = string, content = pandoc.Blocks }
    -- Nested ::: {.driver dir="…" title="…" desc="…" tag="…" tag-color="…"} :::
    -- divs are extracted from content and stripped from the body.
    -- Falls back to flat driver-N-* attrs when no nested driver divs are found.
    local function half_args(div, prefix)
      if div == nil then return { args = "", content = pandoc.Blocks({}) } end
      local args     = ""
      local eyebrow  = attr(div, "eyebrow",  "Executive Summary")
      local title    = attr(div, "title",    "")
      local takeaway = attr(div, "takeaway", "")
      local color    = attr(div, "color",    "")

      args = args .. string.format('  %s-eyebrow: "%s",\n',
        prefix, escape_typst_str(eyebrow))
      if title ~= "" then
        args = args .. string.format('  %s-title: [%s],\n',
          prefix, escape_typst_str(title))
      end
      if takeaway ~= "" then
        args = args .. string.format('  %s-takeaway: "%s",\n',
          prefix, escape_typst_str(takeaway))
      end
      if color ~= "" then
        args = args .. string.format('  %s-color: "%s",\n',
          prefix, escape_typst_str(color))
      end

      local meta_entries = {}
      for i = 1, 3 do
        local lbl = attr(div, "left-label-" .. i, "")
        local val = attr(div, "left-value-" .. i, "")
        local sub = attr(div, "left-sub-"   .. i, "")
        if lbl ~= "" then
          if sub ~= "" then
            table.insert(meta_entries, string.format('("%s", "%s", "%s")',
              escape_typst_str(lbl), escape_typst_str(val), escape_typst_str(sub)))
          else
            table.insert(meta_entries, string.format('("%s", "%s", none)',
              escape_typst_str(lbl), escape_typst_str(val)))
          end
        end
      end
      if #meta_entries > 0 then
        args = args .. string.format('  %s-meta: (%s,),\n',
          prefix, table.concat(meta_entries, ", "))
      end

      -- Status section (label, hero word, kind, value, single meta pair)
      local status_label = attr(div, "status-label", "")
      if status_label ~= "" then
        args = args .. string.format('  %s-status-label: "%s",\n',
          prefix, escape_typst_str(status_label))
      end
      local status_hero = attr(div, "status-hero", "")
      if status_hero ~= "" then
        args = args .. string.format('  %s-status-hero: "%s",\n',
          prefix, escape_typst_str(status_hero))
      end
      local status_kind = attr(div, "status-kind", "")
      if status_kind ~= "" then
        args = args .. string.format('  %s-status-kind: "%s",\n',
          prefix, escape_typst_str(status_kind))
      end
      local status_value = attr(div, "status-value", "")
      if status_value ~= "" then
        args = args .. string.format('  %s-status-value: %s,\n', prefix, status_value)
      end
      local sml = attr(div, "status-meta-label", "")
      local smv = attr(div, "status-meta-value", "")
      if sml ~= "" then
        args = args .. string.format('  %s-status-meta-label: "%s",\n',
          prefix, escape_typst_str(sml))
        args = args .. string.format('  %s-status-meta-value: "%s",\n',
          prefix, escape_typst_str(smv))
      end

      -- Driver list — collect nested ::: {.driver} ::: divs first,
      -- fall back to flat driver-N-* attrs when none found.
      local driver_entries = {}
      local body_list = {}

      for _, block in ipairs(div.content) do
        if block.t == "Div" and block.classes:includes("driver")
            and #driver_entries < 3 then
          local dtitle = attr(block, "title", "")
          if dtitle ~= "" then
            local dir    = attr(block, "dir",       "neutral")
            local ddesc  = attr(block, "desc",      "")
            local dtag   = attr(block, "tag",       "")
            local dtag_c = attr(block, "tag-color", "")
            table.insert(driver_entries, string.format(
              '    ("%s", "%s", "%s", "%s", "%s")',
              escape_typst_str(dir),   escape_typst_str(dtitle),
              escape_typst_str(ddesc), escape_typst_str(dtag),
              escape_typst_str(dtag_c)))
          end
          -- driver divs are not added to body_list (stripped from body)
        else
          table.insert(body_list, block)
        end
      end

      -- Fall back to flat driver-N-* attrs when no nested drivers found
      if #driver_entries == 0 then
        body_list = {}
        for _, block in ipairs(div.content) do
          table.insert(body_list, block)
        end
        for i = 1, 3 do
          local dtitle = attr(div, "driver-" .. i .. "-title", "")
          if dtitle ~= "" then
            local dir    = attr(div, "driver-" .. i .. "-dir",       "neutral")
            local ddesc  = attr(div, "driver-" .. i .. "-desc",      "")
            local dtag   = attr(div, "driver-" .. i .. "-tag",       "")
            local dtag_c = attr(div, "driver-" .. i .. "-tag-color", "")
            table.insert(driver_entries, string.format(
              '    ("%s", "%s", "%s", "%s", "%s")',
              escape_typst_str(dir),   escape_typst_str(dtitle),
              escape_typst_str(ddesc), escape_typst_str(dtag),
              escape_typst_str(dtag_c)))
          end
        end
      end

      if #driver_entries > 0 then
        args = args .. string.format('  %s-drivers: (\n%s,\n  ),\n',
          prefix, table.concat(driver_entries, ",\n"))
      end

      local drivers_label = attr(div, "drivers-label", "")
      if drivers_label ~= "" then
        args = args .. string.format('  %s-drivers-label: "%s",\n',
          prefix, escape_typst_str(drivers_label))
      end

      return { args = args, content = pandoc.Blocks(body_list) }
    end

    local top_result = half_args(top_div, "top")
    local bot_result = half_args(bot_div, "bot")

    local top_inner = pandoc.write(pandoc.Pandoc(top_result.content), "typst")
    local bot_inner = pandoc.write(pandoc.Pandoc(bot_result.content), "typst")

    local call = "#chanwe-double-exec-summary(\n"
    call = call .. top_result.args
    call = call .. bot_result.args
    call = call .. ")[\n" .. top_inner .. "\n][\n" .. bot_inner .. "\n]"

    return pandoc.RawBlock("typst", call)
  end

  -- -------------------------------------------------------
  -- ::: {.fig-border}
  -- -------------------------------------------------------
  if el.classes:includes("fig-border") then
    local inner = pandoc.write(pandoc.Pandoc(pandoc.Blocks(el.content)), "typst")
    return pandoc.RawBlock("typst", "#fig-border[\n" .. inner .. "\n]")
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

return {{traverse = "topdown", Div = Div}}
