return {
	{
		"catppuccin/nvim",
		name = "catppuccin-moccha",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavour = "mocha", -- latte, frappe, macchiato, mocha
			})
			vim.cmd.colorscheme("catppuccin-mocha")
		end,
	},
}
