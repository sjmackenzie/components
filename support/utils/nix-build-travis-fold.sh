#! /usr/bin/env bash
set -e
set -u
set -o pipefail

function subfold() {
  local prefix=$1
  awk '
    BEGIN {
      date_cmd=sprintf("echo $(( ($(date +%%s) - 1) * 1000000000 + $(echo 1$(date +%%N)) ))")
      current_scope="'$prefix'"
      printf "travis_fold:start:%s\r", current_scope
      printf "travis_time:start:%s\r", current_scope
      date_cmd | getline start_time
      close(date_cmd)
    }
    /^building \x27\/nix\/store\/.*[.]drv\x27/ {
      date_cmd | getline finish_time
      close(date_cmd)
      printf "travis_time:end:%s:start=%s,finish=%s,duration=%s\r", \
        current_scope, start_time, finish_time, (finish_time - start_time)
      printf "travis_fold:end:%s\r", current_scope
      current_scope=$0
      sub("building \x27/nix/store/", "", current_scope)
      sub("\x27.*", "", current_scope)
      current_scope=current_scope ".." "'$prefix'"
      printf "travis_fold:start:%s\r", current_scope
      printf "travis_time:start:%s\r", current_scope
      date_cmd | getline start_time
      close(date_cmd)
    }
    { print }
    END {
      date_cmd | getline finish_time
      close(date_cmd)
      printf "travis_time:end:%s:start=%s,finish=%s,duration=%s\r", \
        current_scope, start_time, finish_time, (finish_time - start_time)
      printf "travis_fold:end:%s\r", current_scope
    }
  '
}

nix-build "$@" |& subfold ${!#}
