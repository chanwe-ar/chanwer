function Div(el)
  if el.classes:includes("chapter-cover") then
    local title = el.attributes["title"] or ""
    local img = el.attributes["img"] or ""

    -- Get body text from div content
    local body = ""
    if #el.content > 0 then
      body = pandoc.utils.stringify(el)
    end

    -- Build typst function call
    local args = string.format("title: [%s]", title)

    if body ~= "" then
      args = args .. string.format(", body: [%s]", body)
    end

    if img ~= "" then
      args = args .. string.format(', img: "%s"', img)
    end

    return pandoc.RawBlock("typst", string.format("#chapter-cover(%s)", args))
  end
end
