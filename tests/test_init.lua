#!/usr/bin/env lua

-- ============================================================================
-- TEST: init.lua roll dice / oracle capture to history before display
-- Task 2.1: After roll succeeds, call add_to_history BEFORE showing float
-- ============================================================================

package.path = package.path .. ";./lua/?.lua"

local roll_history_calls = {}
local oracle_history_calls = {}

-- Mock vim with everything init.lua needs
_G.vim = {
  api = {
    nvim_create_autocmd = function() end,
    nvim_create_augroup = function() return 1 end,
    nvim_get_current_buf = function() return 42 end,
  },
  fn = {
    line = function() return 10 end,
    hlexists = function() return true end,
  },
  cmd = function() end,
  notify = function() end,
  log = { levels = { ERROR = 1, WARN = 2 } },
  ui = {
    input = function(_, cb)
      cb("") -- Simulate empty input for mythic (keeps default chaos)
    end,
  },
}

-- Preload all submodule dependencies
package.preload["lonelog.config"] = function()
  return {
    setup = function() end,
    get = function()
      return {
        dice = { max_dice = 100, max_sides = 1000 },
        oracle = { default_table = "fate", persist_chaos = false, chaos_file = "chaos.txt" },
        highlight = {},
      }
    end,
  }
end

package.preload["lonelog.dice"] = function()
  return {
    setup = function() end,
    roll = function(notation)
      if notation == "bad" then
        return nil, "Invalid notation"
      end
      return {
        original = notation,
        count = 2,
        sides = 6,
        rolls = { 3, 4 },
        total = 7,
        display = notation .. "[3,4] = 7",
      }
    end,
    add_to_history = function(bufnr, result, line)
      table.insert(roll_history_calls, { bufnr = bufnr, result = result, line = line })
    end,
    get_history = function() return {} end,
    clear_history = function() end,
  }
end

package.preload["lonelog.oracle"] = function()
  return {
    load_chaos = function() end,
    roll = function(name)
      if name == "bad" then
        return nil, "Unknown table"
      end
      return {
        table = name,
        table_name = name == "mythic" and "Mythic" or "Fate",
        value = "yes",
        display = "Yes",
      }
    end,
    add_to_history = function(bufnr, result, line)
      table.insert(oracle_history_calls, { bufnr = bufnr, result = result, line = line })
    end,
    get_history = function() return {} end,
    clear_history = function() end,
    get_chaos = function() return 5 end,
    set_chaos = function(v) end,
    list_tables = function() return { "Binary", "Fate", "Mythic" } end,
    format_result = function(r) return "[" .. r.table_name .. "] " .. r.display end,
  }
end

package.preload["lonelog.ui"] = function()
  return {
    show_dice_result = function() end,
    show_oracle_result = function() end,
    pick = function() end,
  }
end

package.preload["lonelog.ui.floating"] = function()
  return {
    show_dice_result = function() end,
    show_oracle_result = function() end,
    insert_result = function() end,
    get_latest_content = function() return "" end,
  }
end

package.preload["lonelog.ui.picker"] = function()
  return { pick = function() end }
end

package.preload["lonelog.ui.parsers"] = function()
  return {
    tags = { show_tags_picker = function() end },
    scenes = { show_scenes_picker = function() end },
  }
end

-- Helper to get a fresh init module (clears package cache)
local function fresh_init()
  package.loaded["lonelog.init"] = nil
  for k, _ in pairs(package.loaded) do
    if k:match("^lonelog%.ui") or k:match("^lonelog%.(dice|oracle|config)") then
      package.loaded[k] = nil
    end
  end
  return require("lonelog.init")
end

local passed, failed = 0, 0

local function check(name, fn)
  local ok, err = pcall(fn)
  if ok then
    io.write("  PASS " .. name .. "\n")
    passed = passed + 1
  else
    io.write("  FAIL " .. name .. "\n")
    io.write("    " .. tostring(err) .. "\n")
    failed = failed + 1
  end
end

print("================================================================================")
print("INIT.LUA — ROLL CAPTURE TO HISTORY BEFORE DISPLAY")
print("================================================================================")

print("\n--- roll_dice capture to history ---\n")

roll_history_calls = {}

check("roll_dice captures to dice history before showing float", function()
  local init = fresh_init()
  init.roll_dice("2d6")
  assert(#roll_history_calls == 1, "add_to_history should be called once")
  local c = roll_history_calls[1]
  assert(c.bufnr == 42, "bufnr should be 42, got " .. tostring(c.bufnr))
  assert(c.line == 10, "line should be 10, got " .. tostring(c.line))
  assert(c.result.original == "2d6", "result.original should be 2d6, got " .. tostring(c.result.original))
end)

print("\n--- roll_oracle (non-mythic) capture to history ---\n")

oracle_history_calls = {}

check("roll_oracle non-mythic captures to oracle history before showing float", function()
  local init = fresh_init()
  init.roll_oracle("fate")
  assert(#oracle_history_calls == 1, "add_to_history should be called once")
  local c = oracle_history_calls[1]
  assert(c.bufnr == 42, "bufnr should be 42, got " .. tostring(c.bufnr))
  assert(c.line == 10, "line should be 10, got " .. tostring(c.line))
  assert(c.result.table == "fate", "result.table should be fate, got " .. tostring(c.result.table))
end)

print("\n--- Error handling: no capture on failure ---\n")

roll_history_calls = {}

check("roll_dice error does NOT capture to history", function()
  local init = fresh_init()
  local result, err = init.roll_dice("bad")
  assert(result == nil, "result should be nil")
  assert(err ~= nil, "should return error string")
  assert(#roll_history_calls == 0, "add_to_history should NOT be called on error, got " .. #roll_history_calls)
end)

oracle_history_calls = {}

check("roll_oracle error does NOT capture to history", function()
  local init = fresh_init()
  local result, err = init.roll_oracle("bad")
  assert(result == nil, "result should be nil")
  assert(err ~= nil, "should return error string")
  assert(#oracle_history_calls == 0, "add_to_history should NOT be called on error, got " .. #oracle_history_calls)
end)

print("\n--- Triangulation: mythic path ---\n")

oracle_history_calls = {}

check("roll_oracle mythic captures to history before display", function()
  local init = fresh_init()
  init.roll_oracle("mythic")
  -- vim.ui.input callback fires synchronously with "" → keeps default chaos → rolls mythic
  assert(#oracle_history_calls == 1, "add_to_history should be called for mythic, got " .. #oracle_history_calls)
  local c = oracle_history_calls[1]
  assert(c.result.table == "mythic", "result.table should be mythic, got " .. tostring(c.result.table))
end)

print("\n--- Triangulation: multiple rolls accumulate ---\n")

roll_history_calls = {}

check("multiple roll_dice calls accumulate history entries in order", function()
  local init = fresh_init()
  init.roll_dice("2d6")
  init.roll_dice("1d20")
  init.roll_dice("3d8")
  assert(#roll_history_calls == 3, "should have 3 history entries, got " .. #roll_history_calls)
  assert(roll_history_calls[1].result.original == "2d6")
  assert(roll_history_calls[2].result.original == "1d20")
  assert(roll_history_calls[3].result.original == "3d8")
end)

oracle_history_calls = {}

check("multiple roll_oracle calls accumulate history entries in order", function()
  local init = fresh_init()
  init.roll_oracle("fate")
  init.roll_oracle("binary")
  assert(#oracle_history_calls == 2, "should have 2 history entries, got " .. #oracle_history_calls)
  assert(oracle_history_calls[1].result.table == "fate")
  assert(oracle_history_calls[2].result.table == "binary")
end)

print()
print("================================================================================")
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("================================================================================")

if failed > 0 then
  os.exit(1)
end
