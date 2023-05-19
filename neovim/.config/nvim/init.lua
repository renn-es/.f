---------------------
-- Setup lazy.nvim --
---------------------

cfg_root = vim.fn.stdpath("config")


local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- We need to set this before lazy so our mappings are set
vim.g.mapleader = " "


-- enable hex colors. This needs to come before plugins, because
-- some (like cmp) will render ugly colors else
vim.opt.termguicolors = true

-------------
-- Plugins --
-------------

require("lazy").setup({
    -- Gruvbox colorscheme
    {
        "morhetz/gruvbox",
        init = function()
            vim.cmd [[colorscheme gruvbox]]
        end
    },
    -- Lualine statusline
    {
        "hoob3rt/lualine.nvim",
        opts = {
            options = {
                component_separators = {"", ""},
                section_separators = {"", ""},
            }
        },
        dependencies = {"kyazdani42/nvim-web-devicons"}
    },
    -- treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        dependencies = {
            'windwp/nvim-ts-autotag'
        },
        init = function ()
            require'nvim-treesitter.configs'.setup {
                ensure_installed = {"c", "lua", "rust", "markdown", "yaml", "bash"},
                highlight = {
                    enable = true,
                },
                autotag = {
                    enable = true,
                }
            }
        end
    },
    -- LSP (completion, diagnostics, etc)
    {
        "neovim/nvim-lspconfig",
        init = function ()
            local lspconfig = require("lspconfig")
            local servers = {"pyright", "bashls", "jsonls", "lua_ls", "yamlls"}
            for _, lsp in ipairs(servers) do
                lspconfig[lsp].setup{
                    capabilities = require("cmp_nvim_lsp").default_capabilities(),
                }
            end
        end
    },
    -- cmp (autocomplete)
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        init = function ()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            cmp.setup({
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = {
                    ["<C-d>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.close(),
                    ["<CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                        else fallback() end
                    end, {"i", "s"}),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                },
            })
        end
    },
    -- Luasnip (snippets)
    "L3MON4D3/LuaSnip",
    -- trouble: show errors with :Trouble
    {
        'folke/trouble.nvim',
        init = function ()
            require("which-key").register({
                ["<space>t"] = { ":TroubleToggle<cr>", "Open/close Trouble" },
            })
        end
    },
    -- which-key: shortcuts
    {
        "folke/which-key.nvim",
        init = function ()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            local wk = require('which-key')
            wk.setup{}
            wk.register({
                ["<space>"] = {
                    w = { ":w<cr>", "Save" },
                    q = { ":q<cr>", "Quit" },
                }
            })
        end
    },
    -- Telescope: fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-lua/popup.nvim",
        },
        init = function()
            local telescope = require("telescope")
            require("which-key").register({
                ["<space>f"] = {
                    name = "Find",
                    f = {"<cmd>Telescope find_files<cr>", "Find files"},
                    g = {"<cmd>Telescope live_grep<cr>", "Find in files"},
                    b = {"<cmd>Telescope buffers<cr>", "Find buffers"},
                    h = {"<cmd>Telescope help_tags<cr>", "Find help"},
                }
            })
        end
    },
    -- NvimTree: file explorer
    {
        "nvim-tree/nvim-tree.lua",
        init = function ()
            vim.g.loaded_netrw = 1
            vim.g.loaded_netrwPlugin = 1
            require("which-key").register({
                ["<space>e"] = { ":NvimTreeToggle<cr>", "Open/close NvimTree" },
            })
        end,
        opts = {}
    },
    -- change project root to git root
    "airblade/vim-rooter",
    -- Git helper
    {
        "tpope/vim-fugitive",
        init = function ()
            require("which-key").register({
                ["<space>g"] = {
                    name = "Git",
                    c = { "<cmd>Git commit<cr>", "Commit" },
                    a = { "<cmd>Git add " .. vim.fn.expand('%:p') .. "<cr>", "Stage current file" },
                    A = { "<cmd>Git add --patch " .. vim.fn.expand('%:p') .. "<cr>", "Stage current file selectively" },
                    u = { "<cmd>Git restore --staged " .. vim.fn.expand('%:p') .. "<cr>", "Unstage current file" },
                    p = { "<cmd>Git push<cr>", "Push" },
                    s = { "<cmd>Git status<cr>", "Status" },
                    d = { "<cmd>Git diff<cr>", "Diff" },
                    r = { "<cmd>Git restore ".. vim.fn.expand('%:p') .."<cr>", "Restore current file" },
                    R = { "<cmd>Git restore --patch ".. vim.fn.expand('%:p') .."<cr>", "Restore current file selectively" },
                }
            })
        end
    },
    -- Auto close brackets that aren't annoying (= closing already closed brackets)
    {
        "windwp/nvim-autopairs",
        -- Actually call require("nvim-autopairs").setup()
        opts = {}
    },
    -- Automatically add, change, and remove pairs of quotes, brackets, etc.
    "tpope/vim-surround",
    -- Easily comment/decomment code
    "tpope/vim-commentary",
    -- Automatically detect tab/space indentation
    "tpope/vim-sleuth",
    -- Fountain (screenplay magkup language) support
    "kblin/vim-fountain",
    -- Rust integration
    {
        "rust-lang/rust.vim",
        init = function ()
            vim.g.rustfmt_autosave = 1
        end
    },
})


------------------------
-- Additional options --
------------------------

-- Enable relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Show gutter in line numbers
vim.opt.signcolumn = "number"

-- Disable those annoying swap files
vim.opt.swapfile = false

-- Store undo history between sessions
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("cache") .. "/undo"

-- Set tab width to 4 spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Enable mouse support just in case I turn into a normie (magic!)
vim.opt.mouse = "a"

-- Enable system clipboard support
vim.opt.clipboard = "unnamedplus"

-- Word wrap
vim.opt.wrap = true
vim.opt.linebreak = true

-- Bind S to replace every occurence (normal mode)
vim.cmd [[map S :%s//g<Left><Left>]]

