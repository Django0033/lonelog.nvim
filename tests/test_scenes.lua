#!/usr/bin/env lua

vim = {
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
  api = {
    nvim_buf_get_lines = function() return {} end,
    nvim_buf_get_name = function() return "test.md" end,
    nvim_get_current_buf = function() return 1 end,
  },
  trim = function(s) return s:match("^%s*(.-)%s*$") end,
  tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
}

package.path = package.path .. ";./lua/?.lua"
local M = require("lonelog.ui.parsers").scenes

local test_cases = {
  { input = "S1 *Lighthouse tower, dusk*", expected_type = "main", expected_id = "S1", expected_context = "Lighthouse tower, dusk" },
  { input = "S2 *Basement stairs*", expected_type = "main", expected_id = "S2", expected_context = "Basement stairs" },
  { input = "S5a *Flashback: Father's workshop*", expected_type = "flashback", expected_id = "S5a", expected_context = "Flashback: Father's workshop" },
  { input = "S7.1 *Day 1: Forest*", expected_type = "sub", expected_id = "S7.1", expected_context = "Day 1: Forest" },
  { input = "T1-S1 *Lighthouse tower*", expected_type = "thread", expected_id = "T1-S1", expected_context = "Lighthouse tower" },
  { input = "T1+T2-S5 *Combined*", expected_type = "thread", expected_id = "T1+T2-S5", expected_context = "Combined" },
  { input = "S10", expected_type = "main", expected_id = "S10", expected_context = nil },
}

print("Testing parse_scene function:")
print("==============================")

local passed, failed = 0, 0

for _, tc in ipairs(test_cases) do
  local result = M.parse_scene(tc.input, 1)

  if result then
    local ok = true
    local errors = {}

    if result.type ~= tc.expected_type then
      table.insert(errors, string.format("type: got %s, expected %s", result.type, tc.expected_type))
      ok = false
    end
    if result.scene_id ~= tc.expected_id then
      table.insert(errors, string.format("id: got %s, expected %s", tostring(result.scene_id), tc.expected_id))
      ok = false
    end
    if result.context ~= tc.expected_context then
      table.insert(errors, string.format("context: got %s, expected %s", tostring(result.context), tostring(tc.expected_context)))
      ok = false
    end

    if ok then
      print(string.format("PASS [%s] %s", tc.expected_type, tc.input))
      passed = passed + 1
    else
      print(string.format("FAIL [%s] %s", tc.expected_type, tc.input))
      for _, err in ipairs(errors) do
        print("  - " .. err)
      end
      failed = failed + 1
    end
  else
    print(string.format("FAIL [%s] %s - returned nil", tc.expected_type, tc.input))
    failed = failed + 1
  end
end

print()
print("Testing sorting:")
print("==============================")

local test_scenes = {
  M.parse_scene("S1", 1),
  M.parse_scene("S2", 1),
  M.parse_scene("S5a", 1),
  M.parse_scene("S7.1", 1),
  M.parse_scene("S7.2", 1),
  M.parse_scene("S7.3", 1),
  M.parse_scene("S5b", 1),
  M.parse_scene("S10", 1),
  M.parse_scene("T1-S1", 1),
  M.parse_scene("T2-S1", 1),
}

local sorted = M.sort_scenes(test_scenes)
local sorted_ids = {}
for _, s in ipairs(sorted) do
  table.insert(sorted_ids, s.scene_id)
end

local expected_order = {"S1", "S2", "S5a", "S5b", "S7.1", "S7.2", "S7.3", "S10", "T1-S1", "T2-S1"}
local order_ok = true
for i, expected in ipairs(expected_order) do
  if sorted_ids[i] ~= expected then
    order_ok = false
    print(string.format("Order FAIL: position %d, got %s, expected %s", i, sorted_ids[i], expected))
  end
end

if order_ok then
  print("PASS - Scenes sorted correctly:")
  for _, id in ipairs(sorted_ids) do print("  " .. id) end
  passed = passed + 1
else
  failed = failed + 1
end

print()
print(string.format("RESULTS: %d passed, %d failed", passed, failed))

if failed > 0 then
  os.exit(1)
end
