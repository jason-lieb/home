{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  name = "chromebook-ucm-conf";

  src = pkgs.fetchFromGitHub {
    owner = "WeirdTreeThing";
    repo = "chromebook-ucm-conf";
    rev = "b6ce2a76f6360b87bfe593ff14dffc125fd9c671";
    sha256 = "QRUKHd3RQmg1tnZU8KCW0AmDtfw/daOJ/H3XU5qWTCc=";
  };

  installPhase = ''
    mkdir -p $out/share/alsa/ucm2/{conf.d,common,codecs,platforms}
    mkdir -p $out/share/alsa/ucm2/conf.d/{sof-rt5682,sof-cs42l42}
    cp -rf ${src}/common $out/share/alsa/ucm2/common
    cp -rf ${src}/codecs $out/share/alsa/ucm2/codecs
    cp -rf ${src}/platforms $out/share/alsa/ucm2/platforms
    cp -rf ${src}/sof-rt5682 $out/share/alsa/ucm2/conf.d/sof-rt5682
    cp -rf ${src}/sof-cs42l42 $out/share/alsa/ucm2/conf.d/sof-cs42l42
  '';
}

# board: lillipup
# platform: tgl

# def sof_audio(platform):
#     install_package("sof-firmware", "firmware-sof-signed", "alsa-sof-firmware", "sof-firmware", "sof-firmware")

# Install wireplumber config to increase headroom
# fixes instability and crashes on various devices
#      if path_exists("/usr/bin/wireplumber"):
#        print_status("Increasing alsa headroom (fixes instability)")
#        mkdir("/etc/wireplumber/main.lua.d/", create_parents=True)
#        cpfile("conf/common/51-increase-headroom.lua", "/etc/wireplumber/main.lua.d/51-increase-headroom.lua")
