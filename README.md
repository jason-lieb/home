# Nix Home Configuration

## NixOs Setup

```
bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/setup-nixos.sh)"
```

## Nix Profiles Use

### Install
```
nix profile install ./profiles#backend
```

### Update
```
nix profile upgrade ./profiles#backend
```

### Initialize cache example
```
nix build --no-link --print-out-paths github:ghostty-org/ghostty#default
```
