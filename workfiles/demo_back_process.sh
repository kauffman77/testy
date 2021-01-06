#!/bin/bash

# basic demo of using child process to print background messages to
# same spot as parent; when child is done, signals parent to shut down

function handle_signal() {
    exit 0
}

trap 'handle_signal' TERM
trap 'handle_signal' INT

ppid=$$

i=0
while ((i<3)); do
    sleep 2
    printf "BACKGROUND: message\n"
    ((i++))
done && echo "BACKGROUND DONE" && kill $ppid &
background_input_pid=$!

while read line < /dev/stdin; do
    printf "ENTERED: %s\n" "$line"
done 


# printf "fore: %s\n" "$foreground_input_pid"
# printf "back: %s\n" "$background_input_pid"
# kill -0 $foreground_input_pid
# kill -0 $background_input_pid

kill $background_input_pid

# wait $background_input_pid
# wait $foreground_input_pid

