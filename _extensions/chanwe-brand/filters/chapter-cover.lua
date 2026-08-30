local function append_blocks(target, source)
  for _, block in ipairs(source) do
    table.insert(target, block)
  end
end

local function escaped_css_url(path)
  return string.gsub(path, "'", "\\'")
end

local default_cover_image = "_extensions/chanwe-brand/assets/bg_mountains.jpg"

local function background_image_style(path)
  return "background-image: url('" .. escaped_css_url(path) .. "');"
end

local function cover_media_attr(path)
  if path == default_cover_image then
    return pandoc.Attr("", { "chapter-cover-media", "chapter-cover-media-default" })
  end

  return pandoc.Attr("", { "chapter-cover-media" }, {
    style = background_image_style(path)
  })
end

function Div(el)
  if not el.classes:includes("chapter-cover") then
    return nil
  end

  local title = el.attributes["title"] or ""
  local img = el.attributes["img"] or default_cover_image

  if quarto.doc.is_format("html") then
    local text_blocks = pandoc.Blocks({})
    if title ~= "" then
      table.insert(
        text_blocks,
        pandoc.Div(
          pandoc.Blocks({ pandoc.Plain(pandoc.Inlines({ pandoc.Str(title) })) }),
          pandoc.Attr("", { "chapter-cover-title" })
        )
      )
    end
    append_blocks(text_blocks, el.content)

    local cover_blocks = pandoc.Blocks({
      pandoc.Div(
        pandoc.Blocks({}),
        cover_media_attr(img)
      ),
      pandoc.Div(text_blocks, pandoc.Attr("", { "chapter-cover-content" }))
    })

    return pandoc.Div(cover_blocks, pandoc.Attr("", { "chapter-cover" }))
  end

  local text_blocks = pandoc.Blocks({})
  if title ~= "" then
    table.insert(text_blocks, pandoc.Header(2, pandoc.Inlines({ pandoc.Str(title) })))
  end
  append_blocks(text_blocks, el.content)

  return text_blocks
end
