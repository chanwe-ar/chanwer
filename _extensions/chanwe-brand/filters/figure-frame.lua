local function slot(el, primary, alias)
  local value = el.attributes[primary]
  if (value == nil or value == "") and alias ~= nil then
    value = el.attributes[alias]
  end
  return value or ""
end

local function markdown_inlines(value)
  if value == "" then
    return pandoc.Inlines({})
  end

  local parsed = pandoc.read(value, "markdown")
  if #parsed.blocks > 0 and
      (parsed.blocks[1].t == "Plain" or parsed.blocks[1].t == "Para") then
    return parsed.blocks[1].content
  end

  return pandoc.Inlines({ pandoc.Str(value) })
end

local function text_div(value, class_name)
  return pandoc.Div(
    pandoc.Blocks({ pandoc.Plain(markdown_inlines(value)) }),
    pandoc.Attr("", { class_name })
  )
end

local function top_left_div(value)
  local content = pandoc.Inlines({
    pandoc.Span(pandoc.Inlines({}), pandoc.Attr("", { "chanwe-figure-footer-dash" })),
    pandoc.Span(markdown_inlines(value), pandoc.Attr("", { "chanwe-figure-footer-label" }))
  })

  return pandoc.Div(
    pandoc.Blocks({ pandoc.Plain(content) }),
    pandoc.Attr("", { "chanwe-figure-footer-left" })
  )
end

local component_attributes = {
  ["top-left"] = true,
  ["top-right"] = true,
  ["bottom-left"] = true,
  ["bottom-right"] = true,
  ["footer-left"] = true,
  ["footer-right"] = true,
  ["alt-footer-left"] = true,
  ["alt-footer-right"] = true,
}

function Div(el)
  if not el.classes:includes("chanwe-figure-frame") then
    return nil
  end

  if not quarto.doc.is_format("html") then
    return el.content
  end

  local top_left = slot(el, "top-left", "footer-left")
  local top_right = slot(el, "top-right", "footer-right")
  local bottom_left = slot(el, "bottom-left", "alt-footer-left")
  local bottom_right = slot(el, "bottom-right", "alt-footer-right")

  local frame_blocks = pandoc.Blocks({})

  if top_left ~= "" or top_right ~= "" then
    table.insert(
      frame_blocks,
      pandoc.Div(
        pandoc.Blocks({
          top_left_div(top_left),
          text_div(top_right, "chanwe-figure-footer-right")
        }),
        pandoc.Attr("", { "chanwe-figure-footer" })
      )
    )
  end

  table.insert(
    frame_blocks,
    pandoc.Div(el.content, pandoc.Attr("", { "chanwe-figure-body" }))
  )

  if bottom_left ~= "" or bottom_right ~= "" then
    table.insert(
      frame_blocks,
      pandoc.Div(
        pandoc.Blocks({
          text_div(bottom_left, "chanwe-figure-alt-footer-left"),
          text_div(bottom_right, "chanwe-figure-alt-footer-right")
        }),
        pandoc.Attr("", { "chanwe-figure-alt-footer" })
      )
    )
  end

  local classes = { "chanwe-figure" }
  for _, class_name in ipairs(el.classes) do
    if class_name ~= "chanwe-figure-frame" then
      table.insert(classes, class_name)
    end
  end

  local attributes = {}
  for key, value in pairs(el.attributes) do
    if not component_attributes[key] then
      attributes[key] = value
    end
  end

  return pandoc.Div(frame_blocks, pandoc.Attr(el.identifier, classes, attributes))
end
