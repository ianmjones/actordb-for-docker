#!/usr/bin/env bash

cd `dirname $0`

rm -f node*/data/.erlang.cookie
rm -f node*/data/lmdb*
rm -f node*/logs/*.log*
