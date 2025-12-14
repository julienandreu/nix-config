vim.g.mapleader = " "
vim.keymap.set("n", "<leader><leader>", function()
	vim.cmd("so")
end)

-- Oil
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
