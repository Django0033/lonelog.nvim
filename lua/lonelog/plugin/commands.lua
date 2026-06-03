local function register_commands()
	local h = require("lonelog.plugin.helpers")

	-- Core commands
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
			return { "1d4", "1d6", "1d8", "1d10", "1d12", "1d20", "1d100",
				"2d6", "2d6+3", "4d6", "6d6>>4", "2d6>7", "1d20>10" }
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

	vim.api.nvim_create_user_command("LonelogChaos", function()
		require("lonelog.oracle").show_chaos_ui()
	end, { nargs = 0, desc = "Open Chaos Factor UI" })

	vim.api.nvim_create_user_command("LonelogCompleteTag", function()
		local ok, err = pcall(require("lonelog.completion").complete_tag)
		if not ok then
			vim.notify("lonelog: " .. tostring(err), vim.log.levels.ERROR)
		end
	end, { nargs = 0, desc = "Trigger Lonelog tag autocomplete" })

	-- Quick dice commands
	for _, d in ipairs(h.QUICK_DICE) do
		vim.api.nvim_create_user_command("Lonelog" .. d.cmd, function()
			require("lonelog").roll_dice(d.dice)
		end, { nargs = 0, desc = "Roll " .. d.dice })
	end

	-- Notation insertion commands
	vim.api.nvim_create_user_command("LonelogSymbol", function(o)
		local symbols = {
			["@"] = "@ ", ["?"] = "? ", d = "d: ",
			arrow = " -> ", conseq = "=> ", actor = "@(|) ",
		}
		local text = symbols[o.args]
		if text then
			local offset = o.args == "actor" and 3 or nil
			h.insert_text(text, offset)
		else
			vim.notify("lonelog: Unknown symbol '" .. o.args .. "'", vim.log.levels.WARN)
		end
	end, { nargs = 1, desc = "Insert Lonelog symbol" })

	vim.api.nvim_create_user_command("LonelogActionSequence", function()
		h.insert_template_at_cursor(h.ACTION_TEMPLATE, 0, 3)
	end, { desc = "Insert action sequence template" })

	vim.api.nvim_create_user_command("LonelogOracleSequence", function()
		h.insert_template_at_cursor(h.ORACLE_TEMPLATE, 0, 2)
	end, { desc = "Insert oracle sequence template" })

	-- Tag snippet command
	vim.api.nvim_create_user_command("LonelogTag", function(o)
		local tags = {
			npc = "[N:|]", location = "[L:|]", pc = "[PC:|]",
			thread = "[Thread:|Open]", ref = "[#N:|]", foe = "[F:|]",
		}
		local offsets = { npc = 2, location = 2, pc = 2, thread = 6, ref = 2, foe = 2 }
		local snippet = tags[o.args]
		if snippet then
			h.insert_text(snippet, offsets[o.args])
		else
			vim.notify("lonelog: Unknown tag '" .. o.args .. "'", vim.log.levels.WARN)
		end
	end, {
		nargs = 1,
		complete = function() return { "npc", "location", "pc", "thread", "ref", "foe" } end,
		desc = "Insert Lonelog tag snippet",
	})

	-- Progress commands
	vim.api.nvim_create_user_command("LonelogInsertClock", function(o)
		h.do_insert_progress("E", o.args ~= "" and o.args or nil, 5, "Clock")
	end, { nargs = "?", desc = "Insert or increment event clock" })

	vim.api.nvim_create_user_command("LonelogInsertTrack", function(o)
		h.do_insert_progress("TRACK", o.args ~= "" and o.args or nil, 5, "Track")
	end, { nargs = "?", desc = "Insert or increment progress track" })

	vim.api.nvim_create_user_command("LonelogInsertTimer", function(o)
		h.do_insert_progress("TIMER", o.args ~= "" and o.args or nil, 5, "Timer")
	end, { nargs = "?", desc = "Insert or decrement timer" })

	-- Scene marker
	vim.api.nvim_create_user_command("LonelogSceneMarker", function()
		h.insert_scene_marker()
	end, { nargs = 0, desc = "Insert auto-numbered scene marker" })

	-- Campaign / Session / Narrative / Note
	vim.api.nvim_create_user_command("LonelogCampaign", function()
		require("lonelog.commands.campaign").insert_campaign_header()
	end, { nargs = 0, desc = "Insert campaign header YAML frontmatter" })

	vim.api.nvim_create_user_command("LonelogSession", function()
		require("lonelog.commands.session").insert_session_header()
	end, { nargs = 0, desc = "Insert auto-numbered session header" })

	vim.api.nvim_create_user_command("LonelogNarrative", function()
		require("lonelog.commands.narrative").insert_narrative_block()
	end, { nargs = 0, desc = "Insert narrative block" })

	vim.api.nvim_create_user_command("LonelogNote", function()
		require("lonelog.commands.note").insert_note()
	end, { nargs = 0, desc = "Insert meta note" })

	-- Summary commands
	vim.api.nvim_create_user_command("LonelogSessionSummary", function()
		require("lonelog.commands.summary").show_session_summary()
	end, { nargs = 0, desc = "Show session summary" })

	vim.api.nvim_create_user_command("LonelogExportSummary", function()
		require("lonelog.commands.summary").export_session_summary()
	end, { nargs = 0, desc = "Export session summary to file" })

	-- Multi-line tag
	vim.api.nvim_create_user_command("LonelogMultiTag", function(o)
		require("lonelog.commands.multiline_tag").insert_multiline_tag(o.args)
	end, {
		nargs = 1,
		complete = function() return { "npc", "location", "pc", "thread", "ref", "foe" } end,
		desc = "Insert multi-line tag",
	})

	-- Scene navigation
	vim.api.nvim_create_user_command("LonelogScenePrev", function()
		require("lonelog.parsers.scenes").navigate_scene(-1)
	end, { nargs = 0, desc = "Go to previous scene" })

	vim.api.nvim_create_user_command("LonelogSceneNext", function()
		require("lonelog.parsers.scenes").navigate_scene(1)
	end, { nargs = 0, desc = "Go to next scene" })
end

return register_commands
