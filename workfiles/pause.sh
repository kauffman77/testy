#!/bin/bash
#
# demonstrates some principles of file descritors in bash for
# communicating with a subprocess, 'bc' calculator in this case.

specfile=$1
echo "Testing $specfile"
shift

to_fifo=$(mktemp --tmpdir testy_to.XXXXXX)
from_fifo=$(mktemp --tmpdir testy_from.XXXXXX)
echo "to_fifo: $to_fifo"
echo "to_fifo: $from_fifo"

rm -f ${to_fifo} ${from_fifo}

mkfifo $to_fifo 
mkfifo $from_fifo

bc <${to_fifo} >${from_fifo} &
pid=$!
echo "child pid: $pid"

exec {to}>${to_fifo}              # open connection to fifo for writing
exec {from}<${from_fifo}          # and for reading

echo "to fd: $to"
echo "from fd: $from"

input="1+1\n"
echo "Sending input: '$input'"
printf "$input" >&$to

read response 0<&$from
echo "Response: $response"

kill -0 $pid
echo "kill returned: $?"

echo "Sending STOP signal"
kill -STOP ${pid}

echo "Pausing"
read

echo "Sending CONT signal"
kill -CONT ${pid}

echo "closing to fifo"
# printf "quit\n" >&$to
exec {to}>&-                    # closes to to fifo

echo "Checking child status with kill -0"
kill -0 $pid  >& /dev/null
echo "kill returned: $?"

read -t 0.1 response 0<&$from
echo "last read returned: $?"

echo "Checking child status with kill -0"
kill -0 $pid  >& /dev/null
echo "kill returned: $?"

echo "Cleaning up child"
wait $pid
echo "wait returned: $?"

rm -f ${to_fifo} ${from_fifo}
