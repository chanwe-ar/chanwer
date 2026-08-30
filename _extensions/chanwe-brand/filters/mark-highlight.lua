function Span(el)
  if el.classes:includes("mark") then
    if quarto.doc.is_format("html") then
      local inlines = pandoc.Inlines({ pandoc.RawInline("html", "<mark>") })
      for _, inline in ipairs(el.content) do
        table.insert(inlines, inline)
      end
      table.insert(inlines, pandoc.RawInline("html", "</mark>"))
      return inlines
    end

    return el
  end
end
