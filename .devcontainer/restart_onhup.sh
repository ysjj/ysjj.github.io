#!/bin/bash

program=("$@")
start_program() {
    "${program[@]}" &
    pid=$!
}
restart_program() {
    if kill -0 $pid; then
        kill $pid
        wait $pid
    fi
    start_program
}

trap 'restart_program' HUP
trap 'kill $pid; exit 0' TERM INT

start_program
while true; do
    wait $pid
    kill -0 $pid || start_program
done
