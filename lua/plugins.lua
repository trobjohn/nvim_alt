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
})

