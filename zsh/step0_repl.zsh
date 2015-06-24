#!/usr/bin/env zsh

function READ(){
	read -re "?user> "
}

function EVAL(){
	print -r -- "$(<&0)"
}

function PRINT(){
	print -r -- "$(<&0)"
}

function rep(){
	READ | EVAL | PRINT
}

while true; do
	print -r -- "$(rep)"
done
