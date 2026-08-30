function Header(el)
  if el.level == 2 then
    local text = pandoc.utils.stringify(el.content)
    if text:match("^Área:") or text:match("^Area:") then
      el.classes:insert("chanwe-area-heading")
    end
  end
  return el
end
