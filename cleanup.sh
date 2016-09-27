#!/usr/bin/env bash

cd `dirname $0`

rm node*/data/.erlang.cookie
rm node*/data/lmdb*
rm node*/logs/*.log*
