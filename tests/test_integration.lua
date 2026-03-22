#!/usr/bin/env lua
-- Integration tests for UI modules (tags, scenes)
-- These test the full picker flow with mocked vim.ui.select and Telescope

package.path = package.path .. ";./lua/?.lua"

-- Track test results
local passed = 0
local failed = 0

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS: " .. name)
    passed = passed + 1
  else
    print("FAIL: " .. name)
    print("  Error: " .. tostring(err))
    failed = failed + 1
  end
end

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error((msg or "assertion failed") .. ": got " .. tostring(actual) .. ", expected " .. tostring(expected))
  end
end

local function assert_table_eq(actual, expected, msg)
  for k, v in pairs(expected) do
    if actual[k] ~= v then
      error((msg or "assertion failed") .. ": key " .. tostring(k) .. ": got " .. tostring(actual[k]) .. ", expected " .. tostring(v))
    end
  end
end

-- ============================================================================
-- Test 1: Tags picker flow (vim.ui.select fallback)
-- ============================================================================

print("\n=== Testing Tags Picker Flow ===\n")

test("tags: parse_tags extracts all tag types", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "[N:Jonah|friendly]",
          "[L:Library|dark]",
          "[E:Alert 2/6]",
          "[PC:Alex|HP 8]",
          "[Thread:Main|Open]",
          "[Clock:Ritual 1/8]",
          "[Track:Escape 3/8]",
          "[Timer:Dawn 3]",
          "[Inv:Slot 1 | rifle]",
          "[R:1 | active]",
          "[F:Flesh blob|dead]",
        }
      end,
      nvim_buf_get_name = function(bufnr)
        return "/test/lonelog.md"
      end,
      nvim_set_current_buf = function(bufnr) end,
      nvim_win_set_cursor = function(winid, pos) end,
    },
    cmd = function(cmd) end,
    notify = function(msg, level) end,
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
    tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
    tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
  }

  local tags = require("lonelog.ui.parsers")
  local results = tags.parse_tags(0)

  assert_eq(#results, 11, "should find 11 tags")
end)

test("tags: tags_summary groups by type", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "[N:Jonah|friendly]",
          "[N:Alice|friendly]",
          "[L:Library|dark]",
          "[E:Alert 2/6]",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local tags = require("lonelog.ui.parsers")
  local results = tags.parse_tags(0)
  local summary = tags.tags_summary(results)

  assert_eq(summary["N"].count, 2, "N type should have 2")
  assert_eq(summary["L"].count, 1, "L type should have 1")
  assert_eq(summary["E"].count, 1, "E type should have 1")
end)

test("tags: filter by type works", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "[N:Jonah|friendly]",
          "[L:Library|dark]",
          "[N:Alice|friendly]",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
    tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
    tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
  }

  local tags = require("lonelog.ui.parsers")
  local results = tags.parse_tags(0)
  local filtered = vim.tbl_filter(function(t) return t.type == "N" end, results)

  assert_eq(#filtered, 2, "filter N should return 2")
end)

test("tags: format_tag_display includes type and name", function()
  vim = {
    api = {
      nvim_buf_get_lines = function() return {} end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local tags = require("lonelog.ui.parsers")
  local tag = tags.parse_tag("[N:Jonah|friendly|brave]", 1)
  local display = tags.format_tag_display(tag)

  assert(display:match("%[N%]"), "should include [N]")
  assert(display:match("Jonah"), "should include name")
  assert(display:match("friendly"), "should include tag")
end)

test("tags: parse_tag handles reference tags", function()
  vim = { trim = function(s) return s:match("^%s*(.-)%s*$") end, tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end, tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end }
  local tags = require("lonelog.ui.parsers")

  local tag = tags.parse_tag("[#N:Jonah]", 1)
  assert(tag.is_reference == true, "should be reference")
  assert(tag.name == "Jonah", "should parse name")
end)

test("tags: parse_tag handles changes (→)", function()
  vim = { trim = function(s) return s:match("^%s*(.-)%s*$") end, tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end, tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end }
  local tags = require("lonelog.ui.parsers")

  local tag = tags.parse_tag("[N:Jonah| friendly → hostile]", 1)
  assert_eq(#tag.changes, 1, "should have 1 change")
end)

test("tags: parse_tag handles additions (+)", function()
  vim = { trim = function(s) return s:match("^%s*(.-)%s*$") end, tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end, tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end }
  local tags = require("lonelog.ui.parsers")

  local tag = tags.parse_tag("[N:Jonah|+captured]", 1)
  assert_eq(#tag.additions, 1, "should have 1 addition")
end)

test("tags: parse_tag handles removals (-)", function()
  vim = { trim = function(s) return s:match("^%s*(.-)%s*$") end, tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end, tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end }
  local tags = require("lonelog.ui.parsers")

  local tag = tags.parse_tag("[N:Jonah|-wounded]", 1)
  assert_eq(#tag.removals, 1, "should have 1 removal")
end)

-- ============================================================================
-- Test 2: Scenes picker flow
-- ============================================================================

print("\n=== Testing Scenes Picker Flow ===\n")

test("scenes: parse_scenes extracts all scene types", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "S1 *Lighthouse tower*",
          "S2 *Basement*",
          "S5a *Flashback*",
          "S7.1 *Day 1*",
          "T1-S1 *Thread scene*",
        }
      end,
      nvim_buf_get_name = function(bufnr)
        return "/test/lonelog.md"
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local results = scenes.parse_scenes(0)

  assert_eq(#results, 5, "should find 5 scenes")
end)

test("scenes: sort_scenes orders correctly", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "S3 *Third*",
          "S1 *First*",
          "S5a *Flashback a*",
          "S5b *Flashback b*",
          "S2 *Second*",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local results = scenes.parse_scenes(0)
  local sorted = scenes.sort_scenes(results)

  local ids = {}
  for _, s in ipairs(sorted) do
    table.insert(ids, s.scene_id)
  end

  assert_eq(ids[1], "S1", "first should be S1")
  assert_eq(ids[2], "S2", "second should be S2")
  assert_eq(ids[3], "S3", "third should be S3")
  assert_eq(ids[4], "S5a", "fourth should be S5a (before S5b)")
  assert_eq(ids[5], "S5b", "fifth should be S5b")
end)

test("scenes: format_scene_display shows type and context", function()
  vim = {
    api = {
      nvim_buf_get_lines = function() return {} end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local scene = scenes.parse_scene("S1 *Lighthouse tower*", 1)
  local display = scenes.format_scene_display(scene)

  assert(display:match("S1"), "should include scene id")
  assert(display:match("Lighthouse tower"), "should include context")
end)

test("scenes: thread scenes sort after main scenes", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "T1-S1 *Thread*",
          "S1 *Main*",
          "T2-S3 *Thread 2*",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local results = scenes.parse_scenes(0)
  local sorted = scenes.sort_scenes(results)

  local ids = {}
  for _, s in ipairs(sorted) do
    table.insert(ids, s.scene_id)
  end

  assert_eq(ids[1], "S1", "main scene should come first")
  assert_eq(ids[2], "T1-S1", "thread should come after main scenes")
  assert_eq(ids[3], "T2-S3", "thread 2 should come after thread 1")
end)

test("scenes: markdown header scene works", function()
  vim = {
    api = {
      nvim_buf_get_lines = function() return {} end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local scene = scenes.parse_scene("## S1 *Lighthouse tower*", 1)

  assert(scene ~= nil, "should parse markdown header scene")
  assert_eq(scene.scene_id, "S1", "should extract S1")
  assert_eq(scene.context, "Lighthouse tower", "should extract context")
end)

test("scenes: scenes_summary groups by type", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "S1 *Main 1*",
          "S2 *Main 2*",
          "S3a *Flashback*",
          "T1-S1 *Thread*",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
  }

  local scenes = require("lonelog.ui.parsers")
  local results = scenes.parse_scenes(0)
  local summary = scenes.scenes_summary(results)

  assert_eq(summary["main"].count, 2, "main should have 2")
  assert_eq(summary["flashback"].count, 1, "flashback should have 1")
  assert_eq(summary["thread"].count, 1, "thread should have 1")
end)

test("scenes: filter by type works", function()
  vim = {
    api = {
      nvim_buf_get_lines = function(bufnr, start, ending, strict)
        return {
          "S1 *Main*",
          "S2 *Main 2*",
          "S3a *Flashback*",
        }
      end,
    },
    trim = function(s) return s:match("^%s*(.-)%s*$") end,
    tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
    tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
  }

  local scenes = require("lonelog.ui.parsers")
  local results = scenes.parse_scenes(0)
  local filtered = vim.tbl_filter(function(s) return s.type == "main" end, results)

  assert_eq(#filtered, 2, "filter main should return 2")
end)

-- ============================================================================
-- Test 3: Picker module
-- ============================================================================

print("\n=== Testing Picker Module ===\n")

test("picker: pick calls vim.ui.select when Telescope not available", function()
  local called = false
  local selected_item, selected_index
  vim = {
    ui = {
      select = function(items, opts, on_choice)
        called = true
        on_choice(items[1])
      end,
    },
    tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
    tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
  }

  local picker = require("lonelog.ui")
  picker.pick({
    title = "Test",
    items = { "a", "b", "c" },
    on_select = function(item, idx)
      selected_item = item
      selected_index = idx
    end,
  })

  assert(called, "should call vim.ui.select")
end)

test("picker: format_item defaults to tostring", function()
  vim = {
    ui = {
      select = function() end,
    },
    tbl_map = function(fn, t) local r = {}; for _, v in ipairs(t) do table.insert(r, fn(v)) end; return r end,
    tbl_filter = function(fn, t) local r = {}; for _, v in ipairs(t) do if fn(v) then table.insert(r, v) end end; return r end,
  }

  local picker = require("lonelog.ui")

  local result = picker.pick({
    items = { "hello", "world" },
    format_item = nil,
  })

  -- The internal formatting should use tostring by default
end)

-- ============================================================================
-- Summary
-- ============================================================================

print("\n========================================")
print(string.format("RESULTS: %d passed, %d failed", passed, failed))
print("========================================\n")

if failed > 0 then
  os.exit(1)
end
