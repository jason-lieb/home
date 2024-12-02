- Install WSL

```powershell
wsl --install --no-distribution
```

- Install Nix OS for WSL
    - Download from https://github.com/nix-community/NixOS-WSL/releases/latest

```powershell
wsl --import NixOS $env:Jason\NixOS\ nixos-wsl.tar.gz --version 2
wsl -d NixOS # Enter NixOS machine
wsl -s NixOS # Make NixOS the default distro
```

- Install Git Bash (https://git-scm.com/)
- Create SSH Key

```bash
ssh-keygen -t ed25519 -C "jason.lieb@outlook.com"
```

- Add to Windows SSH Agent

```powershell
# As Administrator
Get-Service -Name ssh-agent | Set-Service -StartupType Manual
Start-Service ssh-agent

# As Normal User
ssh-add c:/Users/Jason/.ssh/id_ed25519
```

- Add to WSL

```bash
cp -r /mnt/c/Users/Jason/.ssh ~ # Run in wsl
```

- Fix Permissions with .ssh if necessary

```bash
chmod 600 id_ed25519
```

- Add to Github

```bash
clip < ~/.ssh/id_ed25519.pub
```

- Clone in Config Flake and Rebuild
