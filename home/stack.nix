{
  name = ".stack/config.yaml";
  value = {
    text = ''
      nix: { enable: false }
      system-ghc: true
      recommend-stack-upgrade: false
      notify-if-nix-on-path: false
      ghc-options:
        "$everything": -fconstraint-solver-iterations=10 -O0 -fobject-code -j +RTS -A64m -n2m -RTS
    '';
  };
}
