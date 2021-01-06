#!/bin/bash
# testing to see if we can get functions to run in subshells /
# subprocesses, according to reading, this is either not easy or not
# possible

i=0
function doyes() {
    while true; do
        echo yes
        ((i++))
    done
}

$(doyes &)
pid=$?

sleep 1
echo "killing $pid"
kill $pid

echo "i has value $i"

