-- Set up all plugin keybindings

local function insert_text(text, cursor_offset)
	vim.api.nvim_put({ text }, "c", true, true)
	if cursor_offset then
		local row = vim.fn.line(".")
		local col = vim.fn.col(".") - cursor_offset
		vim.api.nvim_win_set_cursor(0, { row, col })
	end
end

local ACTION_TEMPLATE = {
	"@ [action]",
	"d: [roll] -> [outcome]",
	"=> [consequence]",
}

local ORACLE_TEMPLATE = {
	"? [question]",
	"-> [answer]",
	"=> [consequence]",
}

-- Insert multiline template at cursor and position cursor
local function insert_template_at_cursor(template, cursor_line, cursor_col)
	local row = vim.fn.line(".") - 1
	local col = vim.fn.col(".") - 1
	vim.api.nvim_buf_set_text(0, row, col, row, col, template)
	vim.api.nvim_win_set_cursor(0, { row + 1 + cursor_line, cursor_col })
end

-- Insert auto-numbered scene marker above current line
-- Prompts for context if config.prompt_for_scene_context is true
local function insert_scene_marker()
	local scenes_mod = require("lonelog.parsers.scenes")
	local cfg = require("lonelog.config").get()
	local next_id = scenes_mod.generate_next_scene_id()

	local context
	if cfg.prompt_for_scene_context then
		context = vim.fn.input("Scene context: ")
		if context == "" then context = nil end
	end

	local text = scenes_mod.build_scene_line(next_id, context)
	local row = vim.fn.line(".") - 1
	vim.api.nvim_buf_set_lines(0, row, row, false, { text, "" })
	vim.api.nvim_win_set_cursor(0, { row + 1, #("### " .. next_id .. " ") })
end

local function setup_keymaps()
	local cfg = require("lonelog.config")
	local solo = require("lonelog")
	local function map(mode, lhs, rhs, opts)
		vim.keymap.set(mode, lhs, rhs, opts or { silent = true })
	end

	-- ================================================================
	-- Group 1: Main actions (uppercase)
	-- ================================================================

	map("n", cfg.get().keymaps.oracle, function()
		solo.ui.pick({
			title = "Choose the Oracle",
			items = solo.oracle.list_tables(),
			on_select = function(t)
				solo.roll_oracle(t)
			end,
		})
	end, { desc = "Lonelog Oracle" })
	map("n", cfg.get().keymaps.dice, function()
		vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
			if n and n ~= "" then
				solo.roll_dice(n)
			end
		end)
	end, { desc = "Roll Dice" })
	map("n", cfg.get().keymaps.tags, function()
		solo.parsers.tags.show_tags_picker()
	end, { desc = "Navigate Tags" })
	map("n", cfg.get().keymaps.scenes, function()
		solo.parsers.scenes.show_scenes_picker()
	end, { desc = "Navigate Scenes" })
	map("n", cfg.get().keymaps.chaos, function()
		solo.oracle.show_chaos_ui()
	end, { desc = "Chaos Factor UI" })
	map("n", cfg.get().keymaps.session_header, function()
		require("lonelog.commands.session").insert_session_header()
	end, { desc = "Insert session header" })
	map("n", cfg.get().keymaps.narrative_block, function()
		require("lonelog.commands.narrative").insert_narrative_block()
	end, { desc = "Insert narrative block" })
	map("n", cfg.get().keymaps.insert_result, function()
		local w, c = solo.ui.get_latest_content()
		if c then
			solo.ui.insert_result(w)
		else
			vim.notify("lonelog: No result to insert", vim.log.levels.WARN)
		end
	end, { desc = "Insert result" })
	map("n", cfg.get().keymaps.scene_marker, function()
		insert_scene_marker()
	end, { desc = "Insert auto-numbered scene" })
	map("n", cfg.get().keymaps.scene_prev, function()
		require("lonelog.parsers.scenes").navigate_scene(-1)
	end, { desc = "Previous scene" })
	map("n", cfg.get().keymaps.scene_next, function()
		require("lonelog.parsers.scenes").navigate_scene(1)
	end, { desc = "Next scene" })
	map("n", cfg.get().keymaps.roll_line, function()
		require("lonelog.roll_line").roll_current_line()
	end, { desc = "Lonelog roll on current line" })

	-- ================================================================
	-- Group 2: Insert notation symbols (li-)
	-- ================================================================

	map("n", cfg.get().keymaps.insert_action, function()
		insert_text("@ ")
	end, { desc = "Insert action marker @" })
	map("n", cfg.get().keymaps.insert_question, function()
		insert_text("? ")
	end, { desc = "Insert oracle question ?" })
	map("n", cfg.get().keymaps.insert_dice, function()
		insert_text("d: ")
	end, { desc = "Insert dice roll d:" })
	map("n", cfg.get().keymaps.insert_note, function()
		require("lonelog.commands.note").insert_note()
	end, { desc = "Insert (note:)" })
	map("n", cfg.get().keymaps.insert_arrow, function()
		insert_text(" -> ")
	end, { desc = "Insert result arrow ->" })
	map("n", cfg.get().keymaps.insert_conseq, function()
		insert_text("=> ")
	end, { desc = "Insert consequence =>" })

	-- Actor action marker
	map("n", cfg.get().keymaps.actor_action, function()
		insert_text("@(|) ", 3)
	end, { desc = "Insert actor action @(Name)" })

	-- Multi-line notation sequences
	map("n", cfg.get().keymaps.action_seq, function()
		insert_template_at_cursor(ACTION_TEMPLATE, 0, 3)
	end, { desc = "Insert action sequence" })
	map("n", cfg.get().keymaps.oracle_seq, function()
		insert_template_at_cursor(ORACLE_TEMPLATE, 0, 2)
	end, { desc = "Insert oracle sequence" })

	-- ================================================================
	-- Group 3: Entity tags (lt-)
	-- ================================================================

	map("n", cfg.get().keymaps.tag_npc, function()
		insert_text("[N:|]", 2)
	end, { desc = "Insert NPC tag" })
	map("n", cfg.get().keymaps.tag_location, function()
		insert_text("[L:|]", 2)
	end, { desc = "Insert location tag" })
	map("n", cfg.get().keymaps.tag_pc, function()
		insert_text("[PC:|]", 2)
	end, { desc = "Insert PC tag" })
	map("n", cfg.get().keymaps.tag_thread, function()
		insert_text("[Thread:|Open]", 6)
	end, { desc = "Insert thread tag" })
	map("n", cfg.get().keymaps.tag_ref, function()
		insert_text("[#N:|]", 2)
	end, { desc = "Insert reference tag" })
	map("n", cfg.get().keymaps.tag_foe, function()
		insert_text("[F:|]", 2)
	end, { desc = "Insert foe tag" })

	-- ================================================================
	-- Group 4: Progress elements (lp-)
	-- ================================================================

	map("n", cfg.get().keymaps.progress_clock, function()
		vim.cmd("LonelogInsertClock")
	end, { desc = "Insert/increment clock" })
	map("n", cfg.get().keymaps.progress_track, function()
		vim.cmd("LonelogInsertTrack")
	end, { desc = "Insert/increment track" })
	map("n", cfg.get().keymaps.progress_timer, function()
		vim.cmd("LonelogInsertTimer")
	end, { desc = "Insert/decrement timer" })

	-- ================================================================
	-- Group 5: Quick dice (ld-)
	-- ================================================================

	local quick_dice = {
		{ key = "d4", dice = "1d4" },
		{ key = "d6", dice = "1d6" },
		{ key = "d8", dice = "1d8" },
		{ key = "d10", dice = "1d10" },
		{ key = "d12", dice = "1d12" },
		{ key = "d20", dice = "1d20" },
		{ key = "d100", dice = "1d100" },
	}
	for _, q in ipairs(quick_dice) do
		local km = cfg.get().keymaps[q.key]
		if km then
			map("n", km, function()
				solo.roll_dice(q.dice)
			end, { desc = "Roll " .. q.dice })
		end
	end

	-- ================================================================
	-- Insert mode (C-l)
	-- ================================================================

	-- Notation symbols
	map("i", "<C-l>a", function()
		insert_text("@ ")
	end, { desc = "Insert action marker @" })
	map("i", "<C-l>N", function()
		insert_text("@(|) ", 3)
	end, { desc = "Insert actor action @(Name)" })
	map("i", "<C-l>q", function()
		insert_text("? ")
	end, { desc = "Insert oracle question ?" })
	map("i", "<C-l>d", function()
		insert_text("d: ")
	end, { desc = "Insert dice roll d:" })
	map("i", "<C-l>-", function()
		insert_text(" -> ")
	end, { desc = "Insert result arrow ->" })
	map("i", "<C-l>=", function()
		insert_text("=> ")
	end, { desc = "Insert consequence =>" })

	-- Entity tags
	map("i", "<C-l>n", function()
		insert_text("[N:|]", 3)
	end, { desc = "Insert NPC tag" })
	map("i", "<C-l>l", function()
		insert_text("[L:|]", 3)
	end, { desc = "Insert location tag" })
	map("i", "<C-l>p", function()
		insert_text("[PC:|]", 3)
	end, { desc = "Insert PC tag" })
	map("i", "<C-l>h", function()
		insert_text("[Thread:|Open]", 7)
	end, { desc = "Insert thread tag" })
	map("i", "<C-l>r", function()
		insert_text("[#N:|]", 3)
	end, { desc = "Insert reference tag" })
	map("i", "<C-l>f", function()
		insert_text("[F:|]", 3)
	end, { desc = "Insert foe tag" })

	-- Tag completion
	map("i", cfg.get().keymaps.complete_tag, function()
		local ok, err = pcall(require("lonelog.completion").complete_tag)
		if not ok then
			vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { desc = "Complete Lonelog tag" })

	-- ================================================================
	-- Visual mode (reuse action keys for selected text)
	-- ================================================================

	map("v", cfg.get().keymaps.oracle, function()
		local t = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		solo.roll_oracle(t == "" and nil or t)
	end, { desc = "Oracle with selection" })
	map("v", cfg.get().keymaps.dice, function()
		local n = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		if n ~= "" then
			solo.roll_dice(n)
		end
	end, { desc = "Roll dice with selection" })
end

-- Create Vim commands
vim.api.nvim_create_user_command("LonelogOracle", function(o)
	require("lonelog").roll_oracle(o.args ~= "" and o.args or nil)
end, { nargs = "?", desc = "Roll the oracle" })
vim.api.nvim_create_user_command("LonelogDice", function()
	vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
		if n and n ~= "" then
			require("lonelog").roll_dice(n)
		end
	end)
end, { nargs = 0, desc = "Interactive dice roller" })
vim.api.nvim_create_user_command("LonelogDiceRoll", function(o)
	require("lonelog").roll_dice(o.args)
end, {
	nargs = 1,
	complete = function()
		return {
			"1d4",
			"1d6",
			"1d8",
			"1d10",
			"1d12",
			"1d20",
			"1d100",
			"2d6",
			"2d6+3",
			"4d6",
			"6d6>>4",
			"2d6>7",
			"1d20>10",
		}
	end,
	desc = "Roll dice with notation",
})
vim.api.nvim_create_user_command("LonelogRollLine", function()
	require("lonelog.roll_line").roll_current_line()
end, { nargs = 0, desc = "Roll dice/table on current line" })
vim.api.nvim_create_user_command("LonelogTags", function()
	require("lonelog.ui.parsers").tags.show_tags_picker()
end, { nargs = 0, desc = "Navigate tags" })
vim.api.nvim_create_user_command("LonelogScenes", function()
	require("lonelog.ui.parsers").scenes.show_scenes_picker()
end, { nargs = 0, desc = "Navigate scenes" })
vim.api.nvim_create_user_command("Lonelog", function()
	require("lonelog").open_picker()
end, { nargs = 0, desc = "Open Lonelog picker" })
vim.api.nvim_create_user_command("LonelogInsert", function()
	local ui = require("lonelog.ui")
	local w, c = ui.get_latest_content()
	if c then
		ui.insert_result(w)
	else
		vim.notify("lonelog: No result to insert", vim.log.levels.WARN)
	end
end, { nargs = 0, desc = "Insert last result" })

-- Quick dice commands
for _, d in ipairs({
	{ "D4", "1d4" },
	{ "D6", "1d6" },
	{ "D8", "1d8" },
	{ "D10", "1d10" },
	{ "D12", "1d12" },
	{ "D20", "1d20" },
	{ "D100", "1d100" },
}) do
	vim.api.nvim_create_user_command("Lonelog" .. d[1], function()
		require("lonelog").roll_dice(d[2])
	end, { nargs = 0, desc = "Roll " .. d[2] })
end

-- Notation insertion commands
vim.api.nvim_create_user_command("LonelogSymbol", function(o)
	local symbols = {
		["@"] = "@ ",
		["?"] = "? ",
		d = "d: ",
		arrow = " -> ",
		conseq = "=> ",
		actor = "@(|) ",
	}
	local text = symbols[o.args]
	if text then
		local offset = o.args == "actor" and 3 or nil
		insert_text(text, offset)
	else
		vim.notify("lonelog: Unknown symbol '" .. o.args .. "'", vim.log.levels.WARN)
	end
end, { nargs = 1, desc = "Insert Lonelog symbol (@, ?, d, arrow, conseq, actor)" })

-- Multi-line sequence commands
vim.api.nvim_create_user_command("LonelogActionSequence", function()
	insert_template_at_cursor(ACTION_TEMPLATE, 0, 3)
end, { desc = "Insert action sequence template" })

vim.api.nvim_create_user_command("LonelogOracleSequence", function()
	insert_template_at_cursor(ORACLE_TEMPLATE, 0, 2)
end, { desc = "Insert oracle sequence template" })

-- Tag snippet command
vim.api.nvim_create_user_command("LonelogTag", function(o)
	local tags = {
		npc = "[N:|]",
		location = "[L:|]",
		pc = "[PC:|]",
		thread = "[Thread:|Open]",
		ref = "[#N:|]",
		foe = "[F:|]",
	}
	local offsets = { npc = 2, location = 2, pc = 2, thread = 6, ref = 2, foe = 2 }
	local snippet = tags[o.args]
	if snippet then
		insert_text(snippet, offsets[o.args])
	else
		vim.notify("lonelog: Unknown tag '" .. o.args .. "'", vim.log.levels.WARN)
	end
end, {
	nargs = 1,
	complete = function()
		return { "npc", "location", "pc", "thread", "ref", "foe" }
	end,
	desc = "Insert Lonelog tag snippet",
})

local function do_insert_progress(type_key, name, max_default, label)
  if name then
    if type_key:upper() ~= "TIMER"
      and require("lonelog.commands.progress").check_needs_insert(type_key, name)
    then
      vim.ui.input({ prompt = "Max progress (default " .. max_default .. "): " }, function(m)
        local max_val = tonumber(m) or max_default
        require("lonelog.commands.progress").increment_progress(type_key, name, max_val)
      end)
    else
      require("lonelog.commands.progress").increment_progress(type_key, name, max_default)
    end
  else
    vim.ui.input({ prompt = label .. " name: " }, function(n)
      if n and n ~= "" then
        do_insert_progress(type_key, n, max_default, label)
      end
    end)
  end
end

-- Progress element commands (smart increment or fresh insert)
vim.api.nvim_create_user_command("LonelogInsertClock", function(o)
	local name = o.args ~= "" and o.args or nil
	do_insert_progress("E", name, 5, "Clock")
end, { nargs = "?", desc = "Insert or increment event clock" })

vim.api.nvim_create_user_command("LonelogInsertTrack", function(o)
	local name = o.args ~= "" and o.args or nil
	do_insert_progress("TRACK", name, 5, "Track")
end, { nargs = "?", desc = "Insert or increment progress track" })

vim.api.nvim_create_user_command("LonelogInsertTimer", function(o)
	local name = o.args ~= "" and o.args or nil
	do_insert_progress("TIMER", name, 5, "Timer")
end, { nargs = "?", desc = "Insert or decrement timer" })

-- Scene marker command
vim.api.nvim_create_user_command("LonelogSceneMarker", function()
	insert_scene_marker()
end, { nargs = 0, desc = "Insert auto-numbered scene marker" })

-- Session header command
vim.api.nvim_create_user_command("LonelogSession", function()
	require("lonelog.commands.session").insert_session_header()
end, { nargs = 0, desc = "Insert auto-numbered session header" })

vim.api.nvim_create_user_command("LonelogNarrative", function()
	require("lonelog.commands.narrative").insert_narrative_block()
end, { nargs = 0, desc = "Insert narrative block" })

vim.api.nvim_create_user_command("LonelogNote", function()
	require("lonelog.commands.note").insert_note()
end, { nargs = 0, desc = "Insert meta note" })

-- Scene navigation commands
vim.api.nvim_create_user_command("LonelogScenePrev", function()
	require("lonelog.parsers.scenes").navigate_scene(-1)
end, { nargs = 0, desc = "Go to previous scene" })

vim.api.nvim_create_user_command("LonelogSceneNext", function()
	require("lonelog.parsers.scenes").navigate_scene(1)
end, { nargs = 0, desc = "Go to next scene" })

-- Set up keymaps after plugin loads
vim.api.nvim_create_autocmd("User", { pattern = "LonelogLoaded", callback = setup_keymaps })
vim.defer_fn(function()
	vim.api.nvim_exec_autocmds("User", { pattern = "LonelogLoaded" })
end, 0)

vim.api.nvim_create_user_command("LonelogChaos", function()
	require("lonelog.oracle").show_chaos_ui()
end, { nargs = 0, desc = "Open Chaos Factor UI" })

vim.api.nvim_create_user_command("LonelogCompleteTag", function()
	local ok, err = pcall(require("lonelog.completion").complete_tag)
	if not ok then
		vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
	end
end, { nargs = 0, desc = "Trigger Lonelog tag autocomplete" })

vim.api.nvim_create_augroup("LonelogCompletion", { clear = true })
vim.api.nvim_create_autocmd("TextChangedI", {
	group = "LonelogCompletion",
	pattern = "*",
	callback = function()
		if vim.bo.filetype ~= "markdown" then
			return
		end
		require("lonelog.completion").try_complete()
	end,
	desc = "Lonelog tag autocomplete",
})
