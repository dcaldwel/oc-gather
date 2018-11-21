#!/bin/bash

# Get output file string and create file. Exit if already exists.

getopts f: OPT

case $OPT in 
  f) 
    if test -e $OPTARG; then
      echo $OPTARG 'already exists. Will not overwrite.'
      exit 1
    else
      echo 'Creating' $OPTARG
      touch $OPTARG
    fi
  ;;

  ?)
    printf '\nUsage: oc-gather.sh -f <output filename>\n\n'
    exit 1
  ;;
esac


#
# Gather stuff
#

printf "\nGathering...\n\n"
echo 'oc-gather started:' >> $OPTARG; date >> $OPTARG
printf "\n\n--=oc commands=--\n\n" >> $OPTARG

oc version | tee -a $OPTARG

