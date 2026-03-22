local M = {}

-- Seed random number generator with current time
math.randomseed(os.time())

-- Roll a single die with given number of sides
local function roll_die(sides) return math.random(1, sides) end

-- Parse dice notation string into components
-- Example: "2d6+3" -> {count=2, sides=6, modifier=3}
local function parse_notation(notation)
  -- Initialize with all possible options set to 0 or false
  local p = { original = notation, count = 0, sides = 0, modifier = 0, keep_highest = 0, keep_lowest = 0, exploding = false, target = 0, target_mode = nil }
  notation = notation:gsub("%s+", ""):upper()

  -- Check for exploding dice (e.g., "4d6!")
  if notation:match("!+") then p.exploding = true; notation = notation:gsub("!+", "") end

  -- Check for success counting mode (e.g., "6d6>>4")
  local mt = notation:match(">>%d+"); if mt then p.target = tonumber(mt:sub(3)); p.target_mode = "successes"; notation = notation:gsub(">>%d+", "") end

  -- Check for sum vs target mode (e.g., "2d6>7")
  mt = notation:match(">%d+"); if mt then p.target = tonumber(mt:sub(2)); p.target_mode = "sum"; notation = notation:gsub(">%d+", "") end

  -- Extract dice count and sides (e.g., "2d6")
  local c, s = notation:match("^(%d+)[dD](%d+)"); if c and s then p.count = tonumber(c); p.sides = tonumber(s) else return nil end

  -- Extract modifier (e.g., "+3" or "-2")
  local mod = notation:match("[+-]%d+$"); if mod then p.modifier = tonumber(mod) end

  return p
end

-- Roll a single die, handling exploding dice recursively
local function roll_single(sides, exploding, exploded)
  exploded = exploded or {}
  local roll = roll_die(sides)
  table.insert(exploded, roll)
  -- If exploding and rolled max, roll again (max 100 rolls to prevent infinite loops)
  if exploding and roll == sides and #exploded < 100 then return roll_single(sides, exploding, exploded) end
  return exploded
end

-- Main dice rolling function
-- Parses notation, rolls dice, and returns result object
function M.roll(notation)
  if type(notation) ~= "string" then return nil, "Notation must be a string" end
  local parsed = parse_notation(notation)
  if not parsed then return nil, "Invalid dice notation: " .. notation end
  local cfg = require("lonelog.config").get()
  if parsed.count > cfg.dice.max_dice then return nil, "Too many dice (max: " .. cfg.dice.max_dice .. ")" end
  if parsed.sides > cfg.dice.max_sides then return nil, "Too many sides (max: " .. cfg.dice.max_sides .. ")" end

  -- Roll all dice (each die may produce multiple rolls if exploding)
  local all_rolls = {}
  for i = 1, parsed.count do for _, r in ipairs(roll_single(parsed.sides, parsed.exploding, {})) do table.insert(all_rolls, r) end end

  -- Apply keep highest/lowest if specified
  local kept = all_rolls
  if parsed.keep_highest > 0 then table.sort(all_rolls, function(a, b) return a > b end); kept = vim.list_slice(all_rolls, 1, parsed.keep_highest)
  elseif parsed.keep_lowest > 0 then table.sort(all_rolls, function(a, b) return a < b end); kept = vim.list_slice(all_rolls, 1, parsed.keep_lowest) end

  -- Calculate total based on target mode
  local total = 0
  if parsed.target > 0 then
    if parsed.target_mode == "sum" then for _, r in ipairs(kept) do total = total + r end; total = total + parsed.modifier
    else for _, r in ipairs(kept) do if r >= parsed.target then total = total + 1 end end end
  else for _, r in ipairs(kept) do total = total + r end; total = total + parsed.modifier end

  -- Build display string
  local parts, dice_str = {}, parsed.count .. "d" .. parsed.sides
  if parsed.exploding then dice_str = dice_str .. "!" end
  if parsed.keep_highest > 0 then dice_str = dice_str .. "kh" .. parsed.keep_highest elseif parsed.keep_lowest > 0 then dice_str = dice_str .. "kl" .. parsed.keep_lowest end
  if parsed.target > 0 then
    if parsed.modifier ~= 0 then local s = parsed.modifier > 0 and "+" or ""; dice_str = dice_str .. s .. parsed.modifier end
    dice_str = dice_str .. (parsed.target_mode == "successes" and ">>" or ">") .. parsed.target
  elseif parsed.modifier ~= 0 then local s = parsed.modifier > 0 and "+" or ""; dice_str = dice_str .. s .. parsed.modifier end
  table.insert(parts, dice_str)
  table.insert(parts, "[" .. table.concat(kept, ", ") .. "]")

  if parsed.target > 0 then
    if parsed.target_mode == "successes" then table.insert(parts, " successes") else
      local sum = 0; for _, r in ipairs(kept) do sum = sum + r end; sum = sum + parsed.modifier
      table.insert(parts, string.format(" = %d vs %d -> %s", sum, parsed.target, sum >= parsed.target and "Success" or "Fail")); total = sum end
  elseif parsed.modifier ~= 0 then table.insert(parts, " = " .. tostring(total)) else table.insert(parts, " = " .. tostring(total)) end

  return { original = notation, count = parsed.count, sides = parsed.sides, rolls = kept, all_rolls = all_rolls, modifier = parsed.modifier, target = parsed.target, exploding = parsed.exploding, total = total, display = table.concat(parts, "") }
end

-- Quick roll helpers for common dice
for _, d in ipairs({ { "d4", "1d4" }, { "d6", "1d6" }, { "d8", "1d8" }, { "d10", "1d10" }, { "d12", "1d12" }, { "d20", "1d20" }, { "d100", "1d100" } }) do
  M[d[1]] = function() return M.roll(d[2]) end
end

return M
