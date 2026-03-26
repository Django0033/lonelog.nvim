local M = {}

M.floating = require("lonelog.ui.floating")
M.sidebar = require("lonelog.ui.sidebar")
M.picker = require("lonelog.ui.picker")

-- Exports aliases for backward compatibility
M.show_result = M.floating.show_result
M.show_colored_result = M.floating.show_colored_result
M.show_dice_result = M.floating.show_dice_result
M.show_oracle_result = M.floating.show_oracle_result
M.copy_result = M.floating.copy_result
M.insert_result = M.floating.insert_result
M.get_latest_content = M.floating.get_latest_content
M.can_insert_here = M.floating.can_insert_here
M.pick = M.picker.pick
M.open = M.floating.open
M.close = M.floating.close

return M
