{ ... }:

{
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    # defaultEditor = true;

    # plugins = [
    #   pkgs.vimPlugins.nvim-tree-lua
    #   {
    #     plugin = pkgs.vimPlugins.vim-startify;
    #     config = "let g:startify_change_to_vcs_root = 0";
    #   }
    # ];

    # plugins =
    #   with pkgs.vimPlugins;
    #   [
    #     ## Treesitter
    #     nvim-treesitter
    #     nvim-treesitter.withAllGrammars
    #     nvim-treesitter-textobjects
    #     nvim-lspconfig

    #     trouble-nvim
    #     plenary-nvim
    #     telescope-nvim
    #     telescope-fzf-native-nvim
    #     fidget-nvim

    #     ## cmp
    #     nvim-cmp
    #     cmp-nvim-lsp
    #     cmp-buffer
    #     cmp-cmdline

    #     clangd_extensions-nvim
    #     luasnip
    #     cmp_luasnip
    #     lspkind-nvim
    #     nvim-lint
    #     vim-surround
    #     vim-obsession
    #     kommentary
    #     neoformat
    #     lazygit-nvim
    #     gitsigns-nvim
    #     rainbow
    #     vim-sleuth
    #     lualine-nvim
    #     nvim-web-devicons
    #     lightspeed-nvim
    #     leap-nvim
    #     vim-repeat
    #     kanagawa-nvim

    #     ## Debugging
    #     nvim-dap
    #     nvim-dap-ui
    #     nvim-dap-virtual-text
    #   ]
    #   ++ [ mrc.vimPlugins.no-neck-pain-nvim ];

    #   extraConfig = ''
    #     lua << EOF
    #     ${builtins.readFile config/mappings.lua}
    #     ${builtins.readFile config/options.lua}
    #     ${builtins.readFile config/setup/cmp.lua}
    #     ${builtins.readFile config/setup/treesitter.lua}
    #     ${builtins.readFile config/setup/lspconfig.lua}
    #     ${builtins.readFile config/setup/luasnip.lua}
    #     ${builtins.readFile config/setup/trouble.lua}
    #     ${builtins.readFile config/setup/telescope.lua}
    #     ${builtins.readFile config/setup/kommentary.lua}
    #     ${builtins.readFile config/setup/lualine.lua}
    #     ${builtins.readFile config/setup/fidget.lua}
    #     ${builtins.readFile config/setup/lint.lua}
    #     ${builtins.readFile config/setup/leap.lua}
    #     ${builtins.readFile config/setup/gitsigns.lua}
    #     ${builtins.readFile config/setup/clangd_extensions.lua}
    #     ${builtins.readFile config/setup/dap.lua}
    #   '';
  };
}
