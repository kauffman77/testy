#!/bin/bash
# 
# some examples of bash indirect variable references taken from
#   http://mywiki.wooledge.org/BashFAQ/006
# Was considering this approach to get 2D arrays but it is i a mess.

fruits=( APPLE BANANA ORANGE "STAR FRUIT" )
veggis=( Carrot Potato "Green Bean" Asparagus )

arrname='fruits'
indirect="$arrname[@]"
i=0
for x in "${!indirect}"; do
    echo "$i : $x"
    ((i++))
done

arrname='veggis'
indirect="${arrname}[2]"
echo "${!indirect}"

${!indirect[1]}="Kale"
i=0
for x in "${!indirect}"; do
    echo "$i : $x"
    ((i++))
done
