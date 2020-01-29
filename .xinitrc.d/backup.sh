#!/bin/bash

if [ -f "$HOME/bin/backup" ] ; then
  # start backup loop
  $HOME/bin/backup -b
fi
