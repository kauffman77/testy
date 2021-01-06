#!/bin/bash
#
# demonstrates some principles of file descritors in bash for
# communicating with a subprocess, 'bc' calculator in this case.

rm -f to.fifo from.fifo
mkfifo to.fifo 
mkfifo from.fifo

bc <to.fifo >from.fifo &
pid=$!
echo "bc pid: $pid"

exec {to}>to.fifo              # open connection to fifo for writing
exec {from}<from.fifo          # and for reading

echo "to fd: $to"
echo "from fd: $from"



input="5+5\n7+7\n"
echo "Sending input: '$input'"
printf "$input" >&$to
read response 0<&$from
echo "Response: $response"
read response 0<&$from
echo "Response: $response"

kill -0 $pid
echo "kill returned: $?"

input="10+10\n"
echo "Sending input: '$input'"
printf "$input" >&$to
read response 0<&$from
echo "Response: $response"

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

# echo "Cleaning up child"
# wait $pid
# echo "wait returned: $?"

rm -f to.fifo from.fifo
