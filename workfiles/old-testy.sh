#!/bin/bash
#
# demonstrates some principles of file descritors in bash for
# communicating with a subprocess, 'bc' calculator in this case.

# Determine column width of the terminal
if [[ -z "$COLUMNS" ]]; then
    printf "Setting COLUMNS based on stty\n"
    COLUMNS=$(stty size | awk '{print $2}')
fi
if (($COLUMNS == 0)); then
    COLUMNS=126
fi

# printf "COLUMNS is $COLUMNS\n"

SDIFF="diff -bBy -W $COLUMNS"

DEBUG=1
function debug(){                                   # print a debug message
    if [[ ! -z "$DEBUG" ]]; then
        echo "==DBG== $1"
    fi
}

function updateline(){                              # update the current line number 
    ((linenum++))
    prefix="${line:0:2}"
    suffix="${line:2}"
}    

# function next_test(){                               # advance to the next test
#     # 

################################################################################
# BEGIN main processing
if [[ "$#" < 1 ]]; then
    printf "usage: testy <testspec> [testnum]\n"
    exit 1
fi

specfile=$1                                         # gather test file
debug "Testing $specfile"
shift

exec {stderr}>&2                                    # copy stderr
exec 2>testy.err                                    # redirects standard error to a log file


export linenum=0
export testnum=0
export npass=0
while read line; do
    updateline
    debug "$linenum: $line"
    if [[ "$prefix" == "* " ]]; then
        testname=$suffix
        ((testnum++))
        comments=""
    elif [[ "$prefix" = "#+" ]]; then
        debug "Begin testing session"

        to_fifo=$(mktemp --tmpdir testy_to.XXXXXX)
        from_fifo=$(mktemp --tmpdir testy_from.XXXXXX)
        debug "to_fifo: $to_fifo"
        debug "to_fifo: $from_fifo"

        rm -f ${to_fifo} ${from_fifo}

        mkfifo $to_fifo 
        mkfifo $from_fifo

        bc <${to_fifo} >${from_fifo} &
        pid=$!
        debug "child pid: $pid"

        exec {to}>${to_fifo}                                # open connection to fifo for writing
        exec {from}<${from_fifo}                            # and for reading
        debug "to fd: $to"
        debug "from fd: $from"


        failure=""
        actual="==== ACTUAL ===="
        expect="==== EXPECT ===="
        while read line; do                                 # BEGINNING of a test run
            updateline
            debug "$linenum: (TEST) $line"
            
            if [[ "$prefix" == "#+" ]]; then                # end of test
                debug "$line: End Testing Session"
                break
            elif [[ "$prefix" = "> " ]]; then               # test input
                input="$suffix\n"
                actual="$actual\n$line"
                expect="$expect\n$line"
                debug "Sending input: '$input'"
                printf "$input" >&$to
            else                                            # test output
                expect="$expect\n$line"
                read response 0<&$from
                debug "Response: $response"
                actual="$actual\n$response"

                # use diff to check individual line
                if $SDIFF <(echo "$line") <(echo "$response") &> /dev/null ; then
                    debug "Matches Expected"
                else
                    failure=1
                    break
                fi
            fi                                              # DONE with test input, either pass or fail
        done;
        if [[ ! -z "$failure" ]]; then                      # test failed
            actual_file=actual.tmp
            expect_file=expect.tmp
            printf "$actual\n"  > ${actual_file}
            printf "$expect\n" > ${expect_file}
            echo "FAILURE: Output Mismatch at Last line of Input"
            $SDIFF $expect_file $actual_file

            debug "FAILURE cleanup"
            debug "Killing child process"
            kill -KILL $pid &> /dev/null
            debug "closing to fifo ${to_fifo}"
            exec {to}>&-                                    # closes to to fifo
            while read line; do                                 # BEGINNING of a test run
                updateline
                debug "$linenum: (FAILED TEST) $line"
                if [[ "$prefix" == "#+" ]]; then                # end of test
                    debug "$line: End Testing Session"
                    break
                fi
            done

        else
            debug "NORMAL cleanup"                          # normal finish
            debug "closing to fifo ${to_fifo}"
            exec {to}>&-                                    # closes to to fifo

            debug "Checking child status with kill -0"
            kill -0 $pid  >& /dev/null
            debug "kill returned: $?"

            debug "waiting on finished child"
            wait $pid
            debug "wait returned: $?"
            ((npass++))
            debug "npass now $npass"
        fi
    else                                                    # COMMENTs about the test
        debug "comment: "
        comments="$comments\n$line"
    fi
done < $specfile

echo "$npass / $testnum  tests passed"

        # exec 2>&$stderr                                     # restore standard error
        # exec {stderr}>&-                                    # close backup of standard error
