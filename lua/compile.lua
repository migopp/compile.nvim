local M = {}

function M.compile()
    print("Compiling...")
end

function M.setup(opts)
    -- Fake user command.
    --
    -- So I can tell if this sheisse is working.
    vim.api.nvim_create_user_command("Compile", function()
        M.compile()
    end, {})
end

return M
