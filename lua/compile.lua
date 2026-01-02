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

---Write line into this UI.
---@param text string
---@param opts table?
function CompileUI:writeln(text, opts)
    local this_line = vim.api.nvim_buf_line_count(self.buf_handle)
    vim.api.nvim_buf_set_lines(self.buf_handle, this_line, this_line, true, { text })

    -- Highlight if needed.
    if opts and opts.hl then
        assert(opts.hl_words)

        -- Do each phrase manually.
        for _, hl_pair in ipairs(opts.hl_words) do
            -- Destructure highlight pair.
            local phrase, group = hl_pair[1], hl_pair[2] -- Why tf does `table.unpack` not work?? It's `nil`?!

            -- Find the substr (start + end col.) of the phrase.
            local first, last = string.find(text, phrase)
            assert(first, "Highlight substring must exist in text.")
            assert(last, "Highlight substring must exist in text.")
            vim.api.nvim_buf_set_extmark(self.buf_handle, M.plugin_ns, this_line, first - 1, {
                end_col = last,
                hl_group = group,
            })
        end
    end
end

---Opens a compilation window.
function M.open_compile_window()
    return CompileUI:new()
end

---Runs the given compile command, or the one cached in `M`.
---@param cmd string?
function M.compile(cmd)
    assert(cmd ~= nil, "`M.compile` must be run with a non-nil cmd.")

    -- Open the UI.
    local cmd_ui = M.open_compile_window()

    -- Report the command written.
    cmd_ui:writeln("> " .. cmd)
    cmd_ui:writeln("") -- Empty line.

    -- Run the command, and report the output.
    --
    -- See `:help systemlist`.
    local cmd_out = vim.fn.systemlist(cmd .. " 2>&1")
    for _, out_line in ipairs(cmd_out) do
        cmd_ui:writeln(out_line)
    end

    -- Report status.
    --
    -- Very handy.
    -- See `:help shell_error`
    local code = vim.v.shell_error
    cmd_ui:writeln("") -- Empty line.
    if code == 0 then
        -- OK status.
        cmd_ui:writeln("Command exited with status ok.", { hl = true, hl_words = { { "ok", "CompileOk" } } })
        -- Highlight OK.
    else
        cmd_ui:writeln(
            "Command exited abnormally with code " .. code,
            { hl = true, hl_words = { { "abnormally", "CompileErr" } } }
        )
    end
end

function M.setup(opts)
    -- Setup plugin namespace for exts.
    M.plugin_ns = vim.api.nvim_create_namespace("compile")

    -- Highlight groups for UI.
    --
    -- Use global highlight namespace.
    vim.api.nvim_set_hl(0, "CompileOk", {
        fg = "#00ff00",
        bold = true,
    })
    vim.api.nvim_set_hl(0, "CompileErr", {
        fg = "#ff0000",
        bold = true,
    })

    -- Set keybinds.
    vim.keymap.set("n", "<leader>cr", function()
        if M.cached_cmd then
            M.compile(M.cached_cmd)
        end
        -- TODO: If there is no cached command, ask user to enter one.
        --
        -- Dependent on implementing the input window UI, probably.
    end, {})

    -- User command to run the compiler.
    vim.api.nvim_create_user_command("Compile", function(cmp_opts)
        local cmd = cmp_opts.args
        if cmd == "" then
            M.compile(M.cached_cmd)
        else
            M.compile(cmd)
            M.cached_cmd = cmd
        end
    end, { nargs = "?" })
end

return M
