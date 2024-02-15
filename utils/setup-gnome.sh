# Change keybinding from switching applications to switching windows
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"

# To Revert
# gsettings set org.gnome.desktop.wm.keybindings switch-windows []
# gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Alt>Tab']"