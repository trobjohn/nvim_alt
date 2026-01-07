
-- leader is space:
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- Make Space purely a leader key (prevents Visual-mode "space moves right" fallthrough)
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })


-- Terminal panel commands:
--vim.keymap.set( 'n', '<C-t>', ':belowright split | term<CR>', {noremap=true,silent=true})
vim.keymap.set('n', '<leader>ii', ':rightbelow vsp | term ipython<CR>', { silent = true })
vim.keymap.set('n', '<leader>pp', ':rightbelow vsp | term python<CR>', { silent = true })
vim.keymap.set('n', '<leader>rr', ':rightbelow vsp | term R<CR>', { silent = true })
vim.keymap.set('n', '<leader>tt', function()
  vim.cmd('split | terminal')
  vim.cmd('wincmd J')     -- make it a full-width bottom split
  vim.cmd('resize 4')
end, { noremap = true, silent = true })


-- Ctrl+s to save:
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { silent = true })
vim.keymap.set({ "n", "v" }, "<C-s>", ":w<CR>", { silent = true })


-- Ctrl+q/+w/+e to exit/save-and-exit/hard exit:
vim.keymap.set("i", "<C-q>", "<Esc>:q<CR>",{silent=true})
vim.keymap.set({"n", "v"}, "<C-q>", ":q<CR>", {silent=true})

--vim.keymap.set("i", "<C-w>", "<Esc>:wq<CR>", {silent=true})
--vim.keymap.set({"n","v"}, "<C-w>", ":wq<CR>", {silent=true})

vim.keymap.set("i", "<C-e>", "<Esc>:qa<CR>", {silent=true})
vim.keymap.set({"n","v"}, "<C-e>", ":qa<CR>", {silent=true})


-- Timeout delay
vim.opt.timeout = true
vim.opt.timeoutlen = 2500   -- mappings: be patient
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 100    -- keycodes: be fast

-- Python settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
    vim.opt_local.expandtab = true
  end,
})

-- :set list
vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  space = "·",
}
vim.keymap.set("n", "<leader>w", function()
  vim.opt.list = not vim.opt.list:get()
end, { desc = "Toggle whitespace" })


-- home and end motions
-- ...normal mode
vim.keymap.set("n", "<C-h>", "^", { silent = true })
vim.keymap.set("n", "<C-l>", "$", { silent = true })
-- ...insert mode
vim.keymap.set("i", "<C-h>", "<C-o>^", { silent = true })
vim.keymap.set("i", "<C-l>", "<C-o>$", { silent = true })


-- Neo-tree automatically
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
      vim.cmd("Neotree")
    end
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    if vim.bo.filetype == "neo-tree" and vim.fn.winnr("$") == 1 then
      vim.cmd("quit")
    end
  end,
})


-- Visual-mode: send selection
-- vim.keymap.set("v", "<leader>r", function()
--   require("repl").send_visual_to_right_term()
-- end, { silent = true, desc = "Send selection to right REPL" })

--vim.keymap.set("n", "<leader>r", function()
-- require("repl").send_current_line_to_right_term()
--end, { silent = true, desc = "Send line to right REPL" })

--vim.keymap.set("v", "<leader>r", function()
--  require("repl").send_visual_via_tmpfile()
--end, { silent = true, desc = "Run selection via temp file" })

