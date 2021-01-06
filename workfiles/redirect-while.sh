#!/bin/bash
# Attempts to get a function to read input from a string through
# string input redirection.

function debug(){                                     # print a debug message
    if [[ ! -z "$DEBUG" ]]; then
        echo "==DBG== $1" > /dev/stderr
    fi
}

function redirect() {
    while read -r; do
        case "$REPLY" in
            "10")
                debug "Reached 10"
                break
                ;;
            *)
                echo "line $REPLY"
                ;;
        esac
    done > out.txt
}

redirect <<< "$(seq 20)"
