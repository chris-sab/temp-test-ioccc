#!/usr/bin/env bash

ioc="$1"
: "${iocccsize:=iocccsize}"
: "${ioc:=prog}"

opt=-crs
kopt=-kcrs

for name in "$@"; do
	
	if test "$name" != "$ioc"; then

	a=$("$ioc" "$opt" < "$name" 2>&1)
	b=$("$iocccsize" "$opt" < "$name" 2>&1)
	if test "$a" != "$b"; then
		echo "$a" , "$b" , "$name"
	fi

	a=$("$ioc" "$kopt" < "$name" 2>&1)
	b=$("$iocccsize" "$kopt" < "$name" 2>&1)
	if test "$a" != "$b"; then
		echo "$a" , "$b" , "$name" " keep"
	fi

	fi
done
