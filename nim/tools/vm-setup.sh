#!/bin/bash

HOST=$1

sudo apt install vim tmux htop wget parallel
wget http://${HOST}/plinko/release.tar.gz
wget https://raw.githubusercontent.com/mattbierbaum/system/master/dotfiles/tmux/tmux.conf

tar xvf release.tar.gz
chmod +x ./build/plinko
chmod +x ./scripts/*.sh
mv tmux.conf ${HOME}/.tmux.conf
