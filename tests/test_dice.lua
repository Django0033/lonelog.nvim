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
print("--- Error Cases ---")
if test_error("invalid_empty", "") then passed = passed + 1 else failed = failed + 1 end
if test_error("invalid_no_d", "2x6") then passed = passed + 1 else failed = failed + 1 end
if test_error("invalid_letters", "abc") then passed = passed + 1 else failed = failed + 1 end

print()
print("=" .. string.rep("=", 70))
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 70))

if failed > 0 then
  os.exit(1)
end
