{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  cb-linux-audio = pkgs.fetchFromGitHub {
    owner = "WeirdTreeThing";
    repo = "chromebook-linux-audio";
    rev = "2fedc1da9d85369acc79215182093d6ecacbf442";
    hash = "sha256-77s679xcXVbnkTUpHoRjIvB6Zhuxyaqf6Yzmgb0ZXVo=";
  };
  cb-ucm-conf = pkgs.fetchFromGitHub {
    owner = "WeirdTreeThing";
    repo = "chromebook-ucm-conf";
    rev = "b6ce2a76f6360b87bfe593ff14dffc125fd9c671";
    hash = "sha256-QRUKHd3RQmg1tnZU8KCW0AmDtfw/daOJ/H3XU5qWTCc=";
  };
  topology-package = pkgs.runCommandNoCC "topology-package" { } ''
    mkdir -p $out/lib/firmware/intel/sof-tplg
    cp -rf ${cb-linux-audio}/conf/sof/tplg/* $out/lib/firmware/intel/sof-tplg
  '';
  alsa-ucm-conf-cb = pkgs.alsa-ucm-conf.overrideAttrs (old: {
    installPhase = ''
      mkdir -p $out/share/alsa/ucm2/{conf.d,common,codecs,platforms}
      mkdir -p $out/share/alsa/ucm2/conf.d/{sof-rt5682,sof-cs42l42}
      cp -rf ${cb-ucm-conf}/common/* $out/share/alsa/ucm2/common
      cp -rf ${cb-ucm-conf}/codecs/* $out/share/alsa/ucm2/codecs
      cp -rf ${cb-ucm-conf}/platforms/* $out/share/alsa/ucm2/platforms
      cp -rf ${cb-ucm-conf}/sof-rt5682/* $out/share/alsa/ucm2/conf.d/sof-rt5682
      cp -rf ${cb-ucm-conf}/sof-cs42l42/* $out/share/alsa/ucm2/conf.d/sof-cs42l42
    '';
  });
in
{
  config = {
    sound.enable = true;
    nixpkgs.config.pulseaudio = true;
    hardware.enableAllFirmware = true;
    hardware.firmware = [ topology-package ];
    environment.systemPackages = [
      alsa-ucm-conf-cb
      pkgs.sof-firmware
    ];
    environment.etc."wireplumber/main.lua.d/51-increase-headroom.lua".text = builtins.readFile (
      cb-linux-audio + "/conf/common/51-increase-headroom.lua"
    );
    boot.extraModprobeConfig = ''
      options snd-intel-dspcfg dsp_driver=1
    '';
  };
}
