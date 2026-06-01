local M = {}

M.floating = require("lonelog.ui.floating")
M.sidebar = require("lonelog.ui.sidebar")
M.picker = require("lonelog.ui.picker")

-- Export aliases for commonly accessed functions
M.show_dice_result = M.floating.show_dice_result
M.show_oracle_result = M.floating.show_oracle_result
M.insert_result = M.floating.insert_result
M.get_latest_content = M.floating.get_latest_content
M.pick = M.picker.pick

return M
