-- lua/repl.lua
local M = {}

-- Store job/channel ids for terminals we open
M.jobs = {
  python = nil,
  ipython = nil,
  r = nil,
}

-- Find the rightmost non-floating window
local function rightmost_window()
  local wins = vim.api.nvim_list_wins()
  local best_win, best_col = nil, -1

  for _, win in ipairs(wins) do
    local cfg = vim.api.nvim_win_get_config(win)
    if not cfg.relative or cfg.relative == "" then
      local pos = vim.api.nvim_win_get_position(win)
      local col = pos[2]
      if col > best_col then
        best_col = col
        best_win = win
      end
    end
  end

  return best_win
end

-- If the given window is a terminal, return its job id; else nil
local function terminal_job_in_window(win)
  if not win then return nil end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "terminal" then
    return nil
  end
  return vim.b[buf].terminal_job_id
end

-- Prefer sending to the rightmost terminal window (your interpreter pane)
local function right_pane_job()
  return terminal_job_in_window(rightmost_window())
end


-- Open (or reuse) a terminal split and remember its job id
local function open_term(kind, cmd)
  -- If we already have a live job, don't reopen
  if M.jobs[kind] and vim.fn.chansend(M.jobs[kind], "") == 0 then
    return M.jobs[kind]
  end

  -- Open a split terminal
  vim.cmd("botright split")
  vim.cmd("resize 12")
  vim.cmd("terminal " .. cmd)

  -- The terminal job id lives in b:terminal_job_id
  local job = vim.b.terminal_job_id
  M.jobs[kind] = job

  -- Optional: go back to previous window automatically
  vim.cmd("wincmd p")

  return job
end

function M.open_python()
  return open_term("python", "python -i")
end

function M.open_ipython()
  return open_term("ipython", "ipython")
end

function M.open_r()
  -- Use plain R. If you prefer radian: "radian"
  return open_term("r", "R")
end

-- Get visual selection as a string (preserves lines, handles partial line selection)
local function get_visual_selection()
  -- Visual range positions
  local _, ls, cs = unpack(vim.fn.getpos("'<"))
  local _, le, ce = unpack(vim.fn.getpos("'>"))

  if ls > le or (ls == le and cs > ce) then
    -- Swap if reversed
    ls, le = le, ls
    cs, ce = ce, cs
  end

  local lines = vim.fn.getline(ls, le)
  if #lines == 0 then return "" end

  -- Trim first/last line to match columns
  lines[1] = string.sub(lines[1], cs)
  lines[#lines] = string.sub(lines[#lines], 1, ce)

  return table.concat(lines, "\n") .. "\n"
end

-- Cell marker (VS Code style): "# %%"
local CELL_PAT = [[^\s*#\s*%%]]
local CELL_VIM_PAT = [[^\s*#\s*%%]]     -- for vim.fn.search
local CELL_LUA_PAT = "^%s*#%s*%%%%"      -- for string.match


-- Move cursor to the start of the next cell (after a # %% marker)
local function goto_next_cell()
  local cur = vim.api.nvim_win_get_cursor(0)
  local row = cur[1]

  local last_line = vim.api.nvim_buf_line_count(0)

  -- Search forward for next cell marker
  for i = row + 1, last_line do
    local line = vim.fn.getline(i)
    if line:match(CELL_LUA_PAT) then
      -- Move to first non-blank line after marker
      local target = i + 1
      while target <= last_line and vim.fn.getline(target):match("^%s*$") do
        target = target + 1
      end
      vim.api.nvim_win_set_cursor(0, { target, 0 })
      return
    end
  end
end


-- Return the text of the cell containing the cursor.
-- If no cell markers exist, return the whole file.
local function get_cell_text()
  local cur = vim.api.nvim_win_get_cursor(0) -- {row, col}, row is 1-indexed
  local cur_row = cur[1]

  local last_line = vim.api.nvim_buf_line_count(0)

  -- Save/restore cursor so searches don't move you
  local saved = vim.fn.getpos(".")

  -- Find previous cell marker (including current line)
  vim.fn.setpos(".", {0, cur_row, 1, 0})
  local start_marker = vim.fn.search(CELL_PAT, "bnW") -- backward, no wrap
  local start_line
  if start_marker == 0 then
    start_line = 1
  else
    start_line = start_marker + 1 -- start AFTER the marker line
  end

  -- Find next cell marker (search forward from start_line)
  vim.fn.setpos(".", {0, start_line, 1, 0})
  local next_marker = vim.fn.search(CELL_PAT, "nW") -- forward, no wrap
  local end_line
  if next_marker == 0 then
    end_line = last_line
  else
    end_line = next_marker - 1 -- end BEFORE next marker
  end

  -- Restore cursor
  vim.fn.setpos(".", saved)

  if end_line < start_line then
    return ""
  end

  local lines = vim.fn.getline(start_line, end_line)
  return table.concat(lines, "\n") .. "\n"
end


-- Write text to a temp file with a stable name (so you can inspect it)
local function write_temp(ext, text)
  local dir = vim.fn.stdpath("cache") .. "/replblocks"
  vim.fn.mkdir(dir, "p")

  local path = dir .. "/temp_block." .. ext
  local ok, err = pcall(function()
    local f = assert(io.open(path, "w"))
    f:write(text)
    f:close()
  end)
  if not ok then
    vim.notify("Failed writing temp file: " .. tostring(err), vim.log.levels.ERROR)
    return nil
  end
  return path
end

-- Send a command to a terminal job
local function send(job, cmd)
  if not job then
    vim.notify("No REPL job found for this language.", vim.log.levels.WARN)
    return
  end
  vim.fn.chansend(job, cmd .. "\r") -- edited from \n
end

-- Public: run visual selection in Python (plain python -i)
function M.run_visual_python()
  local text = get_visual_selection()
  if text == "" then return end

  local path = write_temp("py", text)
  if not path then return end

  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal (python/ipython).", vim.log.levels.WARN)
    return
  end

  -- plain python REPL doesn't understand %run
  send(job, ("exec(open(%q).read(), globals())"):format(path))
end


-- Public: run visual selection in IPython (%run -i keeps namespace)
function M.run_visual_ipython()
  local text = get_visual_selection()
  if text == "" then return end

  local path = write_temp("py", text)
  if not path then return end

  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal (ipython).", vim.log.levels.WARN)
    return
  end

  send(job, ("%%run -i %s"):format(vim.fn.fnameescape(path)))
end



-- Public: run visual selection in R (source)
function M.run_visual_r()
  local text = get_visual_selection()
  if text == "" then return end

  local path = write_temp("R", text)
  if not path then return end

  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal (R).", vim.log.levels.WARN)
    return
  end

  send(job, ('source("%s")'):format(path:gsub("\\", "\\\\")))
end

function M.run_cell_python()
  local text = get_cell_text()
  if text == "" then return end

  local path = write_temp("py", text)
  if not path then return end

  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal. Open python with <C-p> (or your REPL opener) first.", vim.log.levels.WARN)
    return
  end 
  send(job, ("exec(open(%q).read(), globals())"):format(path))
  goto_next_cell()
end

function M.run_cell_ipython()
  local text = get_cell_text()
  if text == "" then return end

  local path = write_temp("py", text)
  if not path then return end

  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal. Open ipython with <C-i> (or your REPL opener) first.", vim.log.levels.WARN)
    return
  end
  send(job, ("%%run -i %s"):format(vim.fn.fnameescape(path)))
  goto_next_cell()
end

function M.run_cell_r()
  local text = get_cell_text()
  if text == "" then return end

  local path = write_temp("R", text)
  if not path then return end
  
  local job = right_pane_job()
  if not job then
    vim.notify("Right pane is not a terminal. Open python with <C-r> (or your REPL opener) first.", vim.log.levels.WARN)
    return
  end
  send(job, ('source("%s")'):format(path:gsub("\\", "\\\\")))
  goto_next_cell()
end


return M

