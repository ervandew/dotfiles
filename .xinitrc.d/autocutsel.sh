#!/bin/bash

# Synchronize CLIPBOARD and PRIMARY (selection)
if $(which autocutsel &> /dev/null) ; then
  autocutsel -fork
  autocutsel -selection PRIMARY -fork
fi
