#!/bin/sh

template=$1
param=$(cat "$1.params")
aws cloudformation deploy --stack-name $1 --template-file "$1.json" --parameter-overrides $param