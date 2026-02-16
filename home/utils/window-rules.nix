rec {
  applyInitial = value: {
    inherit value;
    apply = "initially";
  };

  applyForce = value: {
    inherit value;
    apply = "force";
  };

  matchWindowClass = windowClass: {
    value = windowClass;
    type = "substring";
  };

  matchWindowTitle = title: {
    value = title;
    type = "exact";
  };

  maximize = map (windowClass: {
    description = "Maximize ${windowClass}";
    match = {
      window-class = matchWindowClass windowClass;
      title = {
        value = "^(?!Bitwarden - Vivaldi$).*";
        type = "regex";
      };
    };
    apply = {
      maximizehoriz = applyInitial true;
      maximizevert = applyInitial true;
    };
  });

  moveToSidewaysScreen = map (
    windowClass:
    let
      title = if windowClass == "vivaldi-stable" then "Notion Home | Notion - Vivaldi" else null;
      apply = if windowClass == "vivaldi-stable" then applyForce else applyInitial;
    in
    {
      description = "Move ${windowClass}${
        if title != null then " (${title})" else ""
      } to sideways screen";
      match = {
        window-class = matchWindowClass windowClass;
      }
      // (if title != null then { title = matchWindowTitle title; } else { });
      apply = {
        screen = apply 1;
        desktops = apply ""; # All desktops
      };
    }
  );

  defaultSize =
    (width: height: [
      {
        description = "Default window size ${toString width}x${toString height}";
        match.window-types = [ "normal" ];
        apply = {
          size = applyInitial "${toString width},${toString height}";
        };
      }
    ])
      1600
      1000;
}

# Helpers
# kdotool --shortcut Alt+Shift+W --name windowclass getactivewindow getwindowclassname
# kdotool --shortcut Alt+Shift+E --name windowtitle getactivewindow getwindowname
# journalctl --user -f -b
