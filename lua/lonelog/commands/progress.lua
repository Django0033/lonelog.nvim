local M = {}

local TYPE_ALIASES = {
  E = { "E", "CLOCK" },
  CLOCK = { "E", "CLOCK" },
  TRACK = { "TRACK" },
  TIMER = { "TIMER" },
}

local function parse_value(val_str)
  if not val_str or val_str == "" then
    return nil, nil
  end
  local current, max_val = val_str:match("^(%d+)/(%d+)$")
  if current then
    return tonumber(current), tonumber(max_val)
  end
  local single = tonumber(val_str)
  if single then
    return single, nil
  end
  return nil, nil
end

function M.find_in_lines(lines, type_key, name)
  local patterns = TYPE_ALIASES[type_key:upper()]
  if not patterns then
    return nil
  end

  local lower_name = name:lower()

  for line_num, line in ipairs(lines) do
    for tag_type, content in line:gmatch("%[(%w+):([^%]]+)%]") do
      local type_upper = tag_type:upper()
      local type_match = false
      for _, p in ipairs(patterns) do
        if type_upper == p then
          type_match = true
          break
        end
      end
      if not type_match then
        goto continue
      end

      local segment = content:match("^([^%|]+)")
      if not segment then
        goto continue
      end

      local seg_name, val_str = segment:match("^(.-)%s+(%d+/?%d*)$")
      if not seg_name then
        goto continue
      end

      seg_name = seg_name:gsub("^%s+", ""):gsub("%s+$", "")

      if seg_name:lower() == lower_name then
        local current, max_val = parse_value(val_str)
        if current ~= nil then
          return {
            line_num = line_num,
            line_text = line,
            current = current,
            max = max_val,
            type_used = type_upper,
          }
        end
      end
      ::continue::
    end
  end

  return nil
end

function M.is_complete(type_key, current, max_val)
  local upper = type_key:upper()
  if upper == "TIMER" then
    return current <= 0
  end
  return max_val ~= nil and current >= max_val
end

function M.increment_in_lines(lines, type_key, name, max_default)
  local found = M.find_in_lines(lines, type_key, name)

  if found then
    local complete = M.is_complete(found.type_used, found.current, found.max)
    if not complete then
      local new_val
      if type_key:upper() == "TIMER" then
        new_val = found.current - 1
      else
        new_val = found.current + 1
      end

      local old_val_str = tostring(found.current)
        .. (found.max and "/" .. found.max or "")
      local new_val_str = tostring(new_val)
        .. (found.max and "/" .. found.max or "")
      local escaped_old = old_val_str:gsub("([%^%$()%%%.%[%]%*%+%-%?])", "%%%1")
      local new_line = found.line_text:gsub(
        "(" .. escaped_old .. ")([%|%]])",
        new_val_str .. "%2"
      )
      lines[found.line_num] = new_line

      return {
        action = "incremented",
        line_num = found.line_num,
        new_value = new_val,
      }
    end
  end

  return {
    action = "insert_fresh",
    type_key = type_key,
    name = name,
    max_default = max_default or 5,
  }
end

function M.insert_fresh_tag(type_key, name, max_default)
  local upper = type_key:upper()
  if upper == "TIMER" then
    return "[Timer:" .. name .. " 0]"
  end
  if upper == "E" or upper == "CLOCK" then
    return "[E:" .. name .. " 0/" .. (max_default or 5) .. "]"
  end
  return "[Track:" .. name .. " 0/" .. (max_default or 5) .. "]"
end

function M.check_needs_insert(type_key, name)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found = M.find_in_lines(lines, type_key, name)
  if not found then
    return true
  end
  return M.is_complete(found.type_used, found.current, found.max)
end

function M.increment_progress(type_key, name, max_default)
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]

  local result = M.increment_in_lines(lines, type_key, name, max_default)

  if result.action == "incremented" then
    vim.api.nvim_buf_set_lines(
      bufnr,
      result.line_num - 1,
      result.line_num,
      false,
      { lines[result.line_num] }
    )
    vim.notify(
      "lonelog: " .. name .. " " .. (type_key:upper() == "TIMER" and "decremented" or "incremented")
        .. " to " .. result.new_value,
      vim.log.levels.INFO
    )
  elseif result.action == "insert_fresh" then
    local tag = M.insert_fresh_tag(result.type_key, result.name, result.max_default)
    vim.api.nvim_buf_set_lines(bufnr, cursor_line, cursor_line, false, { tag, "" })
    vim.api.nvim_win_set_cursor(0, { cursor_line + 1, #tag - 2 })
    vim.notify(
      "lonelog: Inserted fresh " .. type_key,
      vim.log.levels.INFO
    )
  end

  return result
end

return M
