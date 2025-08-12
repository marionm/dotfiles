set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

" Autoreload this file when saving it
autocmd! bufwritepost init.vim source %

" System clipboard/sugar bindings
" TODO: Use C-* instead of D-* for non-osx systems
noremap <D-c> "+y
noremap <D-v> "+p
cnoremap <D-v> <C-r>+
imap <D-v> <C-r>+
noremap <D-t> :tabnew<CR>
noremap <D-s> :w<CR>
noremap <D-a> ggVGo

" NetrwSeek is ripped off from vim-vinegar so opening netrw starts with the
" current file selected. You can use :edit instead of :Explore to do the same
" thing without any additional calls, but that seems to make netrw the altfile,
" even when you prefix with :keepalt or set g:netrw_altfile=1
noremap - :Explore %:h<CR>:call NetrwSeek(expand('#:t'))<CR>
function! NetrwSeek(file) abort
  if get(b:, 'netrw_liststyle') == 2
    let pattern = '\%(^\|\s\+\)\zs'.escape(a:file, '.*[]~\').'[/*|@=]\=\%($\|\s\+\)'
  else
    let pattern = '^\%(| \)*'.escape(a:file, '.*[]~\').'[/*|@=]\=\%($\|\t\)'
  endif
  call search(pattern, 'wc')
  return pattern
endfunction
" This keeps netrw out of altfile, even after navigating up a directory
augroup netrw_fix
  autocmd!
  autocmd FileType netrw setlocal bufhidden=wipe
augroup END

" Neovide settings
" TODO: Wrap in neovide check
let g:neovide_cursor_animate_command_line = v:false
let g:neovide_cursor_animate_in_insert_mode = v:false
let g:neovide_cursor_animation_length = 0 " The flag to disable animations in command mode doesn't seem to work
" let g:neovide_cursor_trail_size = 0
" let g:neovide_position_animation_length = 0
" let g:neovide_scroll_animation_far_lines = 0
let g:neovide_scroll_animation_length = 0.00

" Inlined vim-rspec functionality, since the plugin isn't neovim compatible
" TODO: Why doesn't ~/. work here?
let g:rspec_runner = "/Users/mikemarion/.nvim_iterm2_runner"
let g:rspec_command = "rspec --format documentation --profile --"
func! RunRspec(mode)
  let s:is_spec = match(expand("%"), "_spec.rb$") != -1

  if a:mode == "file" && s:is_spec
    let s:rspec_target = expand("%")
  elseif a:mode == "line" && s:is_spec
    let s:rspec_target = expand("%") . ":" . line(".")
  elseif !exists("s:rspec_target")
    return
  endif

  execute "silent ! " . g:rspec_runner . " '" . g:rspec_command . " \"" . s:rspec_target . "\"'"
endfunc
map <Leader>t :call RunRspec("file")<CR>
map <Leader>s :call RunRspec("line")<CR>
map <Leader>p :call RunRspec("last")<CR>

lua << EOF
-- TODO: What plugin is setting this to a non-zero value?
conceeallevel = 0
EOF

lua << EOF
local lspconfig = require('lspconfig')

lspconfig.ts_ls.setup({
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
  on_attach = function(client, bufnr)
    -- Disable LSP syntax highlighting for now - I prefer Ale
    client.server_capabilities.semanticTokensProvider = nil
  end
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>k', function()
      if vim.lsp.get_clients({bufnr = 0})[1] then
        vim.lsp.buf.signature_help()
      end
    end, opts)
    vim.keymap.set('i', '<C-s>', function()
      if vim.lsp.get_clients({bufnr = 0})[1] then
        vim.lsp.buf.signature_help()
      end
    end, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)

    -- TODO: This doesn't seem to work as expected - it will only rename things in open buffers, not
    --       across the whole project (even though `gr` can find appropriate references).
    --       Also, it doesn't save those other buffers after a rename.
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  end,
})
EOF

lua << EOF
local cmp = require('cmp')

cmp.setup({
  completion = {
    autocomplete = false,  -- Disable automatic popup
    completeopt = 'menu,menuone',
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-n>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
      else
        fallback()
      end
    end, { 'i' }),
    ['<C-p>'] = cmp.mapping(function()
      cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
    end, { 'i' }),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  })
})
EOF
