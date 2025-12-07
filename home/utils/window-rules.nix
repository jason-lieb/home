rec {
  trueInitial = {
    value = true;
    apply = "initially";
  };

  matchWindowClass = windowClass: {
    value = windowClass;
    type = "substring";
  };

  maxBoth = {
    maximizehoriz = trueInitial;
    maximizevert = trueInitial;
  };

  maximize = map (windowClass: {
    description = "Maximize ${windowClass}";
    match.window-class = matchWindowClass windowClass;
    apply = maxBoth;
  });

  maximizeOnSidewaysScreen = windowClass: {
    description = "Maximize ${windowClass} on sideways screen";
    match.window-class = matchWindowClass windowClass;
    apply = maxBoth // {
      screen = {
        value = 1;
        apply = "initially";
      };
    };
  };
}
