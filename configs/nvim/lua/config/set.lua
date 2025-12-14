vim.cmd("hi normal guibg=NONE")

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.colorcolumn = "80"

vim.api.nvim_set_hl(0, "CursorLine", { bg = "#101010" })
vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#181818" })

vim.opt.termguicolors = true
