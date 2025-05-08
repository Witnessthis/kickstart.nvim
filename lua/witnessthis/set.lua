vim.g.mapleader = ' '
vim.g.python3_host_prog = '/usr/bin/python3'
vim.g.perl_host_prog = '/usr/bin/perl'

vim.opt.guicursor = ''

vim.opt.background = 'dark'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = 'yes'

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.updatetime = 50

vim.opt.tabstop = 8
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.diagnostic.config {
  virtual_text = true,
}
