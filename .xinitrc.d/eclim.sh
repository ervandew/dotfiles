#!/bin/bash

if [ -f $HOME/apps/eclipse/eclimd ] ; then
  # start eclim
  #$HOME/apps/eclipse/eclimd -b
  archlinux-java run java-11-openjdk $HOME/apps/eclipse/eclimd -b
fi
