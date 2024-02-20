#!/usr/bin/env bash

# $1 is the version of node
# rm -rf ~/.nvm/versions/node # need sudo?
# mkdir ~/.nvm/versions/node
# nvm deactivate?
# nvm uninstall 16.20.0
nvm install $1
nvm alias default $1
npm i -g yarn
