#!/bin/sh

#remove old fifo
[ -e /dev/by-name/bootA_fifo ] && dd if=/dev/zero of=/dev/by-name/bootA_fifo
[ -e /dev/by-name/rootfsA_fifo ] && dd if=/dev/zero of=/dev/by-name/rootfsA_fifo

#create new fifo
ubiupdatevol /dev/by-name/bootA -f &
ubiupdatevol /dev/by-name/rootfsA -f &

sleep 1

[ ! -e /dev/by-name/bootA_fifo ] && return 1
[ ! -e /dev/by-name/rootfsA_fifo ] && return 1

return 0
