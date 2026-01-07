require("lazy").setup({
  {
  "samharju/synthweave.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("synthweave") -- or "synthweave-transparent"
  end
  },
  {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" }, -- optional icons (can remove)
  config = function()
    require("lualine").setup({
      options = { theme = "auto" },
    })
  end,
  },
  {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  cmd = "Neotree",
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorer" },
    { "<leader>fe", "<cmd>Neotree filesystem reveal left<cr>", desc = "Explorer (reveal)" },
  },
  opts = {
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
      use_libuv_file_watcher = true,
    },
    window = {
      position = "left",
      width = 32,
    },
    default_component_configs = {
      git_status = {
        symbols = {
          added     = "✚",
          modified  = "",
          deleted   = "✖",
          renamed   = "󰁕",
          untracked = "",
        },
      },
    },
  },
}

})

