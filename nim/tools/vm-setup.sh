#!/bin/bash

HOST=$1

sudo apt install vim tmux htop wget parallel

wget http://${HOST}/plinko/nim/release.tar.gz
tar xvf release.tar.gz
chmod +x ./build/plinko
chmod +x ./scripts/*.sh

wget https://raw.githubusercontent.com/mattbierbaum/system/master/dotfiles/tmux/tmux.conf
mv tmux.conf ${HOME}/.tmux.conf
mkdir -p ${HOME}/.tmux
touch ${HOME}/.tmux/tmux.child1
touch ${HOME}/.tmux/tmux.child2
touch ${HOME}/.tmux/tmux.child3
touch ${HOME}/.tmux/tmux.two
touch ${HOME}/.tmux/tmux.three
sed -i '/vi-copy/d' ${HOME}/.tmux.conf 
echo "alias l='ls -lh'" >> ${HOME}/.bashrc
. ${HOME}/.bashrc