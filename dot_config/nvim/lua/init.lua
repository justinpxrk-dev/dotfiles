vim.opt.number = true
vim.opt.colorcolumn = { "81", "121" }
vim.opt.mouse = "a"

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 4

vim.api.nvim_create_autocmd({ "FocusGained", "VimEnter" }, {
	callback = function()
		vim.wo.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "FocusLost" }, {
	callback = function()
		vim.wo.cursorline = false
	end,
})
