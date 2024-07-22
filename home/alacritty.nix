{
  name = ".config/alacritty/alacritty.toml";
  value = {
    text = ''
      # Default colors
      [colors.primary]
      background = '#1e1e1e'
      foreground = '#d4d4d4'

      # Cursor colors
      [colors.cursor]
      text = '#d4d4d4'
      cursor = '#a6a6a6'

      # Normal colors
      [colors.normal]
      black   = '#0d0d0d'
      red     = '#FF301B'
      green   = '#A0E521'
      yellow  = '#FFC620'
      blue    = '#1BA6FA'
      magenta = '#8763B8'
      cyan    = '#21DEEF'
      white   = '#EBEBEB'

      # Bright colors
      [colors.bright]
      black   = '#6D7070'
      red     = '#FF4352'
      green   = '#B8E466'
      yellow  = '#FFD750'
      blue    = '#1BA6FA'
      magenta = '#A578EA'
      cyan    = '#73FBF1'
      white   = '#FEFEF8'
    '';
  };
}
