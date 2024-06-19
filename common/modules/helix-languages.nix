{
  name = ".config/helix/languages.toml";
  value = {
    text = ''
      [[language]]
      name = "typescript"
      language-servers = [  "typescript-language-server", "tailwindcss-react", "eslint", "emmet-ls", "scls"]
      formatter = { command = 'npx', args = ["prettier", "--parser", "typescript"] }
      auto-format = true

      [[language]]
      name = "tsx"
      language-servers = [ "typescript-language-server", "tailwindcss-react", "eslint", "emmet-ls", "scls"]
      formatter = { command = 'npx', args = ["prettier", "--parser", "typescript"] }
      auto-format = true

      [[language]]
      name = "jsx"
      language-servers = [ "typescript-language-server", "tailwindcss-react", "eslint", "emmet-ls","scls"]
      grammar = "javascript"
      formatter = { command = 'npx', args = ["prettier", "--parser", "typescript"] }
      auto-format = true

      [[language]]
      name = "javascript"
      language-servers = [ "typescript-language-server", "tailwindcss-react", "eslint", "emmet-ls", "scls"]
      formatter = { command = 'npx', args = ["prettier", "--parser", "typescript"] }
      auto-format = true

      [[language]]
      name = "json"
      language-servers = [ "vscode-json-language-server" ]
      formatter = { command = 'npx', args = ["prettier", "--parser", "json"] }
      auto-format = true

      [language-server.vscode-json-language-server.config]
      json = { validate = { enable = true }, format = { enable = true } }
      provideFormatter = true

      [language-server.vscode-css-language-server.config]
      css = { validate = { enable = true } }
      scss = { validate = { enable = true } }
      less = { validate = { enable = true } }
      provideFormatter = true

      [[language]]
      name = "html"
      formatter = { command = 'npx', args = ["prettier", "--parser", "html"] }
      language-servers = [ "vscode-html-language-server", "tailwindcss-react", "emmet-ls"]
      auto-format = true

      [[language]]
      name = "css"
      formatter = { command = 'npx', args = ["prettier", "--parser", "css"] }
      language-servers = [ "vscode-css-language-server", "tailwindcss-react", "emmet-ls"]
      auto-format = true

      [[language]]
      name = "scss"
      formatter = { command = "prettier", args = ["--stdin-filepath", "dummy.scss"] }
      language-servers = ["vscode-css-language-server"]
      auto-format = true

      [language-server.eslint]
      args = ["--stdio"]
      command = "vscode-eslint-language-server"

      [language-server.eslint.config]
      format = { enable = true }
      nodePath = ""
      quiet = false
      rulesCustomizations = []
      run = "onType"
      validate = "on"
      codeAction = { disableRuleComment = { enable = true, location = "separateLine" }, showDocumentation = { enable = false } }
      codeActionsOnSave = { mode = "all", "source.fixAll.eslint" = true }
      experimental = { }
      problems = { shortenToSingleLine = false }
    '';
  };
}
