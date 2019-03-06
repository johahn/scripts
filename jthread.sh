#!/bin/bash

# Repeatedly print the stacktrace of a given java thread(s).

pid=$1
threadName=$2
iterations=${3:-10}
stack=$((${4:-10} + 2))

sedPrintStacktraceOfGivenThread="/$threadName/,/\n\n/ p"

jstacks=""
for i in $(seq 1 $iterations);
do
  jstacks+=$(jstack $pid | sed -n -e "$sedPrintStacktraceOfGivenThread" | sed -n "2,${stack}p" | tr '\n' '|')'\n'
  printf '\r %d/%d' $i $iterations
done
printf '\r'

echo -e "$jstacks" | egrep -v '$^' | sort | uniq -c | sort -rn | awk '{count[NR]=$1; tot+=$1; $1=""; row[NR]=$0} END { for (i in count) { printf("%d (%.1f%%) %s", count[i], 100*count[i]/tot, substr(row[i],25)) }}' | sed $'s/|/\\\n   /g'
