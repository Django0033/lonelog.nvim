local M = {}

function M.format_summary(summary)
	local lines = {}
	local s = summary.session

	table.insert(lines, " Session " .. s.number .. " Summary")
	table.insert(lines, "  Date: " .. (s.date or "—"))
	table.insert(lines, "  Lines: " .. summary.lines_count .. "  Words: " .. summary.words_count)
	table.insert(lines, "")

	local scene_total = #summary.scenes
	table.insert(lines, "  Scenes: " .. scene_total)
	for _, sc in ipairs(summary.scenes) do
		local ctx = sc.context and (" — " .. sc.context) or ""
		table.insert(lines, "    " .. sc.scene_id .. ctx)
	end
	table.insert(lines, "")

	local tag_total = #summary.tags
	table.insert(lines, "  Tags: " .. tag_total)
	local type_keys = {}
	for k in pairs(summary.tag_counts) do
		table.insert(type_keys, k)
	end
	table.sort(type_keys)
	local parts = {}
	for _, k in ipairs(type_keys) do
		local tc = summary.tag_counts[k]
		table.insert(parts, tc.label .. ":" .. tc.count)
	end
	if #parts > 0 then
		table.insert(lines, "    " .. table.concat(parts, ", "))
	end
	table.insert(lines, "")

	local n = summary.notation
	local function pad(key, val)
		return key .. string.rep(" ", 12 - #key) .. val
	end
	table.insert(lines, "  " .. pad("Actions @", n.actions))
	table.insert(lines, "  " .. pad("Questions ?", n.questions))
	table.insert(lines, "  " .. pad("Dice d:", n.dice_lines))
	table.insert(lines, "  " .. pad("Notes", summary.meta_notes))
	table.insert(lines, "  " .. pad("Dialogues", summary.dialogues))
	table.insert(lines, "  " .. pad("Narrative", summary.narrative_blocks))
	table.insert(lines, "")

	local p = summary.progress
	local prog_parts = {}
	if p.clocks > 0 then table.insert(prog_parts, "Clocks:" .. p.clocks) end
	if p.tracks > 0 then table.insert(prog_parts, "Tracks:" .. p.tracks) end
	if p.timers > 0 then table.insert(prog_parts, "Timers:" .. p.timers) end
	if #prog_parts > 0 then
		table.insert(lines, "  Progress: " .. table.concat(prog_parts, ", "))
		if #p.completed > 0 then
			table.insert(lines, "    Completed: " .. table.concat(p.completed, ", "))
		end
		table.insert(lines, "")
	end

	local d = summary.dice
	if d.count > 0 then
		table.insert(lines, "  Dice rolls: " .. d.count)
		table.insert(lines, "  Sum total:  " .. d.sum)
		table.insert(lines, "  Average:    " .. d.average)
		table.insert(lines, "  Breakdown:")
		for _, b in ipairs(d.breakdown) do
			table.insert(lines, "    " .. b)
		end
	end

	local rs = summary.roll_stats
	if rs and rs.by_type and #rs.by_type > 0 then
		table.insert(lines, "  Dice by Type:")
		for _, entry in ipairs(rs.by_type) do
			local line = string.format("    %s: %d rolls (sum: %d, avg: %.1f, min: %d, max: %d)",
				entry.notation, entry.count, entry.sum, entry.average, entry.min, entry.max)
			table.insert(lines, line)
		end
	end

	if rs and rs.oracle_results and #rs.oracle_results > 0 then
		table.insert(lines, "  Oracle Results:")
		for _, ot in ipairs(rs.oracle_results) do
			table.insert(lines, "    " .. ot.table .. ":")
			local val_keys = {}
			for k in pairs(ot.results) do
				table.insert(val_keys, k)
			end
			table.sort(val_keys)
			for _, k in ipairs(val_keys) do
				table.insert(lines, "      " .. k .. ": " .. ot.results[k])
			end
		end
	end

	return lines
end

function M.export_summary(summary)
	local s = summary.session
	local out = {}
	table.insert(out, "# Session " .. s.number .. " Summary")
	table.insert(out, "")
	table.insert(out, "**Date:** " .. (s.date or "—"))
	table.insert(out, "**Lines:** " .. summary.lines_count .. " | **Words:** " .. summary.words_count)
	table.insert(out, "")
	table.insert(out, "## Overview")
	table.insert(out, "")
	table.insert(out, "| Metric | Count |")
	table.insert(out, "|--------|-------|")
	table.insert(out, "| Scenes | " .. #summary.scenes .. " |")

	local scene_type_keys = {}
	for k in pairs(summary.scene_counts) do
		table.insert(scene_type_keys, k)
	end
	table.sort(scene_type_keys)
	for _, k in ipairs(scene_type_keys) do
		local sc = summary.scene_counts[k]
		table.insert(out, "| — " .. (sc.label or k) .. " | " .. sc.count .. " |")
	end

	table.insert(out, "| Tags | " .. #summary.tags .. " |")
	local tag_type_keys = {}
	for k in pairs(summary.tag_counts) do
		table.insert(tag_type_keys, k)
	end
	table.sort(tag_type_keys)
	for _, k in ipairs(tag_type_keys) do
		local tc = summary.tag_counts[k]
		table.insert(out, "| — " .. (tc.label or k) .. " | " .. tc.count .. " |")
	end

	local n = summary.notation
	table.insert(out, "| Actions | " .. n.actions .. " |")
	table.insert(out, "| Oracle questions | " .. n.questions .. " |")
	table.insert(out, "| Dice rolls | " .. n.dice_lines .. " |")
	table.insert(out, "| Meta notes | " .. summary.meta_notes .. " |")
	table.insert(out, "| Dialogues | " .. summary.dialogues .. " |")
	table.insert(out, "| Narrative | " .. summary.narrative_blocks .. " |")

	local p = summary.progress
	if p.clocks > 0 or p.tracks > 0 or p.timers > 0 then
		table.insert(out, "| Clocks | " .. p.clocks .. " |")
		table.insert(out, "| Tracks | " .. p.tracks .. " |")
		table.insert(out, "| Timers | " .. p.timers .. " |")
		if #p.completed > 0 then
			table.insert(out, "| Completed | " .. table.concat(p.completed, ", ") .. " |")
		end
	end

	table.insert(out, "")

	local d = summary.dice
	if d.count > 0 then
		table.insert(out, "## Dice")
		table.insert(out, "")
		table.insert(out, "- Total rolls: " .. d.count)
		table.insert(out, "- Sum of totals: " .. d.sum)
		table.insert(out, "- Average per roll: " .. d.average)
		table.insert(out, "")
		for _, b in ipairs(d.breakdown) do
			table.insert(out, "  - `" .. b .. "`")
		end
		table.insert(out, "")
	end

	if #summary.scenes > 0 then
		table.insert(out, "## Scenes")
		table.insert(out, "")
		for _, sc in ipairs(summary.scenes) do
			local ctx = sc.context and (" — " .. sc.context) or ""
			table.insert(out, "- " .. sc.scene_id .. ctx)
		end
		table.insert(out, "")
	end

	if #summary.tags > 0 then
		table.insert(out, "## Tags")
		table.insert(out, "")
		local sorted = {}
		for _, t in ipairs(summary.tags) do
			table.insert(sorted, t)
		end
		table.sort(sorted, function(a, b) return a.type < b.type or (a.type == b.type and a.name < b.name) end)
		for _, t in ipairs(sorted) do
			table.insert(out, "- [" .. t.type .. ":" .. t.name .. "]")
		end
	end

	local rs = summary.roll_stats
	if rs and rs.oracle_results and #rs.oracle_results > 0 then
		table.insert(out, "")
		table.insert(out, "### Oracle Results")
		table.insert(out, "")
		for _, ot in ipairs(rs.oracle_results) do
			table.insert(out, ot.table .. ":")
			local val_keys = {}
			for k in pairs(ot.results) do
				table.insert(val_keys, k)
			end
			table.sort(val_keys)
			for _, k in ipairs(val_keys) do
				table.insert(out, "  " .. k .. ": " .. ot.results[k])
			end
		end
	end

	return table.concat(out, "\n")
end

return M
