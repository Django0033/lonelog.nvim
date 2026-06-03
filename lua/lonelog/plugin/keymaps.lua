local function setup_keymaps()
	local cfg = require("lonelog.config")
	local solo = require("lonelog")
	local h = require("lonelog.plugin.helpers")

	local function map(mode, lhs, rhs, opts)
		if lhs then
			vim.keymap.set(mode, lhs, rhs, opts or { silent = true })
		end
	end

	-- Core actions (l<UPPER>)
	map("n", cfg.get().keymaps.oracle, function()
		solo.ui.pick({
			title = "Choose the Oracle",
			items = solo.oracle.list_tables(),
			on_select = function(t) solo.roll_oracle(t) end,
		})
	end, { desc = "Lonelog Oracle" })
	map("n", cfg.get().keymaps.dice, function()
		vim.ui.input({ prompt = "Dice (e.g., 2d6+3): " }, function(n)
			if n and n ~= "" then solo.roll_dice(n) end
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
	map("n", cfg.get().keymaps.insert_result, function()
		local w, c = solo.ui.get_latest_content()
		if c then
			solo.ui.insert_result(w)
		else
			vim.notify("lonelog: No result to insert", vim.log.levels.WARN)
		end
	end, { desc = "Insert result" })
	map("n", cfg.get().keymaps.roll_line, function()
		require("lonelog.roll_line").roll_current_line()
	end, { desc = "Lonelog roll on current line" })

	-- Session structure (ls-)
	map("n", cfg.get().keymaps.session_header, function()
		require("lonelog.commands.session").insert_session_header()
	end, { desc = "Insert session header" })
	map("n", cfg.get().keymaps.narrative_block, function()
		require("lonelog.commands.narrative").insert_narrative_block()
	end, { desc = "Insert narrative block" })
	map("n", cfg.get().keymaps.scene_marker, function()
		h.insert_scene_marker()
	end, { desc = "Insert auto-numbered scene" })
	map("n", cfg.get().keymaps.campaign_header, function()
		require("lonelog.commands.campaign").insert_campaign_header()
	end, { desc = "Insert campaign header" })
	map("n", cfg.get().keymaps.session_summary, function()
		require("lonelog.commands.summary").show_session_summary()
	end, { desc = "Session summary" })
	map("n", cfg.get().keymaps.scene_prev, function()
		require("lonelog.parsers.scenes").navigate_scene(-1)
	end, { desc = "Previous scene" })
	map("n", cfg.get().keymaps.scene_next, function()
		require("lonelog.parsers.scenes").navigate_scene(1)
	end, { desc = "Next scene" })

	-- Insert notation symbols (li-)
	map("n", cfg.get().keymaps.insert_action, function() h.insert_text("@ ") end, { desc = "Insert action marker @" })
	map("n", cfg.get().keymaps.insert_question, function() h.insert_text("? ") end, { desc = "Insert oracle question ?" })
	map("n", cfg.get().keymaps.insert_dice, function() h.insert_text("d: ") end, { desc = "Insert dice roll d:" })
	map("n", cfg.get().keymaps.insert_note, function()
		require("lonelog.commands.note").insert_note()
	end, { desc = "Insert (note:)" })
	map("n", cfg.get().keymaps.insert_arrow, function() h.insert_text(" -> ") end, { desc = "Insert result arrow ->" })
	map("n", cfg.get().keymaps.insert_conseq, function() h.insert_text("=> ") end, { desc = "Insert consequence =>" })
	map("n", cfg.get().keymaps.actor_action, function() h.insert_text("@(|) ", 3) end, { desc = "Insert actor action @(Name)" })

	-- Multi-line notation sequences
	map("n", cfg.get().keymaps.action_seq, function()
		h.insert_template_at_cursor(h.ACTION_TEMPLATE, 0, 3)
	end, { desc = "Insert action sequence" })
	map("n", cfg.get().keymaps.oracle_seq, function()
		h.insert_template_at_cursor(h.ORACLE_TEMPLATE, 0, 2)
	end, { desc = "Insert oracle sequence" })

	-- Entity tags (lt-)
	map("n", cfg.get().keymaps.tag_npc, function() h.insert_text("[N:|]", 2) end, { desc = "Insert NPC tag" })
	map("n", cfg.get().keymaps.tag_location, function() h.insert_text("[L:|]", 2) end, { desc = "Insert location tag" })
	map("n", cfg.get().keymaps.tag_pc, function() h.insert_text("[PC:|]", 2) end, { desc = "Insert PC tag" })
	map("n", cfg.get().keymaps.tag_thread, function() h.insert_text("[Thread:|Open]", 6) end, { desc = "Insert thread tag" })
	map("n", cfg.get().keymaps.tag_ref, function() h.insert_text("[#N:|]", 2) end, { desc = "Insert reference tag" })
	map("n", cfg.get().keymaps.tag_foe, function() h.insert_text("[F:|]", 2) end, { desc = "Insert foe tag" })
	map("n", cfg.get().keymaps.pc_update, function()
		vim.ui.input({ prompt = "PC name: " }, function(name)
			if not name or name == "" then return end
			vim.ui.input({ prompt = "Stat update (e.g. HP-2, Stress+1): " }, function(stat)
				if not stat or stat == "" then return end
				h.insert_text("[PC:" .. name .. "|" .. stat .. "]", 0)
			end)
		end)
	end, { desc = "Insert PC stat update" })
	map("n", cfg.get().keymaps.npc_update, function()
		vim.ui.input({ prompt = "NPC name: " }, function(name)
			if not name or name == "" then return end
			vim.ui.input({ prompt = "Change (e.g. +captured, -wounded, friendly->hostile): " }, function(change)
				if not change or change == "" then return end
				h.insert_text("[N:" .. name .. "|" .. change .. "]", 0)
			end)
		end)
	end, { desc = "Insert NPC status update" })

	-- Multi-line tags (lm-)
	local function insert_mltag(tag_key)
		return function()
			require("lonelog.commands.multiline_tag").insert_multiline_tag(tag_key)
		end
	end
	map("n", cfg.get().keymaps.mltag_npc, insert_mltag("npc"), { desc = "Insert multi-line NPC tag" })
	map("n", cfg.get().keymaps.mltag_location, insert_mltag("location"), { desc = "Insert multi-line location tag" })
	map("n", cfg.get().keymaps.mltag_pc, insert_mltag("pc"), { desc = "Insert multi-line PC tag" })
	map("n", cfg.get().keymaps.mltag_thread, insert_mltag("thread"), { desc = "Insert multi-line thread tag" })
	map("n", cfg.get().keymaps.mltag_ref, insert_mltag("ref"), { desc = "Insert multi-line reference tag" })
	map("n", cfg.get().keymaps.mltag_foe, insert_mltag("foe"), { desc = "Insert multi-line foe tag" })

	-- Progress elements (lp-)
	map("n", cfg.get().keymaps.progress_clock, function() vim.cmd("LonelogInsertClock") end, { desc = "Insert/increment clock" })
	map("n", cfg.get().keymaps.progress_track, function() vim.cmd("LonelogInsertTrack") end, { desc = "Insert/increment track" })
	map("n", cfg.get().keymaps.progress_timer, function() vim.cmd("LonelogInsertTimer") end, { desc = "Insert/decrement timer" })

	-- Quick dice (ld-)
	for _, q in ipairs(h.QUICK_DICE) do
		local km = cfg.get().keymaps[q.key]
		if km then
			map("n", km, function() solo.roll_dice(q.dice) end, { desc = "Roll " .. q.dice })
		end
	end

	-- Insert mode (C-l)
	map("i", "<C-l>a", function() h.insert_text("@ ") end, { desc = "Insert action marker @" })
	map("i", "<C-l>N", function() h.insert_text("@(|) ", 3) end, { desc = "Insert actor action @(Name)" })
	map("i", "<C-l>q", function() h.insert_text("? ") end, { desc = "Insert oracle question ?" })
	map("i", "<C-l>d", function() h.insert_text("d: ") end, { desc = "Insert dice roll d:" })
	map("i", "<C-l>-", function() h.insert_text(" -> ") end, { desc = "Insert result arrow ->" })
	map("i", "<C-l>=", function() h.insert_text("=> ") end, { desc = "Insert consequence =>" })
	map("i", "<C-l>n", function() h.insert_text("[N:|]", 3) end, { desc = "Insert NPC tag" })
	map("i", "<C-l>l", function() h.insert_text("[L:|]", 3) end, { desc = "Insert location tag" })
	map("i", "<C-l>p", function() h.insert_text("[PC:|]", 3) end, { desc = "Insert PC tag" })
	map("i", "<C-l>h", function() h.insert_text("[Thread:|Open]", 7) end, { desc = "Insert thread tag" })
	map("i", "<C-l>r", function() h.insert_text("[#N:|]", 3) end, { desc = "Insert reference tag" })
	map("i", "<C-l>f", function() h.insert_text("[F:|]", 3) end, { desc = "Insert foe tag" })
	map("i", cfg.get().keymaps.complete_tag, function()
		local ok, err = pcall(require("lonelog.completion").complete_tag)
		if not ok then
			vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { desc = "Complete Lonelog tag" })

	-- Visual mode
	map("v", cfg.get().keymaps.oracle, function()
		local t = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		solo.roll_oracle(t == "" and nil or t)
	end, { desc = "Oracle with selection" })
	map("v", cfg.get().keymaps.dice, function()
		local n = vim.trim(vim.fn.getline("."):sub(vim.fn.col("v"), vim.fn.col(".")))
		if n ~= "" then solo.roll_dice(n) end
	end, { desc = "Roll dice with selection" })
end

return setup_keymaps
