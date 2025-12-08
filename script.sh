#!/bin/bash


yacc -d -y --debug --verbose 22101088_22101357.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 22101088_22101357.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o -o compiler
echo 'All ready, running'
./compiler input.c
echo 'Log file content:'
cat 22101088_22101357_log.txt