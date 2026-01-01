local M = {}

local CompileUI = {}
CompileUI.__index = CompileUI

---Initializes a compile UI.
function CompileUI:new()
    local ui = setmetatable({}, CompileUI)

    -- Create a listed, temporary buffer.
    ui.buf_handle = vim.api.nvim_create_buf(true, true)

    -- Open the compilation window.
    local main_win = vim.api.nvim_get_current_win()
    ui.win_handle = vim.api.nvim_open_win(ui.buf_handle, true, {
        split = "below",
        win = main_win,
    })

    return ui
end

---Write text (split by lines) into this UI.
---@param text string
function CompileUI:write(text)
    local this_line = vim.api.nvim_buf_line_count(self.buf_handle)
    vim.api.nvim_buf_set_lines(self.buf_handle, this_line, this_line, true, { text })
end

---Opens a compilation window.
function M.open_compile_window()
    return CompileUI:new()
end

---Runs the given compile command, or the one cached in `M`.
---@param cmd string?
function M.compile(cmd)
    -- Prioritize given command to the cached command.
    local run_cmd = cmd or M.cached_cmd
    assert(run_cmd ~= nil, "`M.compile` must be run with either a non-nil cmd or cached cmd.")

    -- Open the UI.
    local cmd_ui = M.open_compile_window()

    -- Report the command written.
    cmd_ui:write("> " .. run_cmd)
    cmd_ui:write("") -- Empty line.

    -- Run the command, and report the output.
    local cmd_handle = assert(io.popen(run_cmd))
    for out_line in cmd_handle:lines("*l") do
        cmd_ui:write(out_line)
    end
end

function M.setup(opts)
    -- User command to run the compiler.
    vim.api.nvim_create_user_command("Compile", function(cmp_opts)
        M.compile(cmp_opts.args)
    end, { nargs = 1 })
end

return M
