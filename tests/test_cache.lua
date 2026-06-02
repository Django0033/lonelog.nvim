#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

_G.vim = {
  api = {
    nvim_get_current_buf = function() return 1 end,
    nvim_buf_get_lines = function() return {
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
      "[F:Goblin|HP 6|alerta]",
      "[E:Torch 3/6]",
      "[Clock:Alert 2/5]",
      "[Timer:Burnout 3]",
      "",
      "### S2 *The library*",
      "@ Search the shelves",
      "[N:Elara|waiting]",
      "d: 2d6+3 -> 9",
    } end,
    nvim_buf_get_changedtick = function() return 5 end,
  },
  deepcopy = function(t)
    local function deepcopy(obj)
      if type(obj) == 'table' then
        local copy = {}
        for k, v in pairs(obj) do
          copy[deepcopy(k)] = deepcopy(v)
        end
        return copy
      else
        return obj
      end
    end
    return deepcopy(t)
  end,
  tbl_deep_extend = function(_, t1, t2)
    local r = {}
    for k, v in pairs(t1) do r[k] = v end
    for k, v in pairs(t2) do r[k] = v end
    return r
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

local cache = require("lonelog.parsers.cache")
local passed, failed = 0, 0

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
        if type(got[i]) ~= "table" then ok = false; break end
        for k, val in pairs(v) do
          if got[i][k] ~= val then ok = false; break end
        end
      elseif got[i] ~= v then
        ok = false; break
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

print("Testing cached element parser:")
print("====================================")

-- Test: NPC aggregation with mentions
do
  local data = cache.get()
  check_table("npcs: count", #data.npcs, 1)
  if #data.npcs >= 1 then
    check("npcs: name", data.npcs[1].name, "Elara")
    check_table("npcs: lines", data.npcs[1].lines, { 6, 7, 18 })
    check("npcs: first_seen", data.npcs[1].first_seen, 6)
    check("npcs: last_seen", data.npcs[1].last_seen, 18)
    check("npcs: mention_count", data.npcs[1].mention_count, 3)
  end
end

-- Test: Location
do
  local data = cache.get()
  check_table("locations: count", #data.locations, 1)
  if #data.locations >= 1 then
    check("locations: name", data.locations[1].name, "Library")
    check_table("locations: lines", data.locations[1].lines, { 8 })
  end
end

-- Test: PC
do
  local data = cache.get()
  check_table("pcs: count", #data.pcs, 1)
  if #data.pcs >= 1 then
    check("pcs: name", data.pcs[1].name, "Alex")
  end
end

-- Test: Thread
do
  local data = cache.get()
  check_table("threads: count", #data.threads, 1)
  if #data.threads >= 1 then
    check("threads: name", data.threads[1].name, "Main Quest")
  end
end

-- Test: Foe
do
  local data = cache.get()
  check_table("foes: count", #data.foes, 1)
  if #data.foes >= 1 then
    check("foes: name", data.foes[1].name, "Goblin")
  end
end

-- Test: Progress elements with current/max
do
  local data = cache.get()
  local function find_prog(name)
    for _, p in ipairs(data.progress) do
      if p.name == name then return p end
    end
  end

  local torch = find_prog("Torch")
  check("progress: Torch exists", torch ~= nil, true)
  if torch then
    check("progress: Torch current", torch.current, 3)
    check("progress: Torch max", torch.max, 6)
    check("progress: Torch has line", type(torch.line) == "number", true)
  end

  local alert = find_prog("Alert")
  check("progress: Alert exists", alert ~= nil, true)
  if alert then
    check("progress: Alert current", alert.current, 2)
    check("progress: Alert max", alert.max, 5)
  end

  local burnout = find_prog("Burnout")
  check("progress: Burnout exists", burnout ~= nil, true)
  if burnout then
    check("progress: Burnout current", burnout.current, 3)
    check("progress: Burnout max", burnout.max, nil)
  end
end

-- Test: Scenes
do
  local data = cache.get()
  check("scenes: count", #data.scenes >= 2, true)
end

-- Test: Sessions
do
  local data = cache.get()
  check("sessions: count", #data.sessions >= 1, true)
  if #data.sessions >= 1 then
    check("sessions: number", data.sessions[1].number, 1)
  end
end

-- Test: Cache hit (same changedtick)
do
  local data1 = cache.get()
  local data2 = cache.get()
  check("cache: same reference on hit", data1 == data2, true)
end

-- Test: Invalidate
do
  cache.invalidate()
  local data = cache.get()
  check("invalidate: still returns data", data ~= nil, true)
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
