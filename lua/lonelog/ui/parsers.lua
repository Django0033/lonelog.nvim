local M = {}

-- Map tag type keys to human-readable names
local TAG_TYPES = { N = "NPC", L = "Location", E = "Event", PC = "PC", THREAD = "Thread", CLOCK = "Clock", TRACK = "Track", TIMER = "Timer", INV = "Inventory", R = "Room", F = "Foe" }
local TAG_LABELS = { N = "NPCs", L = "Locations", E = "Events", PC = "Player Characters", THREAD = "Threads", CLOCK = "Clocks", TRACK = "Tracks", TIMER = "Timers", INV = "Inventory", R = "Rooms", F = "Foes" }

-- Map scene type keys to labels
local SCENE_TYPES = { main = "Main", flashback = "Flashback", sub = "Sub-scene", thread = "Thread" }
local SCENE_LABELS = { main = "Main Scenes", flashback = "Flashbacks", sub = "Sub-scenes", thread = "Thread Scenes" }

-- Check if we should use Telescope picker
local function should_use_telescope()
  return require("lonelog.config").should_use_telescope()
end

-- Parse all Lonelog tags from a buffer
-- Returns array of tag objects
function M.parse_tags(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local tags = {}
  for line_num, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    -- Match tag patterns like [N:Name] or [#N:Name]
    for match in line:gmatch("%[[%#]?%w+:%s*[^%]]+%]") do
      local parsed = M.parse_tag(match, line_num)
      if parsed then table.insert(tags, parsed) end
    end
  end
  return tags
end

-- Sort tags by line number
function M.sort_tags(tags)
  table.sort(tags, function(a, b) return a.line < b.line end)
  return tags
end

-- Parse a single tag string into an object
-- raw: the raw tag text like "[N:Jonah|friendly]"
-- line_num: line number where tag appears
function M.parse_tag(raw, line_num)
  -- Check if it's a reference tag (starts with [#)
  local is_ref = raw:match("%[[%#]?") == "[#"
  -- Remove brackets
  local content = raw:gsub("^%[[%#]?", ""):gsub("%]$", "")
  -- Get tag type (first word before colon)
  local type_key = content:match("^(%w+)")
  if not type_key or not TAG_TYPES[type_key:upper()] then return nil end
  type_key = type_key:upper()
  -- Get everything after the type
  local rest = content:sub(#type_key + 2)
  -- Try to split name and tags by pipe
  local name, tags_str = rest:match("^([^%|]+)%|(.+)$")
  if not name then
    name = rest
    tags_str = ""
    -- Check for progress format like "Name 3/6"
    local prog = rest:match("^(.-)%s+(%d+/?%d*)$")
    if prog and prog ~= "" then name = prog; tags_str = rest:match("%s+(%d+/?%d*)$") end
  end
  name = name:gsub("^%s+", ""):gsub("%s+$", "")
  -- Parse tags into categories
  local tags, changes, adds, removes = {}, {}, {}, {}
  for tag in tags_str:gmatch("[^%|]+") do
    tag = tag:gsub("^%s+", ""):gsub("%s+$", "")
    if tag:match("→") then table.insert(changes, tag)  -- Change tracking
    elseif tag:match("^%+") then table.insert(adds, tag)  -- Addition
    elseif tag:match("^%-") then table.insert(removes, tag)  -- Removal
    else table.insert(tags, tag) end
  end
  return { type = type_key, type_label = TAG_TYPES[type_key], name = name, tags = tags, changes = changes, additions = adds, removals = removes, is_reference = is_ref, line = line_num, raw = raw }
end

-- Format tag for display in picker
function M.format_tag_display(tag)
  local parts = { "L" .. tag.line .. " | " .. (tag.is_reference and "#" or "") .. "[" .. tag.type .. "] " .. tag.name }
  if #tag.tags > 0 then table.insert(parts, " | " .. table.concat(tag.tags, ", ")) end
  if #tag.changes > 0 then table.insert(parts, " | " .. table.concat(tag.changes, ", ")) end
  if #tag.additions > 0 then table.insert(parts, " | " .. table.concat(tag.additions, ", ")) end
  if #tag.removals > 0 then table.insert(parts, " | " .. table.concat(tag.removals, ", ")) end
  return table.concat(parts, "")
end

-- Count tags by type
function M.tags_summary(tags)
  local s = {}
  for _, t in ipairs(tags) do
    s[t.type] = s[t.type] or { label = TAG_LABELS[t.type], count = 0 }
    s[t.type].count = s[t.type].count + 1
  end
  return s
end

-- Show picker for navigating tags
function M.show_tags_picker()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then vim.notify("lonelog: No file name", vim.log.levels.WARN) return end
  local file_tags = M.parse_tags(bufnr)
  if #file_tags == 0 then vim.notify("lonelog: No tags found", vim.log.levels.INFO) return end
  table.sort(file_tags, function(a, b) return a.line < b.line end)

  -- Use native sidebar if Telescope is disabled
  if not should_use_telescope() then
    M.show_tags_picker_native(file_tags)
    return
  end

  -- Build type filter list
  local summary = M.tags_summary(file_tags)
  local type_items, key_by_label = {}, {}
  table.insert(type_items, "All Tags (" .. #file_tags .. ")")
  key_by_label["All Tags (" .. #file_tags .. ")"] = "all"
  for k, v in pairs(summary) do
    local label = v.label .. " (" .. v.count .. ")"
    table.insert(type_items, label)
    key_by_label[label] = k
  end
  vim.ui.select(type_items, { prompt = "Filter by Type" }, function(choice)
    if not choice then return end
    local key = key_by_label[choice]
    local filtered = key == "all" and file_tags or vim.tbl_filter(function(t) return t.type == key end, file_tags)
    local items = {}
    for _, t in ipairs(filtered) do table.insert(items, M.format_tag_display(t)) end
    vim.ui.select(items, { prompt = "Lonelog Tags" }, function(c)
      if c then
        for i, display in ipairs(items) do
          if display == c then vim.api.nvim_win_set_cursor(0, { filtered[i].line, 0 }); break end
        end
      end
    end)
  end)
end

-- Native sidebar picker for tags
function M.show_tags_picker_native(all_tags)
  local summary = M.tags_summary(all_tags)
  local type_items, key_by_type = {}, {}
  table.insert(type_items, "All Tags (" .. #all_tags .. ")")
  key_by_type[1] = nil  -- Index 1 is "All"
  local idx = 2
  for k, v in pairs(summary) do
    table.insert(type_items, v.label .. " (" .. v.count .. ")")
    key_by_type[idx] = k
    idx = idx + 1
  end

  local sidebar = require("lonelog.ui.sidebar")
  sidebar.open("Tags", type_items, {
    data = type_items,
    format_item = function(item) return item end,
    on_select = function(choice)
      -- Find which type was selected
      local type_idx = 0
      for i, item in ipairs(type_items) do
        if item == choice then type_idx = i; break end
      end
      local type_key = key_by_type[type_idx]
      local filtered = type_key and vim.tbl_filter(function(t) return t.type == type_key end, all_tags) or all_tags
      if #filtered == 0 then return end
      local display_items = {}
      for _, t in ipairs(filtered) do table.insert(display_items, M.format_tag_display(t)) end
      sidebar.open("Tags - " .. choice, display_items, {
        data = filtered,
        on_select = function(tag)
          vim.api.nvim_win_set_cursor(0, { tag.line, 0 })
        end,
      })
    end,
  })
end

-- Parse all scenes from a buffer
function M.parse_scenes(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local scenes = {}
  for line_num, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local parsed = M.parse_scene(line, line_num)
    if parsed then table.insert(scenes, parsed) end
  end
  return scenes
end

-- Parse a single scene line into an object
-- Handles: S1, S5a, S7.1, T1-S1, T1+T2-S5
function M.parse_scene(line, line_num)
  line = line:match("^%s*(.-)%s*$")  -- Trim whitespace
  local scene_id, rest
  -- Match various scene ID patterns
  if line:match("T[0-9]+%+[0-9]*T?[0-9]+%-S") then
    scene_id = line:match("T[0-9]+%+[0-9]*T?[0-9]+%-S[0-9]*[a-z]?")
  elseif line:match("T[0-9]+%-S") then
    scene_id = line:match("T[0-9]+%-S[0-9]*[a-z]?")
  elseif line:match("S[0-9]+%.[0-9]+") then
    scene_id = line:match("S[0-9]+%.[0-9]+")
  elseif line:match("S[0-9]+[a-z]") then
    scene_id = line:match("S[0-9]+[a-z]")
  elseif line:match("S[0-9]+") then
    scene_id = line:match("S[0-9]+")
  else return nil end
  local start = string.find(line, scene_id, 1, true)
  rest = line:sub(start + #scene_id)
  -- Classify and create appropriate sort key
  if scene_id:match("^T") then
    local t1, s
    if scene_id:match("T[%d%a]+%+") then
      t1, s = scene_id:match("^T[%d%a]*%+?([^%+%-]+)%-S([^%[%s]+)")
    else
      t1, s = scene_id:match("^T([^%-]+)%-S([^%[%s]+)")
    end
    if not t1 or not s then return nil end
    local sort_t = tonumber(t1) or 0
    return { type = "thread", type_label = SCENE_TYPES.thread, scene_id = scene_id, context = rest:match("%*(.-)%*"), location = rest:match("%[L:([^%]]+)"), line = line_num, raw = line, sort_key = string.format("%06d.%06d", sort_t + 1000, tonumber(s) or 0) }
  elseif scene_id:match("^S%d+[a-z]") then
    local num, let = scene_id:match("^S(%d+)([a-z])")
    return { type = "flashback", type_label = SCENE_TYPES.flashback, scene_id = scene_id, context = rest:match("%*(.-)%*"), location = rest:match("%[L:([^%]]+)"), line = line_num, raw = line, sort_key = string.format("%06d.%02d", tonumber(num), string.byte(let) - 96) }
  elseif scene_id:match("^S%d+%.") then
    local num, sub = scene_id:match("^S(%d+)%.(%d+)")
    return { type = "sub", type_label = SCENE_TYPES.sub, scene_id = scene_id, context = rest:match("%*(.-)%*"), location = rest:match("%[L:([^%]]+)"), line = line_num, raw = line, sort_key = string.format("%06d.%06d", tonumber(num), tonumber(sub)) }
  else
    return { type = "main", type_label = SCENE_TYPES.main, scene_id = scene_id, context = rest:match("%*(.-)%*"), location = rest:match("%[L:([^%]]+)"), line = line_num, raw = line, sort_key = string.format("%06d.000", tonumber(scene_id:match("%d+"))) }
  end
end

-- Format scene for display in picker
function M.format_scene_display(scene)
  local parts = { "[" .. scene.type_label .. "] " .. scene.scene_id }
  if scene.context then table.insert(parts, " * " .. scene.context .. " *")
  elseif scene.location then table.insert(parts, " * " .. scene.location .. " *") end
  return table.concat(parts, "")
end

-- Count scenes by type
function M.scenes_summary(scenes)
  local s = {}
  for _, sc in ipairs(scenes) do
    s[sc.type] = s[sc.type] or { label = SCENE_LABELS[sc.type], count = 0 }
    s[sc.type].count = s[sc.type].count + 1
  end
  return s
end

-- Sort scenes by sort_key
function M.sort_scenes(scenes)
  table.sort(scenes, function(a, b) return a.sort_key < b.sort_key end)
  return scenes
end

-- Show picker for navigating scenes
function M.show_scenes_picker()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then vim.notify("lonelog: No file name", vim.log.levels.WARN) return end
  local scenes = M.parse_scenes(bufnr)
  if #scenes == 0 then vim.notify("lonelog: No scenes found", vim.log.levels.INFO) return end
  table.sort(scenes, function(a, b) return a.sort_key < b.sort_key end)

  if not should_use_telescope() then
    M.show_scenes_picker_native(scenes)
    return
  end

  local summary = M.scenes_summary(scenes)
  local type_items, key_by_label = {}, {}
  table.insert(type_items, "All Scenes (" .. #scenes .. ")")
  key_by_label["All Scenes (" .. #scenes .. ")"] = "all"
  for k, v in pairs(summary) do
    if k ~= "all" then
      local label = v.label .. " (" .. v.count .. ")"
      table.insert(type_items, label)
      key_by_label[label] = k
    end
  end
  vim.ui.select(type_items, { prompt = "Filter by Type" }, function(choice)
    if not choice then return end
    local key = key_by_label[choice]
    local filtered = key == "all" and scenes or vim.tbl_filter(function(s) return s.type == key end, scenes)
    local items = {}
    for _, sc in ipairs(filtered) do table.insert(items, M.format_scene_display(sc)) end
    vim.ui.select(items, { prompt = "Lonelog Scenes" }, function(c)
      if c then
        for i, display in ipairs(items) do
          if display == c then vim.api.nvim_win_set_cursor(0, { filtered[i].line, 0 }); break end
        end
      end
    end)
  end)
end

-- Native sidebar picker for scenes
function M.show_scenes_picker_native(all_scenes)
  local summary = M.scenes_summary(all_scenes)
  local type_items, key_by_type = {}, {}
  table.insert(type_items, "All Scenes (" .. #all_scenes .. ")")
  key_by_type[1] = nil
  local idx = 2
  for k, v in pairs(summary) do
    table.insert(type_items, v.label .. " (" .. v.count .. ")")
    key_by_type[idx] = k
    idx = idx + 1
  end

  local sidebar = require("lonelog.ui.sidebar")
  sidebar.open("Scenes", type_items, {
    data = type_items,
    format_item = function(item) return item end,
    on_select = function(choice)
      local type_idx = 0
      for i, item in ipairs(type_items) do
        if item == choice then type_idx = i; break end
      end
      local type_key = key_by_type[type_idx]
      local filtered = type_key and vim.tbl_filter(function(s) return s.type == type_key end, all_scenes) or all_scenes
      if #filtered == 0 then return end
      local display_items = {}
      for _, sc in ipairs(filtered) do table.insert(display_items, M.format_scene_display(sc)) end
      sidebar.open("Scenes - " .. choice, display_items, {
        data = filtered,
        on_select = function(scene)
          vim.api.nvim_win_set_cursor(0, { scene.line, 0 })
        end,
      })
    end,
  })
end

return M
