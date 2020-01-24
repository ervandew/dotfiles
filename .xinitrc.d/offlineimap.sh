#!/bin/bash

if [ -f /usr/bin/offlineimap ] ; then
  # start offlineimap loop
  ~/bin/offlineimap &
fi
