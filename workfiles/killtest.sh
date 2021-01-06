#!/bin/bash

function program_check () {
    key="$1"
    pid=${program_pid[$key]}
    output=$(kill -0 $pid 2>&1)
    ret=$?
    echo "kill $key gives $ret"
    if [[ "$ret" != "0" ]]; then
        echo "kill $key output is $output"
    fi
    program_dead[$key]=$ret
    return $ret
}


declare -A program_pid
program_pid[this]=$$
program_pid[that]=1

if ! program_check "this"; then
    echo this pid $$ is dead
fi
    

if ! program_check "that"; then
    echo that pid 1 is dead
fi
