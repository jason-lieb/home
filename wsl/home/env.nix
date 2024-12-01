let
  envFile = builtins.readFile "/home/jason/home/.env";
  envLines = builtins.filter (line: line != "" && line != [ ]) (builtins.split "\n" envFile);
in
builtins.listToAttrs (
  map (
    line:
    let
      parts = builtins.split "=" line;
      key = builtins.elemAt parts 0;
      value = builtins.elemAt parts 2;
    in
    {
      name = key;
      value = value;
    }
  ) envLines
)
