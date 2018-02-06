#!/usr/bin/env /bin/bash

test1() {
	. ../bashon.sh
	local json=' { "a" : "b" } '
	local root="$(BASHON_parse "${json}" ouais)"
	echo "${root}"
}

test1
