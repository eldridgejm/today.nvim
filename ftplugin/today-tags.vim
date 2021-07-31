set ft=today

lua << EOF
local opts = require('today.ui').get_buffer_options()
opts.categorizer.active = "first_tag"
vim.b.today = opts
EOF
