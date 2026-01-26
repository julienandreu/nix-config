local plugins = {}

-- Merge all plugin configurations
vim.list_extend(plugins, require("config.lazy.git"))
vim.list_extend(plugins, require("config.lazy.key"))
vim.list_extend(plugins, require("config.lazy.lsp"))
vim.list_extend(plugins, require("config.lazy.notification"))
vim.list_extend(plugins, require("config.lazy.oil"))
vim.list_extend(plugins, require("config.lazy.search"))
vim.list_extend(plugins, require("config.lazy.statusline"))
vim.list_extend(plugins, require("config.lazy.theme"))
vim.list_extend(plugins, require("config.lazy.undotree"))
vim.list_extend(plugins, require("config.lazy.winbar"))

return plugins

