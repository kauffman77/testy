#!/bin/bash

# declare -a program_keys                 # INDEXED: each program has a unique key
# declare -A program_pid                  # ASSOCIATIVE: pid of the multiple programs used during the test
# declare -A program_state                # ASSOCIATIVE: 1 for program still running, 0 for program complete/killed
# declare -A program_name                 # ASSOCIATIVE: name of programs, 1st word in command, useful for pkill
# declare -A program_command              # ASSOCIATIVE: full command for each program
# declare -A program_tofifo               # ASSOCIATIVE: file names for fifos for writing to the program
# declare -A program_tofifo_fd            # ASSOCIATIVE: fds for the fifos for writing to the clients
# declare -A program_fromfile             # ASSOCIATIVE: names of files for data coming from the files

ticktime=0.5                            # used to sleep for a duration before taking next action
ticktime=0.25                            # used to sleep for a duration before taking next action
ticktime=0.1
longticks=8

STDBUF="stdbuf -i 0 -o 0 -e 0"          # disables standard IO buffering for a program
TIMEOUT=${TIMEOUT:-"5"}                 # time after which to kill a test, passed to 'timeout' command and program_wait();
                                        # ^^ Don't use '5s' as the letters mess up program_wait
TIMEOUTCMD="timeout --signal KILL"      # kills user programs after a certain duration  of 'timeout'  
VALG_ERROR="13"                         # error code that valgrind should return on detecting errors
VALGRIND_PROG="valgrind --leak-check=full --show-leak-kinds=all --error-exitcode=$VALG_ERROR --track-origins=yes"
VALGRIND_OPTS="--suppressions=test_valg_suppress_leak.conf"

valgrind_reachable=1

use_valgrind=1

function updateline(){                                # processes $line to set some other global variables
    # debug "updateline: '$REPLY'"
    line="$REPLY"                                     # copy from REPLY built-in variable to avoid losing whitespace
    ((linenum++))                                     # update the current line number 
    first="${line%% *}"                               # extracts the first word on the line 
    rest="${line#* }"                                 # extracts remainder of line
}    

function tick() {                       # command to pause input
    sleep $ticktime
}


function debug(){                       # print a debug message
    if [[ ! -z "$DEBUG" ]]; then
        echo "==DBG== $1" > /dev/stderr
    fi
}


# Calls wait on program with given key, captures return value of
# program from wait, marks it as no longer running. If program is
# unresponsive for TIMEOUT seconds, kills it and marks it as timed
# out.
function program_wait () {
    debug "program_wait '$1'"
    key="$1"
    pid=${program_pid[$key]}
    curtime=0.0
    step=0.1                                          # amount of time to wait in between checks on program
    while kill -0 $pid &> /dev/null &&            # loop examining if program is complete
          [[ $(bc <<< "$curtime < $TIMEOUT") == "1" ]];
    do
        sleep $step                                   # sleep a short time and then 
        curtime=$(bc <<< "$curtime + $step")
    done

    if kill -0 $pid &> /dev/null; then            # program still alive after timeout
        printf "Killing unresponsive program '%s' (%s)\n" "$key" "${program_command[$key]}"
        kill -9 $pid &> /dev/null                 # kill it
        wait "${program_pid[$key]}" &> /dev/null      # wait on the child to finish, safe as its killed
        program_state[$key]="TimedOut"
        program_retcode[$key]=$TIMEOUT_RETCODE
    else
        wait "${program_pid[$key]}" &> /dev/null      # wait on the child to finish, safe as its done
        program_retcode[$key]=$ret
        program_state[$key]="Done"
    fi
    return 0
}


# function program_wait () {
#     debug "program_wait '$1'"
#     key="$1"
#     debug "with state ${program_state[$key]}"

#     if [[ "${program_state[$key]}" == "Running" ]]; then
#         debug "Waiting on ${program_pid[$key]} (${program_command[$key]})"
#         curtime=0
#         wait "${program_pid[$key]}" &> /dev/null            # wait on the child to finish
#         ret=$?
#         program_retcode[$key]=$ret
#         program_state[$key]="Done"
#         debug "wait completed with return code $ret"

#         return 0
#     else
#         return 1
#     fi
# }

# Check if the program is running or dead. Update the program_state[]
# array for the given key setting the entry to 0 if the program is no
# longer alive.  Uses the 'kill -0 pid' trick which doesn't actually
# deliver a signal but gives a 0 return code if a signal could be
# delivered and a 1 error code if not. A return value from this of 0
# indicates success (program is still alive) and nonzero indicates the
# program is dead. Use in conditional constructs like:
# 
# if ! program_alive "server"; then
#   printf "It's dead, Jim"
# fi
function program_alive () {
    key="$1"
    if [[ "${program_state[$key]}" == "Done" ]]; then
        printf "Program '$key' has already died\n"
        return 0
    fi
    pid=${program_pid[$key]}
    output=$(kill -0 $pid 2>&1)
    ret=$?                                            # capture return val for kill: 0 for alive, 1 for dead
    if [[ "$ret" != "0" ]]; then
        printf "Program '$key' is not alive: $output\n"
        program_wait "$key"                           # wait on program and mark as dead
    fi
    return $ret
}

function program_start () {                           # create a new program, populate data structures with its info
    debug "program_start '$1' '$2'"
    key="$1"
    progcmd="$2"
    program_keys+=($key)
    debug "Adding program w/ key '$key' command '$progcmd'"
    program_command[$key]="$progcmd"
    program_name[$key]="${progcmd%% *}"
    program_tofifo[$key]=$(mktemp $resultraw/testy_to.XXXXXX)     # set up communication with the program being tested
    program_fromfile[$key]=$(mktemp $resultraw/testy_from.XXXXXX) #
    
    if [[ "$use_valgrind" = 1 ]]; then
        program_valgfile[$key]=$(mktemp $resultraw/testy_valg.XXXXXX)
        VALGRIND="${VALGRIND_PROG} ${VALGRIND_OPTS} --log-file=${program_valgfile[$key]}"
    else
        program_valgfile[$key]="NONE"
        VALGRIND=""
    fi

    rm -f ${program_tofifo[$key]} ${program_fromfile[$key]} # remove just in case
    mkfifo ${program_tofifo[$key]}                          # create the fifo going to the program
    
    cmd="$STDBUF $VALGRIND $progcmd <${program_tofifo[$key]} &> ${program_fromfile[$key]} &"
    debug "running: '$cmd'"
    eval $cmd                           # eval is required due to the complex redirections with < and >
    program_pid[$key]=$!
    debug "PID is '${program_pid[$key]}'"
    program_state[$key]="Running"
    program_retcode[$key]="?"

    exec {to}>${program_tofifo[$key]}   # open connection to fifo for writing
    program_tofifo_fd[$key]=$to
    debug "to: $to   program_tofifo_fd: ${program_tofifo_fd[$key]}"

    if [[ "$use_valgrind" == "1" ]]; then
        debug "use_valgrind=1, long ticks while starting program"
        for i in $(seq $longticks); do
            tick
        done
    else
        tick
    fi
    if ! program_alive "$prog_key"; then
        printf "Failed to start program '%s'\n" "${program_command[$key]}"
        return 1
    fi
}


# sends text to a program on standard input using the pre-established
# FIFO for that program.  The special message '%EOF' will close the
# FIFO used for input which should give the program end of input.
function program_send_input () {
    key="$1"
    msg="$2"
    
    if ! program_alive "$key"; then
        printf "Can't send INPUT to dead program '%s' (%s)\n" "$prog_key" "${program_command[$prog_key]}"
        return 1
    fi

    tofd=${program_tofifo_fd[$key]}     # extract the file descriptor for sending data to the child program
    case "$msg" in
        "%EOF")                         # end of input
            exec {tofd}>&-              # close fifo to child program
            ;;
        *)
            printf "%s\n" "$msg" >&$tofd  # print to open file descriptor, possibly replace with direct reference to fifo name
            ;;
    esac
    tick
}

# show the output for a given program
function program_get_output () {
    debug "program_get_output '$1' '$2'"
    key="$1"
    filter="$2"
    outfile=${program_fromfile[$key]}
    debug "output for '$key' is file '$outfile' with filter '$filter'"
    $filter $outfile
    return $?
}


# Check the valgrind output for the program for erros and print it if
# any errors appear. 
function program_valgrind_check () {
    debug "program_valgrind_check '$1' '$2'"
    if [[ "$use_valgrind" == "0" ]]; then
        printf "Valgrind Disabled\n"
        return 0;
    fi

    key="$1"
    filter="$2"
    progcmd="${program_command[$key]}"
    valgfile="${program_valgfile[$key]}"
    $filter $valgfile > ${valgfile}.filtered          # create a filtered version of the valgrind file to 
    valgfile=${valgfile}.filtered                     # remove spurious errors and use that output instead
    debug "Checking Valgrind for '$key' ($progcmd) filter '$filter' valgfile '$valgfile'"

    retcode="${program_retcode[$key]}"
    status="pass"
    case "$retcode" in                                # inspect return code for errors
        "$VALG_ERROR")
            status="FAIL"
            fail_messages+=("FAILURE($retcode): Valgrind detected errors")
            ;;
        137)
            status="FAIL"
            fail_messages+=("FAILURE($retcode) due to TIMEOUT: Runtime exceeded maximum of '$timeout'")
            ;;
        139)
            status="FAIL"
            fail_messages+=("FAILURE($retcode) due to Kill Signal from OS: likely a SEGFAULT occured")
            ;;
    esac        

    if [[ "$use_valgrind" = "1" ]] &&                 # if valgrind is on
       [[ "$valgrind_reachable" = "1" ]] &&           # and checking for reachable memory
       ! awk '/still reachable:/{if($4 != 0){exit 1;}}' ${valgfile}
    then                                              # valgrind log does not contain 'reachable: 0 bytes'
        status="FAIL"                               
        fail_messages+=("FAILURE: Valgrind reports reachable memory, may need to add free() or fclose()")
    fi

    if [[ "$status" == "FAIL" ]]; then
        printf "Valgrind detected problems for program '$progcmd'\n"
        cat $valgfile
    else
        printf "Valgrind OK\n"
    fi
    return 0
}

function program_signal() {
    debug "program_signal '$1' '$2'"
    key="$1"
    sig="$2"
    if ! program_alive "$key"; then
        printf "Can't send SIGNAL to dead program '%s' (%s)\n" "$prog_key" "${program_command[$prog_key]}"
        return 1
    fi

    cmd="kill $prog_rest ${program_pid[$prog_key]}"
    eval $cmd
    tick
}



# handles a TESTY_MULTI command; run in a context where
# printing/echoing will not go to the screen but is instead redirected
# into a file which will the "actual" results for the test session to
# be compared to the "expected" results from the session
function handle_multi_command() {
    debug "handle_multi_command: '$1'"
    multi_line="$1"
    multi_cmd="${multi_line%% *}"                     # extracts the first word on the line 
    multi_rest="${multi_line#* }"                     # extracts remainder of line
    prog_key="${multi_rest%% *}"                      # key to identify program, only applicable to some lines
    prog_rest="${multi_rest#* }"                      # remainder of program line, only applicable to some lines
    debug "multi_cmd: '$multi_cmd' multi_rest: '$multi_rest'"
    debug "prog_key: '$prog_key' prog_rest: '$prog_rest'"

    case "$multi_cmd" in
        "START")
            program_start "$prog_key" "$prog_rest"
            ;;
        "INPUT")
            program_send_input "$prog_key" "$prog_rest"
            ;;
        "OUTPUT")
            # cat "${program_fromfile[$prog_key]}"
            program_get_output "$prog_key" "$prog_rest"
            ;;
        "VALGRIND_CHECK")
            program_valgrind_check "$prog_key" "$prog_rest"
            ;;
        "SIGNAL")                                     # 'SIGNAL server -15' == 'kill -15 ${program_pid["server"]}'
            program_signal "$prog_key" "$prog_rest"
            ;;
        "WAIT")           
            program_wait "$prog_key"
            ;;

        "SHELL")
            eval "$multi_rest"
            ;;
        *)
            printf "TESTY FAILURE in handle_multi_command():\n" > /dev/stderr
            printf "Unknown command '%s' in line '%s'\n" > /dev/stderr
            printf "Aborting testy\n" > /dev/stderr
            exit 1
            ;;
    esac
    return $?
}

resultdir=${RESULTDIR:-"test-results"}                # directory where the resutls will be written
resultraw=${RESULTRAW:-"$resultdir/raw"}              # directory where actual / expect / valgrind results are stored
prefix=${PREFIX:-"test"}                              # prefix for the files that are produced by testy
prompt=">>"

# Run a test session where several programs must be started and
# coordinated at once. The session comprises a set of commands on when
# to start programs and what input should be given them at what
# time. The function is run in a context where 'read' will extract
# lines from the test session.
function run_testy_multi_session(){
    unset program_keys                 # INDEXED: each program has a unique key
    unset program_pid                  # ASSOCIATIVE: pid of the multiple programs used during the test
    unset program_state                # ASSOCIATIVE: 1 for program still running, 0 for program complete/killed
    unset program_name                 # ASSOCIATIVE: name of programs, 1st word in command, useful for pkill
    unset program_command              # ASSOCIATIVE: full command for each program
    unset program_tofifo               # ASSOCIATIVE: file names for fifos for writing to the program
    unset program_tofifo_fd            # ASSOCIATIVE: fds for the fifos for writing to the clients
    unset program_fromfile             # ASSOCIATIVE: names of files for data coming from the files
    unset program_retcode
    unset program_valgfile
    
    # -g for global, -a for indexed array, -A for associative array (hash)
    declare -g -a program_keys                 # INDEXED: each program has a unique key
    declare -g -A program_pid                  # ASSOCIATIVE: pid of the multiple programs used during the test
    declare -g -A program_state                # ASSOCIATIVE: "Running" or "Done"
    declare -g -A program_name                 # ASSOCIATIVE: name of programs, 1st word in command, useful for pkill
    declare -g -A program_command              # ASSOCIATIVE: full command for each program
    declare -g -A program_tofifo               # ASSOCIATIVE: file names for fifos for writing to the program
    declare -g -A program_tofifo_fd            # ASSOCIATIVE: fds for the fifos for writing to the clients
    declare -g -A program_fromfile             # ASSOCIATIVE: names of files for data coming from the files
    declare -g -A program_retcode              # ASSOCIATIVE: return code for program or "?" if still running
    declare -g -A program_valgfile             # ASSOCIATIVE: name of valgrind file when using valgrind or "NONE"
    
    mkdir -p $resultdir                               # set up test results directory
    mkdir -p $resultraw
    result_file=$(printf "%s/%s-%02d-result.tmp" "$resultdir" "$prefix" "$testnum")
    actual_file=$(printf "%s/%s-%02d-actual.tmp" "$resultraw" "$prefix" "$testnum")
    expect_file=$(printf "%s/%s-%02d-expect.tmp" "$resultraw" "$prefix" "$testnum")

    session_beg_line=$((linenum+1))                   # mark start of session to allow it to be extracted

    while read -r; do                                 # read a line from the test session
        updateline
        debug "$linenum: $line"
        case "$first" in
            "#+END_SRC")                              # end of test, break out
                debug "^^ end of testing session"
                break
                ;;
            "$prompt")
                debug "^^ handle_multi_command"
                printf "%s\n" "$line"
                handle_multi_command "$rest"
                ;;
            "#")
                printf "%s\n" "$line"
                debug "^^ comment"
                ;;
            *)                                        # other lines are test output which should be generated by the programs
                debug "^^ expected output"
                ;;
        esac
    done > ${actual_file}                             # redirect output of printf/echo into actual output
    session_end_line=$((linenum-1))                   # note the line session ends on to enable #+TESTY_RERUN:

    for key in "${program_keys[@]}"; do               # clean up files and other artifacts for each program
        to="${program_tofifo_fd[$key]}"
        exec {to}>&-                                  # close the tofifo
        rm -f "${program_tofifo[$key]}"               # remove tofifo
        # rm -f "${program_fromfile[$key]}"             # remove from file
        if [[ "${program_state[$key]}" == "Running" ]]; then
            kill -9 "${program_pid[$key]}" &> /dev/null # kill program
            program_wait "$key"                         # and wait for it to finish
        fi
    done

    # extract expected output from test file, filter #+TESTY_ , store result in expect_file
    cat $specfile | \
        sed -n "${session_beg_line},${session_end_line}p" | \
        grep -v '^#+TESTY_' \
        > ${expect_file}

    debug "Diffing files"
    diff -y ${expect_file} ${actual_file} > ${result_file}
    cat ${result_file}
    debug "Finished with run_testy_multi_session"
    return 0
}

specfile=$1

while read -r; do
    updateline
    printf "LINE: '%s'\n" "$line"
    case "$first" in
        "#+BEGIN_SRC")                            # test session starting
            printf "Begin testing session\n"
            run_testy_multi_session
            printf "End testing session at line '$line'\n"
            ;;

        *)
            printf "^^ Ignoring\n"
            ;;
    esac
done < $specfile
