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
    type = "substring";
  };

  maximize = map (windowClass: {
    description = "Maximize ${windowClass}";
    match.window-class = matchWindowClass windowClass;
    apply = {
      maximizehoriz = applyInitial true;
      maximizevert = applyInitial true;
    };
  });

  moveToSidewaysScreen = map (
    windowClass:
    let
      title = if windowClass == "vivaldi" then "Home - Vivaldi" else null;
      apply = if windowClass == "vivaldi" then applyForce else applyInitial;
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
}
