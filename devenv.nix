{ pkgs, lib, config, inputs, ... }:

{
  # Docker itself comes from the host: bin/build-binaries needs a running
  # daemon, which a devenv shell cannot provide.
  packages = with pkgs; [ git libyaml ];

  # https://devenv.sh/languages/
  languages.ruby.enable = true;
}
