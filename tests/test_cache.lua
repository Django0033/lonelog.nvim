#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- ---------------------------------------------------------------------------
-- Per-buffer mock data: three buffers for isolation and edge-case testing
-- ---------------------------------------------------------------------------
local _current_buf = 1
local _bufs = {
  [1] = {
    changedtick = 5,
    lines = {
      "## Session 1",
      "2026-01-15",
      "",
      "### S1 *Entering the forest*",
      "@ Follow the trail",
      "[N:Elara|waiting|friendly]",
      "[N:Elara|waiting]",
      "[L:Library|dark|quiet]",
      "[PC:Alex|HP 8]",
      "[Thread:Main Quest|Open]",
      "[F:Goblin|HP 6|alert]",
      "[INV:Ancient Key|quest|heavy]",
      "[WEALTH:Gold Coins|45|sp]",
      "[R:Throne Room|royal|guarded]",
      "[E:Torch 3/6]",
      "[Clock:Alert 2/5]",
      "[Timer:Burnout 3]",
      "[Track:Journey 3/10]",
      "",
      "### S2 *The library*",
      "@ Search the shelves",
      "[N:Elara|waiting]",
      "[N:Marcus|merchant]",
      "[L:Dark Forest|dense|misty]",
      "[INV:Rusty Sword|broken]",
      "[WEALTH:Silver Ring|1|ring]",
      "[R:Dungeon Cell|cold]",
      "d: 2d6+3 -> 9",
    },
  },
  [2] = {
    changedtick = 10,
    lines = {
      "## Session 42",
      "2026-06-03",
      "",
      "### S1 *The final battle*",
      "@ Draw your weapon",
      "[N:Zara|warrior|bold]",
      "[N:Zara|wounded]",
      "[N:Zara|triumphant]",
      "[F:Dragon|HP 20|flying]",
      "[E:Quest 1/1]",
    },
  },
  [3] = {
    changedtick = 0,
    lines = {},
  },
  [4] = {
    changedtick = 3,
    lines = {
      "## Session 1",
      "",
      "d: 2d6[3, 4] = 7",
      "d: 2d6[1, 5] = 6",
      "d: 1d20[15] = 15",
      "",
      "d: 4df[-1, 0, 1, 0] = 0",
    },
  },
}

_G.vim = {
  api = {
    nvim_get_current_buf = function() return _current_buf end,
    nvim_buf_get_lines = function(bufnr)
      bufnr = bufnr or _current_buf
      local entry = _bufs[bufnr]
      if not entry then
        return {}
      end
      return entry.lines
    end,
    nvim_buf_get_changedtick = function(bufnr)
      bufnr = bufnr or _current_buf
      local entry = _bufs[bufnr]
      if not entry then
        return 0
      end
      return entry.changedtick
    end,
  },
  deepcopy = function(t)
    local function copy(obj)
      if type(obj) == "table" then
        local r = {}
        for k, v in pairs(obj) do
          r[copy(k)] = copy(v)
        end
        return r
      end
      return obj
    end
    return copy(t)
  end,
  tbl_deep_extend = function(_, t1, t2)
    local r = {}
    for k, v in pairs(t1) do
      r[k] = v
    end
    for k, v in pairs(t2) do
      r[k] = v
    end
    return r
  end,
  trim = function(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
  end,
  o = { columns = 80, lines = 24 },
  fn = {
    getline = function() return "" end,
    col = function() return 1 end,
  },
  notify = function() end,
  cmd = function() end,
  log = { levels = { ERROR = 1, WARN = 2 } },
}

-- Mock history data for roll aggregation tests (set per-test-block)
local mock_dice_history = {}
local mock_oracle_history = {}

package.preload["lonelog.dice"] = function()
  return {
    setup = function() end,
    roll = function() return { total = 0 } end,
    add_to_history = function() end,
    clear_history = function() end,
    get_history = function(bufnr)
      return mock_dice_history[bufnr] or {}
    end,
  }
end

package.preload["lonelog.oracle"] = function()
  return {
    load_chaos = function() end,
    roll = function() return {} end,
    add_to_history = function() end,
    clear_history = function() end,
    get_chaos = function() return 5 end,
    set_chaos = function() end,
    list_tables = function() return {} end,
    format_result = function() return "" end,
    get_history = function(bufnr)
      return mock_oracle_history[bufnr] or {}
    end,
  }
end

-- Clear any cached instances so preload takes effect
package.loaded["lonelog.dice"] = nil
package.loaded["lonelog.oracle"] = nil

local cache = require("lonelog.cache")
local passed, failed = 0, 0

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function check(name, got, expected)
  if got == expected then
    print("PASS " .. name)
    passed = passed + 1
  else
    local g = type(got) == "table" and "table" or tostring(got)
    local e = type(expected) == "table" and "table" or tostring(expected)
    print(string.format("FAIL %s: got %s, expected %s", name, g, e))
    failed = failed + 1
  end
end

local function check_table(name, got, expected)
  local ok = true
  if type(got) ~= "table" or type(expected) ~= "table" then
    ok = got == expected
  elseif #got ~= #expected then
    ok = false
  else
    for i, v in ipairs(expected) do
      if type(v) == "table" then
        if type(got[i]) ~= "table" then
          ok = false
          break
        end
        for k, val in pairs(v) do
          if got[i][k] ~= val then
            ok = false
            break
          end
        end
      elseif got[i] ~= v then
        ok = false
        break
      end
    end
  end
  if ok then
    print("PASS " .. name)
    passed = passed + 1
  else
    print("FAIL " .. name)
    failed = failed + 1
  end
end

local function find_entity(arr, name)
  for _, e in ipairs(arr) do
    if e.name == name then
      return e
    end
  end
  return nil
end

local function find_progress(arr, name)
  for _, p in ipairs(arr) do
    if p.name == name then
      return p
    end
  end
  return nil
end

print("Testing cache module (lonelog.cache):")
print("======================================")

-- =============================================
-- 1. Entity aggregation: NPCs (N)
-- =============================================
do
  local data = cache.get()
  check_table("npcs: count", #data.npcs, 2)

  local elara = find_entity(data.npcs, "Elara")
  check("npcs: Elara exists", elara ~= nil, true)
  if elara then
    check_table("npcs: Elara tags", elara.tags, { "waiting", "friendly" })
    check_table("npcs: Elara lines", elara.lines, { 6, 7, 22 })
    check("npcs: Elara first_seen", elara.first_seen, 6)
    check("npcs: Elara last_seen", elara.last_seen, 22)
    check("npcs: Elara mention_count", elara.mention_count, 3)
  end

  local marcus = find_entity(data.npcs, "Marcus")
  check("npcs: Marcus exists", marcus ~= nil, true)
  if marcus then
    check("npcs: Marcus first_seen", marcus.first_seen, 23)
    check("npcs: Marcus mention_count", marcus.mention_count, 1)
  end
end

-- =============================================
-- 2. Entity aggregation: Locations (L)
-- =============================================
do
  local data = cache.get()
  check_table("locations: count", #data.locations, 2)

  local lib = find_entity(data.locations, "Library")
  check("locations: Library exists", lib ~= nil, true)
  if lib then
    check("locations: Library first_seen", lib.first_seen, 8)
    check("locations: Library mention_count", lib.mention_count, 1)
  end

  local forest = find_entity(data.locations, "Dark Forest")
  check("locations: Dark Forest exists", forest ~= nil, true)
  if forest then
    check("locations: Dark Forest first_seen", forest.first_seen, 24)
  end
end

-- =============================================
-- 3. Entity aggregation: PC
-- =============================================
do
  local data = cache.get()
  check_table("pcs: count", #data.pcs, 1)
  if #data.pcs >= 1 then
    check("pcs: name", data.pcs[1].name, "Alex")
    check("pcs: first_seen", data.pcs[1].first_seen, 9)
  end
end

-- =============================================
-- 4. Entity aggregation: Thread
-- =============================================
do
  local data = cache.get()
  check_table("threads: count", #data.threads, 1)
  if #data.threads >= 1 then
    check("threads: name", data.threads[1].name, "Main Quest")
    check("threads: first_seen", data.threads[1].first_seen, 10)
  end
end

-- =============================================
-- 5. Entity aggregation: Foes (F)
-- =============================================
do
  local data = cache.get()
  check_table("foes: count", #data.foes, 1)
  if #data.foes >= 1 then
    check("foes: name", data.foes[1].name, "Goblin")
    check("foes: first_seen", data.foes[1].first_seen, 11)
  end
end

-- =============================================
-- 6. Entity aggregation: Inventory (INV)
-- =============================================
do
  local data = cache.get()
  check("inventory: count", #data.inventory, 2)

  local key = find_entity(data.inventory, "Ancient Key")
  check("inventory: Ancient Key exists", key ~= nil, true)
  if key then
    check("inventory: Ancient Key first_seen", key.first_seen, 12)
  end

  local sword = find_entity(data.inventory, "Rusty Sword")
  check("inventory: Rusty Sword exists", sword ~= nil, true)
  if sword then
    check("inventory: Rusty Sword first_seen", sword.first_seen, 25)
  end
end

-- =============================================
-- 7. Entity aggregation: Wealth (WEALTH)
-- =============================================
do
  local data = cache.get()
  check("wealth: count", #data.wealth, 2)

  local gold = find_entity(data.wealth, "Gold Coins")
  check("wealth: Gold Coins exists", gold ~= nil, true)
  if gold then
    check("wealth: Gold Coins first_seen", gold.first_seen, 13)
  end

  local ring = find_entity(data.wealth, "Silver Ring")
  check("wealth: Silver Ring exists", ring ~= nil, true)
  if ring then
    check("wealth: Silver Ring first_seen", ring.first_seen, 26)
  end
end

-- =============================================
-- 8. Entity aggregation: Rooms (R)
-- =============================================
do
  local data = cache.get()
  check("rooms: count", #data.rooms, 2)

  local throne = find_entity(data.rooms, "Throne Room")
  check("rooms: Throne Room exists", throne ~= nil, true)
  if throne then
    check("rooms: Throne Room first_seen", throne.first_seen, 14)
  end

  local cell = find_entity(data.rooms, "Dungeon Cell")
  check("rooms: Dungeon Cell exists", cell ~= nil, true)
  if cell then
    check("rooms: Dungeon Cell first_seen", cell.first_seen, 27)
  end
end

-- =============================================
-- 9. Progress elements
-- =============================================
do
  local data = cache.get()

  -- E type
  local torch = find_progress(data.progress, "Torch")
  check("progress: Torch exists", torch ~= nil, true)
  if torch then
    check("progress: Torch type", torch.type, "E")
    check("progress: Torch current", torch.current, 3)
    check("progress: Torch max", torch.max, 6)
    check("progress: Torch has line", type(torch.line) == "number", true)
  end

  -- CLOCK -> type "E"
  local alert = find_progress(data.progress, "Alert")
  check("progress: Alert exists", alert ~= nil, true)
  if alert then
    check("progress: Alert type (CLOCK->E)", alert.type, "E")
    check("progress: Alert current", alert.current, 2)
    check("progress: Alert max", alert.max, 5)
  end

  -- TIMER
  local burnout = find_progress(data.progress, "Burnout")
  check("progress: Burnout exists", burnout ~= nil, true)
  if burnout then
    check("progress: Burnout type", burnout.type, "TIMER")
    check("progress: Burnout current", burnout.current, 3)
    check("progress: Burnout max", burnout.max, nil)
  end

  -- TRACK
  local journey = find_progress(data.progress, "Journey")
  check("progress: Journey exists", journey ~= nil, true)
  if journey then
    check("progress: Journey type", journey.type, "TRACK")
    check("progress: Journey current", journey.current, 3)
    check("progress: Journey max", journey.max, 10)
  end

  -- Progress count
  check("progress: total count", #data.progress, 4)
end

-- =============================================
-- 10. Passthrough: scenes
-- =============================================
do
  local data = cache.get()
  check("scenes: count", #data.scenes >= 2, true)
  if #data.scenes >= 1 then
    check("scenes: first scene_id", data.scenes[1].scene_id, "S1")
  end
  if #data.scenes >= 2 then
    check("scenes: second scene_id", data.scenes[2].scene_id, "S2")
  end
end

-- =============================================
-- 11. Passthrough: sessions
-- =============================================
do
  local data = cache.get()
  check("sessions: count", #data.sessions >= 1, true)
  if #data.sessions >= 1 then
    check("sessions: number", data.sessions[1].number, 1)
  end
end

-- =============================================
-- 12. Raw tags passthrough
-- =============================================
do
  local data = cache.get()
  check("tags: passthrough is table", type(data.tags) == "table", true)
  check("tags: all tag lines found", #data.tags >= 19, true)
  -- Spot-check: first N tag should be Elara at line 6
  local elara_tag
  for _, t in ipairs(data.tags) do
    if t.name == "Elara" and t.type == "N" then
      elara_tag = t
      break
    end
  end
  check("tags: Elara exists in raw tags", elara_tag ~= nil, true)
  if elara_tag then
    check("tags: Elara raw type", elara_tag.type, "N")
    check("tags: Elara raw line", elara_tag.line, 6)
  end
end

-- =============================================
-- 13. Case-insensitive sorting
-- =============================================
do
  local data = cache.get()
  if #data.npcs >= 2 then
    check("sorting: Elara before Marcus", data.npcs[1].name, "Elara")
    check("sorting: Marcus after Elara", data.npcs[2].name, "Marcus")
  end
  if #data.locations >= 2 then
    check("sorting: Dark Forest before Library", data.locations[1].name, "Dark Forest")
    check("sorting: Library after Dark Forest", data.locations[2].name, "Library")
  end
end

-- =============================================
-- 14. Cache hit (same changedtick)
-- =============================================
do
  local data1 = cache.get()
  local data2 = cache.get()
  check("cache: same reference on hit", data1 == data2, true)
end

-- =============================================
-- 15. Cache miss (different changedtick triggers refresh)
-- =============================================
do
  local data_before = cache.get()
  _bufs[1].changedtick = 6
  local data_after = cache.get()
  check("cache: different reference on miss", data_before ~= data_after, true)
  -- Reset for subsequent tests
  _bufs[1].changedtick = 5
end

-- =============================================
-- 16. refresh() forces re-parse, then subsequent get() is cached
-- =============================================
do
  cache.refresh()
  local data_a = cache.get()
  local data_b = cache.get()
  check("refresh: cached reference after refresh", data_a == data_b, true)
end

-- =============================================
-- 17. invalidate() clears cache entry
-- =============================================
do
  local data_before = cache.get()
  cache.invalidate()
  local data_after = cache.get()
  check("invalidate: data is new object", data_before ~= data_after, true)
end

-- =============================================
-- 18. Explicit bufnr parameter
-- =============================================
do
  local data = cache.get(1)
  check("explicit bufnr: npcs count", #data.npcs, 2)
end

-- =============================================
-- 19. Entity structure has all required fields
-- =============================================
do
  local data = cache.get()
  local elara = find_entity(data.npcs, "Elara")
  if elara then
    check("entity: has name field", elara.name ~= nil, true)
    check("entity: has tags field", type(elara.tags) == "table", true)
    check("entity: has lines field", type(elara.lines) == "table", true)
    check("entity: has first_seen field", type(elara.first_seen) == "number", true)
    check("entity: has last_seen field", type(elara.last_seen) == "number", true)
    check("entity: has mention_count field", type(elara.mention_count) == "number", true)
  end
end

-- =============================================
-- 20. Progress has all required fields
-- =============================================
do
  local data = cache.get()
  local torch = find_progress(data.progress, "Torch")
  if torch then
    check("progress: has type field", torch.type ~= nil, true)
    check("progress: has name field", torch.name ~= nil, true)
    check("progress: has current field", type(torch.current) == "number", true)
    check("progress: has max field", torch.max ~= nil, true)
    check("progress: has line field", type(torch.line) == "number", true)
  end
end

-- =============================================
-- 21. Multiple calls with same data produce consistent results
-- =============================================
do
  cache.invalidate()
  local first = cache.get()
  local second = cache.get()
  check("consistent: same count on repeat", #first.npcs, #second.npcs)
end

-- =============================================
-- 22. Cache isolation (different buffers, different content)
-- =============================================
do
  -- buf 1 has Elara + Marcus
  local data1 = cache.get(1)
  check("isolation: buf 1 has Elara", find_entity(data1.npcs, "Elara") ~= nil, true)
  check("isolation: buf 1 has Marcus", find_entity(data1.npcs, "Marcus") ~= nil, true)

  -- buf 2 has Zara alone (different content, different NPCs)
  local data2 = cache.get(2)
  check("isolation: buf 2 has Zara", find_entity(data2.npcs, "Zara") ~= nil, true)
  check("isolation: buf 2 no Elara", find_entity(data2.npcs, "Elara") == nil, true)
  check("isolation: buf 2 NPC count", #data2.npcs, 1)

  -- buf 1 still intact (isolated cache entry)
  local data1b = cache.get(1)
  check("isolation: buf 1 still intact", #data1b.npcs, 2)
  check("isolation: buf 1 reference cached", data1 == data1b, true)

  -- buf 2 also stays cached
  local data2b = cache.get(2)
  check("isolation: buf 2 reference cached", data2 == data2b, true)
end

-- =============================================
-- 23. Empty buffer returns empty arrays, not nil
-- =============================================
do
  local data = cache.get(3)
  check("empty: data is table", type(data) == "table", true)
  check("empty: npcs is table", type(data.npcs) == "table", true)
  check("empty: npcs count", #data.npcs, 0)
  check("empty: locations count", #data.locations, 0)
  check("empty: pcs count", #data.pcs, 0)
  check("empty: threads count", #data.threads, 0)
  check("empty: foes count", #data.foes, 0)
  check("empty: inventory count", #data.inventory, 0)
  check("empty: wealth count", #data.wealth, 0)
  check("empty: rooms count", #data.rooms, 0)
  check("empty: progress count", #data.progress, 0)
  check("empty: scenes count", #data.scenes, 0)
  check("empty: sessions count", #data.sessions, 0)
  check("empty: tags count", #data.tags, 0)
end

-- =============================================
-- 24. Roll aggregation: rolls field exists with defaults
-- =============================================
do
  mock_dice_history = {}
  mock_oracle_history = {}
  cache.invalidate(3)
  local data = cache.get(3)
  check("rolls: field exists", type(data.rolls) == "table", true)
  check("rolls: by_type is table", type(data.rolls.by_type) == "table", true)
  check("rolls: total_rolls is 0", data.rolls.total_rolls, 0)
  check("rolls: oracle_results is table", type(data.rolls.oracle_results) == "table", true)
	check("rolls: oracle_results has zero-filled tables", #data.rolls.oracle_results, 2)
	check("rolls: fate table zero-filled", data.rolls.oracle_results[1].results.yes, 0)
end

-- =============================================
-- 25. Roll aggregation: dice history entries aggregated by notation
-- =============================================
do
  -- Use bufnr 3 (empty buffer, no d: lines) for pure history test
  mock_dice_history = {
    [3] = {
      { result = { original = "2d6", total = 7 }, line = 3, bufnr = 3 },
      { result = { original = "2d6", total = 6 }, line = 4, bufnr = 3 },
      { result = { original = "1d20", total = 15 }, line = 5, bufnr = 3 },
    },
  }
  mock_oracle_history = {}
  cache.invalidate(3)
  local data = cache.get(3)
  check("rolls: 2 notations from history", #data.rolls.by_type, 2)
  check("rolls: total_rolls is 3", data.rolls.total_rolls, 3)

  local d6_entry
  local d20_entry
  for _, e in ipairs(data.rolls.by_type) do
    if e.notation == "2d6" then d6_entry = e end
    if e.notation == "1d20" then d20_entry = e end
  end
  check("rolls: 2d6 entry exists", d6_entry ~= nil, true)
  if d6_entry then
    check("rolls: 2d6 count", d6_entry.count, 2)
    check("rolls: 2d6 sum", d6_entry.sum, 13)
    check("rolls: 2d6 average", d6_entry.average, 6.5)
  end
  check("rolls: 1d20 entry exists", d20_entry ~= nil, true)
  if d20_entry then
    check("rolls: 1d20 count", d20_entry.count, 1)
    check("rolls: 1d20 sum", d20_entry.sum, 15)
  end
end

-- =============================================
-- 26. Roll aggregation: d: buffer lines parsed (no history)
-- =============================================
do
  mock_dice_history = {}
  mock_oracle_history = {}
  _current_buf = 4
  cache.invalidate(4)
  local data = cache.get(4)
  -- 4 d: lines in buffer 4: "2d6", "2d6", "1d20", "4df"
  check("rolls: 3 notations from d: lines", #data.rolls.by_type, 3)
  check("rolls: total_rolls from d: lines", data.rolls.total_rolls, 4)

  local d6_entry
  for _, e in ipairs(data.rolls.by_type) do
    if e.notation == "2d6" then d6_entry = e end
  end
  check("rolls: 2d6 exists from d: lines", d6_entry ~= nil, true)
  if d6_entry then
    check("rolls: 2d6 count from d: lines", d6_entry.count, 2)
    check("rolls: 2d6 sum from d: lines", d6_entry.sum, 13)
    check("rolls: 2d6 min", d6_entry.min, 6)
    check("rolls: 2d6 max", d6_entry.max, 7)
  end
  _current_buf = 1
end

-- =============================================
-- 27. Roll aggregation: history wins over d: line on same line
-- =============================================
do
  -- buf 4 has d: 2d6[3, 4] = 7 at line 3
  -- Set history with a different total for the same line
  mock_dice_history = {
    [4] = {
      { result = { original = "2d6", total = 999 }, line = 3, bufnr = 4 },
    },
  }
  mock_oracle_history = {}
  _current_buf = 4
  cache.invalidate(4)
  local data = cache.get(4)
  -- Should have 3 notations (2d6 from history replaces line 3 d:, 2d6 from line 4, 1d20, 4df)
  -- Wait, the 2d6 entries: line 3 (history, total=999), line 4 (d: line, total=6)
  -- So 2d6 should have sum = 999 + 6 = 1005
  local d6_entry
  for _, e in ipairs(data.rolls.by_type) do
    if e.notation == "2d6" then d6_entry = e end
  end
  check("rolls: 2d6 exists after merge", d6_entry ~= nil, true)
  if d6_entry then
    check("rolls: 2d6 count is 2 (history 1 + d: line 1)", d6_entry.count, 2)
    check("rolls: 2d6 sum is 1005 (history wins on line 3)", d6_entry.sum, 1005)
  end
  _current_buf = 1
end

-- =============================================
-- 28. Roll aggregation: oracle results aggregated by table and value
-- =============================================
do
  mock_dice_history = {}
  mock_oracle_history = {
    [4] = {
      { result = { table = "fate", value = "yes" }, line = 1, bufnr = 4 },
      { result = { table = "fate", value = "no" }, line = 2, bufnr = 4 },
      { result = { table = "fate", value = "yes" }, line = 3, bufnr = 4 },
      { result = { table = "binary", value = "yes" }, line = 4, bufnr = 4 },
    },
  }
  _current_buf = 4
  cache.invalidate(4)
  local data = cache.get(4)
  check("rolls: oracle_results count", #data.rolls.oracle_results, 2)

  local fate_entry
  for _, e in ipairs(data.rolls.oracle_results) do
    if e.table == "fate" then fate_entry = e end
  end
  check("rolls: fate oracle exists", fate_entry ~= nil, true)
  if fate_entry then
    check("rolls: fate yes count", fate_entry.results.yes, 2)
    check("rolls: fate no count", fate_entry.results.no, 1)
  end
  _current_buf = 1
end

-- =============================================
-- 29. Roll aggregation: per-buffer isolation
-- =============================================
do
  mock_dice_history = {
    [1] = {
      { result = { original = "1d20", total = 18 }, line = 1, bufnr = 1 },
    },
  }
  mock_oracle_history = {}
  -- buf 1 has no d: lines in the d: format with brackets
  cache.invalidate(1)
  local data_buf1 = cache.get(1)
  check("rolls: buf 1 has 1 notation", #data_buf1.rolls.by_type, 1)

  -- buf 3 should have nothing
  cache.invalidate(3)
  local data_buf3 = cache.get(3)
  check("rolls: buf 3 empty", data_buf3.rolls.total_rolls, 0)
end

-- =============================================
-- Summary
-- =============================================
print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
