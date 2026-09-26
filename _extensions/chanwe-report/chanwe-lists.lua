-- chanwe-lists.lua — markdown task lists (`- [ ]` / `- [x]`).
--
-- Shared by the report and the memo; both list it before their own filter.
-- Pandoc represents a task item as a bullet item whose first inline is the
-- glyph ☐ or ☒. A bullet list made only of such items becomes
-- `#task-list(((done, [body]), …))` from `chanwe-lists.typ`, so the box is
-- the marker and no bullet is drawn beside it. Any other list is left alone.

local function task_state(item)
  local first = item[1]
  if first == nil or (first.t ~= "Plain" and first.t ~= "Para") then return nil end
  local s = first.content[1]
  if s == nil or s.t ~= "Str" then return nil end
  if s.text == "☐" then return false end
  if s.text == "☒" then return true end
  return nil
end

local function BulletList(el)
  local items = {}
  for _, item in ipairs(el.content) do
    local done = task_state(item)
    if done == nil then return nil end
    local first = item[1]
    table.remove(first.content, 1)
    if first.content[1] and first.content[1].t == "Space" then
      table.remove(first.content, 1)
    end
    items[#items + 1] = "(" .. tostring(done) .. ", [\n"
      .. pandoc.write(pandoc.Pandoc(item), "typst") .. "\n])"
  end
  if #items == 0 then return nil end
  return pandoc.RawBlock("typst", "#task-list((\n" .. table.concat(items, ",\n") .. ",\n))")
end

return {{BulletList = BulletList}}
