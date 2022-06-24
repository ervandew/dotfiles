#!/bin/bash

if $(which bluetoothctl &> /dev/null) ; then
  bluetoothctl power on
fi
