-- Module table.
local M = {}

-- UI table.
local UI = {}
UI.__index = UI

---Initializes an output UI instance.
---
---To create a new UI window:
---```lua
---local ui = UI:new()
---```
function UI:new()
    local ui = setmetatable({}, UI)

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
---This includes a newline character.
---
---For example, to write "Hello, world!" into a new UI window:
---```lua
---local ui = UI:new()
---ui:writeln("Hello, world!")
---```
---
---You can also emphasize phrases in the text with |highlight groups| by giving an array of phrase-group
---key-value pairs in `opts.hl_words`:
---
---```lua
---ui:writeln("Status err.", { hl_words = { { "err", "Error" } } })
---```
---
---The result is that "err" is highlighted according to the `Error` group rules in the output buffer.
---@param text string
---@param opts table?
function UI:writeln(text, opts)
    local this_line = vim.api.nvim_buf_line_count(self.buf_handle)
    vim.api.nvim_buf_set_lines(self.buf_handle, this_line, this_line, true, { text })

    -- Highlight if needed.
    if opts and opts.hl_words then
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

---Runs the given compile command, or the one cached in `M`. Outputs to a new temp buffer.
---
---Use it by entering the command as `cmd`:
---```lua
---M.compile("lua -v")
---```
---
---Or, `cmd` can be `nil`, and a cached command must be available in `M.cached_cmd`.
---```lua
---M.compile(nil)
---```
---@param cmd string?
function M.compile(cmd)
    assert(cmd ~= nil, "`M.compile` must be run with a non-nil cmd.")

    -- Open the UI.
    local cmd_ui = UI:new()

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
        cmd_ui:writeln("Command exited with status ok.", { hl_words = { { "ok", "CompileOk" } } })
        -- Highlight OK.
    else
        cmd_ui:writeln(
            "Command exited abnormally with code " .. code,
            { hl_words = { { "abnormally", "CompileErr" } } }
        )
    end

    -- Set as read-only.
    vim.api.nvim_set_option_value("readonly", true, { buf = cmd_ui.buf_handle })
end

---Collects a new compile command via a user-editable scratch buffer.
---Then, caches (in `M.cached_cmd`) and runs the command with `M.compile`.
function M.get_cmd_and_compile()
    -- Open scratch buffer.
    local cmd_ui = UI:new()

    -- Runs when window hosting scratch buffer closes.
    -- Gathers the buffer contents, caches it, and runs `compile`.
    local on_close = function(args)
        local cmd_lines = vim.api.nvim_buf_get_lines(cmd_ui.buf_handle, 0, -1, true)
        local cmd = table.concat(cmd_lines, " ")
        assert(cmd ~= "", "Must enter a command in scratch buffer in `M.get_cmd_and_compile()`.")
        M.compile(cmd)
        M.cached_cmd = cmd
    end

    -- Set up autocmd to give contents on window close.
    --
    -- Want to make sure it only impacts this window, so set up an augroup.
    -- See `:help augroup`
    local win_group = vim.api.nvim_create_augroup("compile_win_" .. cmd_ui.win_handle, {})
    vim.api.nvim_create_autocmd("WinClosed", {
        once = true,
        group = win_group,
        callback = on_close,
    })
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
    --
    -- `<leader>cr` for "command-rerun", by default.
    vim.keymap.set("n", "<leader>cr", function()
        -- Prefer cached command, obviously.
        if M.cached_cmd then
            M.compile(M.cached_cmd)
        else
            M.get_cmd_and_compile()
        end
    end, { desc = "[C]ommand [R]erun" })
    -- `<leader>cc` for "command-create", by default.
    vim.keymap.set("n", "<leader>cc", function()
        M.get_cmd_and_compile()
    end, { desc = "[C]ommand [C]reate" })

    -- User command to run the compiler.
    vim.api.nvim_create_user_command("Compile", function(cmp_opts)
        local cmd = cmp_opts.args
        M.compile(cmd)
        M.cached_cmd = cmd
    end, { nargs = 1 })
end

return M
