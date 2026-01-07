require("config")

-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- plugins
require("plugins")

-- repl code
local repl = require("repl")

-- Openers (normal mode)
--vim.keymap.set("n", "<leader>p", repl.open_python, { desc = "Open Python REPL" })
--vim.keymap.set("n", "<leader>i", repl.open_ipython, { desc = "Open IPython REPL" })
--vim.keymap.set("n", "<leader>r", repl.open_r, { desc = "Open R REPL" })

-- Runners (visual mode)
vim.keymap.set("v", "<leader>p", repl.run_visual_python, { desc = "Run selection in Python REPL" })
vim.keymap.set("v", "<leader>i", repl.run_visual_ipython, { desc = "Run selection in IPython" })
vim.keymap.set("v", "<leader>r", repl.run_visual_r, { desc = "Run selection in R" })

-- Cell runners (normal mode)
vim.keymap.set("n", "<leader>p", repl.run_cell_python, { desc = "Run cell in Python REPL" })
vim.keymap.set("n", "<leader>i", repl.run_cell_ipython, { desc = "Run cell in IPython" })
vim.keymap.set("n", "<leader>r", repl.run_cell_r, { desc = "Run cell in R" })

-- Line numbers
vim.opt.number = true        -- absolute line numbers
vim.opt.relativenumber = false

vim.keymap.set("n", "<leader>ln", function()
  vim.opt.number = not vim.opt.number:get()
end, { desc = "Toggle line numbers" })

