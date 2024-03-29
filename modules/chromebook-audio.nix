{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "WeirdTreeThing";
    repo = "chromebook-ucm-conf";
    rev = "master"; # replace with the desired branch or commit
    sha256 = "0"; # replace with the correct hash
  };
in
pkgs.stdenv.mkDerivation rec {
  pname = "chromebook-ucm-conf";
  version = "1.0.0"; # replace with the actual version

  inherit src;

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/share/alsa/ucm2/{conf.d,common,codecs,platforms}
    cp -r ${src}/common $out/share/alsa/ucm2/common
    cp -r ${src}/codecs $out/share/alsa/ucm2/codecs
    cp -r ${src}/platforms $out/share/alsa/ucm2/platforms
    cp -r ${src}/sof-rt5682 $out/share/alsa/ucm2/conf.d/sof-rt5682
    cp -r ${src}/sof-cs42l42 $out/share/alsa/ucm2/conf.d/sof-cs42l42
  '';
}

# board: lillipup
# platform: tgl

# def install_ucm():
#     bash("rm -rf /tmp/chromebook-ucm-conf")
#     bash(f"git clone https://github.com/WeirdTreeThing/chromebook-ucm-conf -b {args.branch_name[0]} /tmp/chromebook-ucm-conf")

#     cpdir("/tmp/chromebook-ucm-conf/common", "/usr/share/alsa/ucm2/common")
#     cpdir("/tmp/chromebook-ucm-conf/codecs", "/usr/share/alsa/ucm2/codecs")
#     cpdir("/tmp/chromebook-ucm-conf/platforms", "/usr/share/alsa/ucm2/platforms")
#     cpdir("/tmp/chromebook-ucm-conf/sof-rt5682", "/usr/share/alsa/ucm2/conf.d/sof-rt5682")
#     cpdir("/tmp/chromebook-ucm-conf/sof-cs42l42", "/usr/share/alsa/ucm2/conf.d/sof-cs42l42")

# def sof_audio(platform):
#     install_package("sof-firmware", "firmware-sof-signed", "alsa-sof-firmware", "sof-firmware", "sof-firmware")
#
#     JSL needs tplg build from upstream which have not been shipped in distros yet
#     cpdir("conf/sof/tplg", "/lib/firmware/intel/sof-tplg")

# Install wireplumber config to increase headroom
# fixes instability and crashes on various devices
#      if path_exists("/usr/bin/wireplumber"):
#        print_status("Increasing alsa headroom (fixes instability)")
#        mkdir("/etc/wireplumber/main.lua.d/", create_parents=True)
#        cpfile("conf/common/51-increase-headroom.lua", "/etc/wireplumber/main.lua.d/51-increase-headroom.lua")
