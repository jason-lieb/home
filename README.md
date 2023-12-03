# Home
A central repo for all my dotfiles, install scripts, etc.

## General Script Use

To grab and run a script from github, write a command in this format:

``sudo bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/utils/script.sh)"``

## Complete Fedora Installation and Set-Up

To go from a minimal installation of Fedora to the complete, customized installation run the following command:

``sudo bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/utils/setup-fedora.sh)"``

This will install everything, update the system, and reboot.

From there, run:

``sudo bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/utils/setup-ssh-key.sh)"``

to create an ssh key and either copy it to the clipboard or display it in the terminal.

Add this ssh key to github and then run:

``sudo bash -c "$(curl -fsSl https://raw.githubusercontent.com/jason-lieb/home/main/utils/setup-home.sh)"``

to setup the home directory, dotfiles, and other configuration.

### Un-Automated Set-Up

The following set-up of the Gnome environment is not yet automated

- Dark Theme
- Set up Displays (Orientation and Resolution)
- brave://password-manger/settings
    - Offer to save passwords → off
- Uninstall gnome bloat (todo)
- Install GNOME Shell integration (chrome extension)