-- ============================================================================
-- SESSION HEADER TEST
-- ============================================================================

package.path = package.path .. ";./lua/?.lua"

_G.vim = {}

-- Mock nil for functions we don't test here
vim.api = {}
vim.api.nvim_buf_get_lines = function()
	return {}
end
vim.api.nvim_get_current_buf = function()
	return 1
end

local session = require("lonelog.commands.session")

-- ============================================================================
-- build_session_header
-- ============================================================================

local tests = {
	{
		name = "build_session_header returns correct format for session 1",
		func = function()
			local lines = session.build_session_header(1)
			assert(lines[1] == "## Session 1", "Expected '## Session 1', got: " .. tostring(lines[1]))
			assert(type(lines[2]) == "string" and #lines[2] > 0, "Expected date string")
			assert(lines[4] == "### Recap", "Expected '### Recap', got: " .. tostring(lines[4]))
			assert(lines[5] == "- ", "Expected '- ', got: " .. tostring(lines[5]))
			assert(lines[7] == "### Goals", "Expected '### Goals', got: " .. tostring(lines[7]))
			assert(lines[8] == "- ", "Expected '- ', got: " .. tostring(lines[8]))
		end,
	},
	{
		name = "build_session_header uses the given number",
		func = function()
			local lines = session.build_session_header(5)
			assert(lines[1] == "## Session 5", "Expected '## Session 5', got: " .. tostring(lines[1]))
		end,
	},
	{
		name = "build_session_header date is in YYYY-MM-DD format",
		func = function()
			local lines = session.build_session_header(1)
			assert(lines[2]:match("%d%d%d%d%-%d%d%-%d%d"), "Expected YYYY-MM-DD date, got: " .. tostring(lines[2]))
		end,
	},
}

local passed = 0
local failed = 0

for _, t in ipairs(tests) do
	local ok, err = pcall(t.func)
	if ok then
		passed = passed + 1
		io.write("  PASS " .. t.name .. "\n")
	else
		failed = failed + 1
		io.write("  FAIL " .. t.name .. "\n")
		io.write("    " .. tostring(err) .. "\n")
	end
end

io.write(string.format("\nRESULTS: %d passed, %d failed\n", passed, failed + 0))

if failed > 0 then
	os.exit(1)
end
