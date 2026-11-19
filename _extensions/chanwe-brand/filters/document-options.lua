-- document-options.lua — the document-wide choices of chanwe-brand-html.
--
--   chanwe:
--     cover-variant: paper | photo-obsidian   # default: the research banner
--     task-style: square | round              # default: square (unified with the kit)
--     table-style: open | pane                # default: open
--     eyebrow-style: dot | rule               # default: dot; `rule` is the orange rule
--     toc-style: glass                        # default: today's index; `glass` adds progress and «back to top»
--
-- The names are the print formats' (`chanwe.cover-variant` in the report).
-- Each choice becomes an attribute on <html> (`data-cw-cover`,
-- `data-cw-tasks`, `data-cw-tables`), written in the <head> so the first paint already has
-- it; chanwe-brand-rules.scss and title-banner-layout.html read it. An
-- unknown value is ignored and the default stays.

local COVERS = { ["paper"] = true, ["photo-obsidian"] = true }
local TASKS = { ["round"] = true, ["square"] = true }
local TABLES = { ["open"] = true, ["pane"] = true }
local EYEBROWS = { ["dot"] = true, ["rule"] = true }
local TOCS = { ["glass"] = true }

local function option(meta, key)
  local chanwe = meta.chanwe
  if type(chanwe) ~= "table" or chanwe[key] == nil then return nil end
  local value = pandoc.utils.stringify(chanwe[key])
  if value == "" then return nil end
  return value
end

function Meta(meta)
  if not quarto.doc.is_format("html") then return nil end

  local attrs = {}
  local cover = option(meta, "cover-variant")
  if cover and COVERS[cover] then attrs[#attrs + 1] = { "cwCover", cover } end
  local tasks = option(meta, "task-style")
  if tasks and TASKS[tasks] then attrs[#attrs + 1] = { "cwTasks", tasks } end
  local tables = option(meta, "table-style")
  if tables and TABLES[tables] then attrs[#attrs + 1] = { "cwTables", tables } end
  local eyebrows = option(meta, "eyebrow-style")
  if eyebrows and EYEBROWS[eyebrows] then attrs[#attrs + 1] = { "cwEyebrows", eyebrows } end
  local toc = option(meta, "toc-style")
  if toc and TOCS[toc] then attrs[#attrs + 1] = { "cwToc", toc } end
  if #attrs == 0 then return nil end

  local lines = {}
  for _, pair in ipairs(attrs) do
    lines[#lines + 1] = string.format('document.documentElement.dataset.%s = "%s";', pair[1], pair[2])
  end
  quarto.doc.include_text("in-header", "<script>" .. table.concat(lines, " ") .. "</script>")
  return nil
end
