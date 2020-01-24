#!/bin/bash

if $(which redshift &> /dev/null) ; then
  redshift -l 37.118323:-113.309552 &
fi
