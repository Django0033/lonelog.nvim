#!/usr/bin/env lua

package.path = package.path .. ";./lua/?.lua"

local progress = require("lonelog.commands.progress")

local passed = 0
local failed = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("  PASS " .. name)
    passed = passed + 1
  else
    print("  FAIL " .. name)
    print("    " .. tostring(err))
    failed = failed + 1
  end
  return ok
end

local function assert_eq(a, b, msg)
  if a ~= b then
    error((msg or "assertion failed") .. ": got " .. tostring(a) .. ", expected " .. tostring(b))
  end
end

local function assert_match(str, pattern, msg)
  if not str:match(pattern) then
    error((msg or "pattern match failed") .. ": '" .. tostring(str) .. "' does not match '" .. tostring(pattern) .. "'")
  end
end

local function assert_nil(val, msg)
  if val ~= nil then
    error((msg or "expected nil") .. ": got " .. tostring(val))
  end
end

print("=== find_in_lines ===")
print()

do
  local lines = { "[N:Jonah|friendly]", "[E:Alert 2/6]", "[Track:Escape 3/8]" }
  local result = progress.find_in_lines(lines, "E", "Alert")
  test("finds existing clock by name", function()
    assert_eq(result.line_num, 2)
    assert_eq(result.current, 2)
    assert_eq(result.max, 6)
    assert_eq(result.type_used, "E")
  end)
end

do
  local lines = { "[E:Alert 2/6]", "[E:Other 1/4]" }
  local result = progress.find_in_lines(lines, "E", "Other")
  test("finds second clock when multiple exist", function()
    assert_eq(result.line_num, 2)
    assert_eq(result.current, 1)
    assert_eq(result.max, 4)
  end)
end

do
  local lines = { "[Clock:Ritual 1/8]" }
  local result = progress.find_in_lines(lines, "E", "Ritual")
  test("finds Clock: alias as E type", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 1)
    assert_eq(result.max, 8)
  end)
end

do
  local lines = { "[E:Alert 2/6]" }
  local result = progress.find_in_lines(lines, "E", "alert")
  test("match is case-insensitive", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 2)
  end)
end

do
  local lines = { "[Track:Escape 3/8]" }
  local result = progress.find_in_lines(lines, "TRACK", "Escape")
  test("finds existing track", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 3)
    assert_eq(result.max, 8)
  end)
end

do
  local lines = { "[Timer:Dawn 3]" }
  local result = progress.find_in_lines(lines, "TIMER", "Dawn")
  test("finds existing timer (no max)", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 3)
    assert_eq(result.max, nil)
  end)
end

do
  local lines = { "[E:Alert 2/6]" }
  local result = progress.find_in_lines(lines, "E", "Nonexistent")
  test("returns nil when not found", function()
    assert_eq(result, nil)
  end)

do
  local lines = { "[N:Jonah|friendly] [E:Alert 2/6]" }
  local result = progress.find_in_lines(lines, "E", "Alert")
  test("finds progress tag even when other tags precede it on same line", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 2)
    assert_eq(result.max, 6)
  end)
end
end

do
  local lines = { "[Track:Ritual 2/6|urgent]" }
  local result = progress.find_in_lines(lines, "TRACK", "Ritual")
  test("finds track with pipe and tags", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 2)
    assert_eq(result.max, 6)
  end)
end

do
  local lines = { "[E: camp ritual 3/6]" }
  local result = progress.find_in_lines(lines, "E", "camp ritual")
  test("finds clock with spaces in name", function()
    assert_eq(result.line_num, 1)
    assert_eq(result.current, 3)
    assert_eq(result.max, 6)
  end)
end

print()
print("=== is_complete ===")
print()

test("clock at max is complete", function()
  assert_eq(progress.is_complete("E", 6, 6), true)
end)

test("clock below max is not complete", function()
  assert_eq(progress.is_complete("E", 3, 6), false)
end)

test("timer at zero is complete", function()
  assert_eq(progress.is_complete("TIMER", 0, nil), true)
end)

test("timer above zero is not complete", function()
  assert_eq(progress.is_complete("TIMER", 3, nil), false)
end)

test("clock with nil max is not complete", function()
  assert_eq(progress.is_complete("E", 5, nil), false)
end)

test("empty lines table returns nil", function()
  assert_eq(progress.find_in_lines({}, "E", "Test"), nil)
end)

print()
print("=== increment_in_lines (increments) ===")
print()

do
  local lines = { "[N:Jonah]", "[E:Alert 2/6]", "[Track:Escape 3/8]" }
  local result = progress.increment_in_lines(lines, "E", "Alert", 6)
  test("clock increments existing", function()
    assert_eq(result.action, "incremented")
    assert_eq(result.line_num, 2)
    assert_eq(result.new_value, 3)
    assert_match(lines[2], "E:Alert 3/6")
  end)
end

do
  local lines = { "[Track:Escape 3/8]" }
  local result = progress.increment_in_lines(lines, "TRACK", "Escape", 6)
  test("track increments existing", function()
    assert_eq(result.action, "incremented")
    assert_eq(result.new_value, 4)
    assert_match(lines[1], "Track:Escape 4/8")
  end)
end

do
  local lines = { "[Timer:Dawn 3]" }
  local result = progress.increment_in_lines(lines, "TIMER", "Dawn", nil)
  test("timer decrements existing", function()
    assert_eq(result.action, "incremented")
    assert_eq(result.new_value, 2)
    assert_match(lines[1], "Timer:Dawn 2")
  end)
end

do
  local lines = { "[Track:Ritual 2/6|urgent]" }
  local result = progress.increment_in_lines(lines, "TRACK", "Ritual", 6)
  test("track with pipe preserves tags after increment", function()
    assert_eq(result.action, "incremented")
    assert_eq(result.new_value, 3)
    assert_match(lines[1], "Track:Ritual 3/6|urgent")
  end)
end

print()
print("=== increment_in_lines (complete/existing) ===")
print()

do
  local lines = { "[E:Alert 6/6]" }
  local result = progress.increment_in_lines(lines, "E", "Alert", 6)
  test("clock at max returns insert_fresh", function()
    assert_eq(result.action, "insert_fresh")
    assert_eq(result.type_key, "E")
    assert_eq(result.name, "Alert")
  end)
end

do
  local lines = { "[Timer:Dawn 0]" }
  local result = progress.increment_in_lines(lines, "TIMER", "Dawn")
  test("timer at 0 returns insert_fresh", function()
    assert_eq(result.action, "insert_fresh")
    assert_eq(result.type_key, "TIMER")
    assert_eq(result.name, "Dawn")
  end)

  do
    local lines = { "[Timer:Step3 3]" }
    local result = progress.increment_in_lines(lines, "TIMER", "Step3", nil)
    test("timer with digit in name preserves name on decrement", function()
      assert_eq(result.action, "incremented")
      assert_eq(result.new_value, 2)
      assert_match(lines[1], "Timer:Step3 2")
      assert(not lines[1]:match("Timer:Step2"))
    end)
  end
end

do
  local lines = { "[E:Other 1/4]" }
  local result = progress.increment_in_lines(lines, "E", "Alert")
  test("not found returns insert_fresh", function()
    assert_eq(result.action, "insert_fresh")
    assert_eq(result.name, "Alert")
    assert_eq(result.max_default, 5)
  end)
end

print()
print("=== insert_fresh_tag ===")
print()

test("clock tag format", function()
  local tag = progress.insert_fresh_tag("E", "Alert", 5)
  assert_eq(tag, "[E:Alert 0/5]")
end)

test("clock tag with Clock: alias", function()
  local tag = progress.insert_fresh_tag("CLOCK", "Ritual", 8)
  assert_eq(tag, "[E:Ritual 0/8]")
end)

test("track tag format", function()
  local tag = progress.insert_fresh_tag("TRACK", "Escape", 8)
  assert_eq(tag, "[Track:Escape 0/8]")
end)

test("timer tag format", function()
  local tag = progress.insert_fresh_tag("TIMER", "Dawn", nil)
  assert_eq(tag, "[Timer:Dawn 0]")
end)

print()
print("=" .. string.rep("=", 60))
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 60))

if failed > 0 then
  os.exit(1)
end
