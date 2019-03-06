#!/usr/bin/bash
#!/bin/bash

# Repeatedly takes thread dumps on jvms and filters the results.
# syntax: grep_threads.sh +include -exclude [n=2] pid [pid2...]
# example: ./grep_threads.sh +getMatchingMemoryEntriesForScanning -count -aggregate pid | grep -v spaces
# example: ./grep_threads.sh +socketRead0 n=2 ${sudo jcmd | awk '/GSC/ {print $1}'}

awkProgram="BEGIN {RS=\"\n\n\"}"
highlight="^"
join=" "
n=1

while true; do
  if [[ ${1:0:1} == "+" ]]; then
    awkProgram="${awkProgram}${join}/${1:1}/"
    highlight="${highlight}|${1:1}"
  elif [[ ${1:0:1} == "-" ]]; then
    awkProgram="${awkProgram}${join}!/${1:1}/"
  elif [[ $1 == "n="* ]]; then
    n=${1:2}
  else
    break
  fi
  join=" && "
  shift
done

me=$(whoami)

declare -A sudos
declare -A last
declare -A count

while true; do
  for pid in ${@}; do
    # Lookup/Cache the owner/sudo needed to inspect each pid
    if [[ -z ${sudos[$pid]} ]]; then
      owner=$(ps -p $pid -o user | awk 'NR==2 {print $1}')
      if [[ -z $owner ]]; then
        echo "No such pid $pid" >&2
        continue
      fi
      sudos[$pid]=$(test "$me" == "$owner" && echo " " || echo "sudo -iu $owner")
    fi
    sudo=${sudos[$pid]}

    foo=$($sudo jcmd $pid Thread.print | awk "${awkProgram} {print $pid,\$0}")

    # Count the number of times we have seen the current stacktrace for the given pid
    if [[ ${last[$pid]} != "$foo" ]]; then
      count[$pid]=1
      last[$pid]="$foo"
    else
      count[$pid]=$((count[$pid]+1))
    fi

    # Print the stacktrace if it's been seen the specified number of times n
    if [ -n "$foo" ] && [ ${count[$pid]} -ge $n ]; then
      echo "$foo" | egrep --color "$highlight"
      count[$pid]=0
    fi
  done
done
