#!/usr/bin/env lua

-- ============================================================================
-- DICE ROLLER TEST SCRIPT
-- ============================================================================

-- Mock vim module for testing outside Neovim
package.path = package.path .. ";./lua/?.lua"

-- Create mock vim
_G.vim = {
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
    local result = {}
    for k, v in pairs(t1) do result[k] = v end
    for k, v in pairs(t2) do result[k] = v end
    return result
  end,
  o = { columns = 80, lines = 24 },
  fn = {
    getline = function() return "" end,
    col = function() return 1 end
  },
  api = {
    nvim_create_buf = function() return 1 end,
    nvim_buf_set_lines = function() end,
    nvim_buf_add_highlight = function() end,
    nvim_open_win = function() return 1 end,
    nvim_set_current_win = function() end,
    nvim_win_is_valid = function() return true end,
    nvim_win_close = function() end,
    nvim_create_user_command = function() end,
    nvim_exec_autocmds = function() end,
  },
  keymap = { set = function() end },
  notify = function() end,
  cmd = function() end,
  log = { levels = { ERROR = 1 } },
  split = function(s, p, o) local r={} for w in s:gmatch('[^'..p..']+') do table.insert(r,w) end return r end,
  tbl_keys = function(t) local r={} for k in pairs(t) do table.insert(r,k) end return r end,
}

-- Load the dice module
local dice = require("lonelog.dice")

-- Seed for reproducible tests
math.randomseed(12345)

local function test(name, notation, expected_parts)
  local result, err = dice.roll(notation)
  
  if err then
    print(string.format("FAIL [%s] %s: %s", name, notation, err))
    return false
  end
  
  local success = true
  local issues = {}
  
  if expected_parts.count and result.count ~= expected_parts.count then
    table.insert(issues, string.format("count: got %d, expected %d", result.count, expected_parts.count))
    success = false
  end
  
  if expected_parts.sides and result.sides ~= expected_parts.sides then
    table.insert(issues, string.format("sides: got %d, expected %d", result.sides, expected_parts.sides))
    success = false
  end
  
  if expected_parts.modifier and result.modifier ~= expected_parts.modifier then
    table.insert(issues, string.format("modifier: got %d, expected %d", result.modifier, expected_parts.modifier))
    success = false
  end
  
  if expected_parts.exploding ~= nil and result.exploding ~= expected_parts.exploding then
    table.insert(issues, string.format("exploding: got %s, expected %s", tostring(result.exploding), tostring(expected_parts.exploding)))
    success = false
  end
  
  if expected_parts.operator and result.operator ~= expected_parts.operator then
    table.insert(issues, string.format("operator: got %s, expected %s", tostring(result.operator), tostring(expected_parts.operator)))
    success = false
  end
  
  if expected_parts.display_match and not result.display:find(expected_parts.display_match, 1, true) then
    table.insert(issues, string.format("display missing: %s", expected_parts.display_match))
    success = false
  end

  if expected_parts.is_fate ~= nil and result.is_fate ~= expected_parts.is_fate then
    table.insert(issues, string.format("is_fate: got %s, expected %s", tostring(result.is_fate), tostring(expected_parts.is_fate)))
    success = false
  end
  
  if success then
    print(string.format("PASS [%s] %s -> %s", name, notation, result.display))
  else
    print(string.format("FAIL [%s] %s: %s", name, notation, table.concat(issues, ", ")))
  end
  
  return success
end

local function test_error(name, notation)
  local result, err = dice.roll(notation)
  
  if result and not err then
    print(string.format("FAIL [%s] %s: Expected error but got result", name, notation))
    return false
  end
  
  print(string.format("PASS [%s] %s -> Error: %s", name, notation, err or "unknown"))
  return true
end

print("=" .. string.rep("=", 70))
print("DICE ROLLER TEST SUITE")
print("=" .. string.rep("=", 70))
print()

local passed = 0
local failed = 0

print("--- Basic Dice Tests ---")
if test("basic", "2d6", { count = 2, sides = 6, modifier = 0 }) then passed = passed + 1 else failed = failed + 1 end
if test("single", "1d20", { count = 1, sides = 20, modifier = 0 }) then passed = passed + 1 else failed = failed + 1 end
if test("d100", "1d100", { count = 1, sides = 100, modifier = 0 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Modifier Tests ---")
if test("positive_mod", "2d6+3", { count = 2, sides = 6, modifier = 3 }) then passed = passed + 1 else failed = failed + 1 end
if test("negative_mod", "1d20-2", { count = 1, sides = 20, modifier = -2 }) then passed = passed + 1 else failed = failed + 1 end
if test("large_mod", "4d10+15", { count = 4, sides = 10, modifier = 15 }) then passed = passed + 1 else failed = failed + 1 end
if test("spaces", "2d6 + 3", { count = 2, sides = 6, modifier = 3 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Exploding Dice Tests ---")
if test("exploding", "4d6!", { count = 4, sides = 6, exploding = true }) then passed = passed + 1 else failed = failed + 1 end
if test("exploding_with_mod", "2d10!+5", { count = 2, sides = 10, modifier = 5, exploding = true }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Advantage/Disadvantage Tests ---")
if test("advantage", "2d20kh1", { count = 2, sides = 20 }) then passed = passed + 1 else failed = failed + 1 end
if test("disadvantage", "2d20kl1", { count = 2, sides = 20 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Success Roll Tests ---")
if test("success", "6d6>>4", { count = 6, sides = 6, target = 4 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Sum vs Target Tests ---")
if test("sum_vs_target", "2d6>7", { count = 2, sides = 6 }) then passed = passed + 1 else failed = failed + 1 end
if test("sum_vs_target_fail", "1d20>15", { count = 1, sides = 20 }) then passed = passed + 1 else failed = failed + 1 end
if test("sum_vs_target_with_mod", "2d6+3>7", { count = 2, sides = 6 }) then passed = passed + 1 else failed = failed + 1 end
if test("sum_vs_target_neg_mod", "2d6-1>8", { count = 2, sides = 6 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Extended Comparison Tests ---")
if test("gte_success", "1d20>=15", { count = 1, sides = 20 }) then passed = passed + 1 else failed = failed + 1 end
if test("lte_fail", "1d20<=10", { count = 1, sides = 20 }) then passed = passed + 1 else failed = failed + 1 end
if test("vs_success", "1d100 vs 50", { count = 1, sides = 100 }) then passed = passed + 1 else failed = failed + 1 end
if test("vs_with_mod", "1d8+2 vs 12", { count = 1, sides = 8, modifier = 2 }) then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Fate Dice Tests ---")
do
  local result = dice.roll("4df")
  local ok = result and result.is_fate == true
    and type(result.display) == "string"
    and result.display:match("%d+df%[")
  if ok then
    print("PASS [fate: 4df basic] " .. result.display)
    passed = passed + 1
  else
    print("FAIL [fate: 4df basic] got nil or invalid")
    failed = failed + 1
  end
end
do
  local result = dice.roll("4df+1")
  local ok = result and result.modifier == 1 and result.is_fate == true
  if ok then
    print("PASS [fate: 4df with modifier] " .. result.display)
    passed = passed + 1
  else
    print("FAIL [fate: 4df with modifier]")
    failed = failed + 1
  end
end
do
  local result = dice.roll("2df")
  local ok = result and result.count == 2 and result.is_fate == true
    and (result.display:match("^2df%[") ~= nil)
  if ok then
    print("PASS [fate: 2df count] " .. result.display)
    passed = passed + 1
  else
    print("FAIL [fate: 2df count]")
    failed = failed + 1
  end
end

print()
print("--- Error Cases ---")
if test_error("invalid_empty", "") then passed = passed + 1 else failed = failed + 1 end
if test_error("invalid_no_d", "2x6") then passed = passed + 1 else failed = failed + 1 end
if test_error("invalid_letters", "abc") then passed = passed + 1 else failed = failed + 1 end

print()
print("--- Roll History Tests ---")

-- Need to reset history module state between runs
-- Test get_history returns empty for unknown buffer
do
  local h = dice.get_history(9999)
  if type(h) == "table" and #h == 0 then
    print("PASS [history: get_history returns empty for unknown buffer]")
    passed = passed + 1
  else
    print("FAIL [history: get_history returns empty for unknown buffer] expected empty array, got " .. tostring(h))
    failed = failed + 1
  end
end

-- Test add_to_history then get_history returns the entry
do
  local test_bufnr = 42
  local test_result = { original = "2d6", count = 2, sides = 6, rolls = { 3, 4 }, total = 7, display = "2d6[3, 4] = 7" }
  dice.add_to_history(test_bufnr, test_result, 10)
  local h = dice.get_history(test_bufnr)
  if type(h) == "table" and #h == 1 then
    local entry = h[1]
    if entry.line == 10 and entry.bufnr == test_bufnr and entry.result.original == "2d6" and entry.result.total == 7 then
      print("PASS [history: add_to_history then get_history returns entry]")
      passed = passed + 1
    else
      print("FAIL [history: add_to_history entry structure wrong]")
      failed = failed + 1
    end
  else
    print("FAIL [history: add_to_history then get_history] expected array with 1 entry, got " .. #h)
    failed = failed + 1
  end
end

-- Test clear_history clears
do
  dice.clear_history(42)
  local h = dice.get_history(42)
  if type(h) == "table" and #h == 0 then
    print("PASS [history: clear_history clears]")
    passed = passed + 1
  else
    print("FAIL [history: clear_history] expected empty array, got " .. #h)
    failed = failed + 1
  end
end

-- Test per-buffer isolation
do
  dice.add_to_history(1, { original = "1d20", total = 15 }, 5)
  dice.add_to_history(2, { original = "2d6", total = 7 }, 8)
  dice.add_to_history(2, { original = "1d4", total = 3 }, 10)

  local h1 = dice.get_history(1)
  local h2 = dice.get_history(2)

  if #h1 == 1 and #h2 == 2 then
    if h1[1].result.original == "1d20" and h2[1].result.original == "2d6" and h2[2].result.original == "1d4" then
      print("PASS [history: per-buffer isolation]")
      passed = passed + 1
    else
      print("FAIL [history: per-buffer isolation - wrong entries]")
      failed = failed + 1
    end
  else
    print("FAIL [history: per-buffer isolation] expected h1:1, h2:2, got h1:" .. #h1 .. " h2:" .. #h2)
    failed = failed + 1
  end

  -- Clean up
  dice.clear_history(1)
  dice.clear_history(2)
end

-- Test multiple entries preserve insertion order (triangulation)
do
  dice.add_to_history(10, { original = "1d4", total = 3 }, 1)
  dice.add_to_history(10, { original = "1d6", total = 5 }, 2)
  dice.add_to_history(10, { original = "1d8", total = 7 }, 3)

  local h = dice.get_history(10)
  if #h == 3
    and h[1].result.original == "1d4" and h[1].line == 1
    and h[2].result.original == "1d6" and h[2].line == 2
    and h[3].result.original == "1d8" and h[3].line == 3
  then
    print("PASS [history: multiple entries preserve insertion order]")
    passed = passed + 1
  else
    print("FAIL [history: multiple entries preserve insertion order]")
    failed = failed + 1
  end
  dice.clear_history(10)
end

-- Test nil bufnr defaults to 0 (current buffer) (triangulation)
do
  dice.add_to_history(0, { original = "1d20", total = 10 }, 5)
  local h = dice.get_history(nil)
  if #h == 1 and h[1].line == 5 and h[1].result.total == 10 then
    print("PASS [history: nil bufnr defaults to 0]")
    passed = passed + 1
  else
    print("FAIL [history: nil bufnr defaults to 0]")
    failed = failed + 1
  end
  dice.clear_history(0)
end

print()
print("=" .. string.rep("=", 70))
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 70))

if failed > 0 then
  os.exit(1)
end
