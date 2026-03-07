local stringify = pandoc.utils.stringify

local function meta_to_string(value)
  if value == nil then
    return nil
  end

  if type(value) == "string" then
    return value
  end

  local text = stringify(value)
  if text == nil or text == "" then
    return nil
  end

  return text
end

local function add_unique_category(categories, seen, value)
  if value == nil or value == "" then
    return
  end

  local key = string.lower(value)
  if seen[key] then
    return
  end

  table.insert(categories, pandoc.MetaString(value))
  seen[key] = true
end

function Meta(meta)
  local topic = meta_to_string(meta.topic)
  local subject = meta_to_string(meta.subject)

  if topic == nil and subject == nil then
    return meta
  end

  local categories = {}
  local seen = {}

  if meta.categories ~= nil then
    if meta.categories.t == "MetaList" then
      for _, item in ipairs(meta.categories) do
        local category_text = meta_to_string(item)
        add_unique_category(categories, seen, category_text)
      end
    else
      local category_text = meta_to_string(meta.categories)
      add_unique_category(categories, seen, category_text)
    end
  end

  add_unique_category(categories, seen, topic)
  add_unique_category(categories, seen, subject)

  meta.categories = pandoc.MetaList(categories)
  return meta
end
