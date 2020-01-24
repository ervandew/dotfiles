#!/bin/bash

if $(which pulseaudio &> /dev/null) ; then
  pulseaudio --start
fi
