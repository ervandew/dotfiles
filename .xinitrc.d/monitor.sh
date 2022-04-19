#!/bin/bash

if [ -f $HOME/bin/laptop ] ; then
  # intialize display outputs by forcing a call to turn the internal monitor on
  # which will detect the external monitor and setup the displays accordingly.
  ~/bin/laptop monitor on

  # now attempt to turn the internal monitor off. if there is no external
  # monitor, this will print an error message and do nothing.
  ~/bin/laptop monitor off
fi
