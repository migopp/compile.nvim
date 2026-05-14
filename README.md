# compile.nvim

Convenient compilation buffer support.

## Usage

With [`nvim.pack`](https://neovim.io/doc/user/pack/), use the following

```lua
vim.pack.add { 'https://github.com/migopp/compile.nvim' }

require('compile').setup {}
```

If you use [lazy](https://github.com/folke/lazy.nvim), this should work:
```lua
{
    'migopp/compile.nvim',
    opts = {},
}
```

Otherwise, assuming that `compile.lua` is available somewhere in your environment, the following setup is also viable:
```lua
local compile = require 'compile'
opts = {}           -- Default config.
compile.setup(opts) -- `opts` is optional here.
```

## Configuration

Configuration is available via the `opts` table listed above.

Below is the default configuration. Any user-supplied table should follow the same basic structure.

```lua
---Default module options.
local def_opts = {
    ---Highlights. These are stupid. Not sure why it is a configuration option.
    ---Options are entered directly into `nvim_set_hl`.
    ---See `:help vim.api.nvim_set_hl` for argument semantics.
    highlights = {
        ['CompileOk'] = {
            fg = '#00ff00',
            bold = true,
        },
        ['CompileErr'] = {
            fg = '#ff0000',
            bold = true,
        },
    },
    ---Keymaps. Each entry is entered directly into a call to `vim.keymap.set`.
    ---See `:help vim.keymap.set` for argument semantics.
    ---
    ---Currently, mapping name is useless, functionally.
    keymaps = {
        ['command_create'] = {
            mode = 'n',
            lhs = '<leader>cc',
            rhs = M.command_create,
            opts = { desc = '[C]ommand [C]reate' },
        },
        ['command_rerun'] = {
            mode = 'n',
            lhs = '<leader>cr',
            rhs = M.command_rerun,
            opts = { desc = '[C]ommand [R]erun' },
        },
    },
    ---User commands. Each is entered directly into a call to `vim.api.nvim_create_user_command`.
    ---See `:help vim.api.nvim_create_user_command` for argument semantics.
    ---
    ---Currently, mapping name is useless, functionally.
    commands = {
        ['command_run'] = {
            name = 'Compile',
            command = function(opts)
                M.command_run(opts.args)
            end,
            opts = { nargs = 1 },
        },
    },
}
```

> [!NOTE]
> Sparse config tables are allowed. Default options will be used where the user does not specify.

## License

MIT.
