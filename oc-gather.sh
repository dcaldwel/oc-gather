#!/bin/bash

####
# Borrowed this short parseArgs() function from https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
parseArgs() {
while [[ $# > 0 ]] ; do
  case "$1" in
    -f)
      FILE=${2}
      shift
      ;;
    -n)
      NS=${2}
      ;;
  esac
  shift
done
}
####

####
# Get output file string and optional namespace string
parseArgs "$@"

# Exit if $FILE is blank
if [[ ! $FILE = *[!\ ]* ]]
  then
    printf "\nNo output file supplied.\nUsage: oc-gather -f <output file> [-n <namespace>]\n\n"
    exit 1
fi

# Exit if $FILE is set to '-'
if [[ ! $FILE = *[!\-]* ]]
  then
    printf "\nNo output file supplied.\nUsage: oc-gather -f <output file> [-n <namespace>]\n\n"
    exit 1
fi

# Exit if $FILE exists
if test -e $FILE
    then
      printf "\nOutput file $FILE already exists. Please move/rename/delete existing output file and retry.\n\n"
      exit 1
fi

# Create the file specified by $FILE
# but exit if touch return an error value (non-zero)
if touch $FILE ; then
  printf "\n$FILE created\n\n"
else
  printf "\nError creating file. Please check that any relevant directories exist.\n\n"
  exit 1
fi


# If $NS is blank, set it to '--all-namespaces'
if [[ ! $NS = *[!\ ]* ]] ; then
  NS="--all-namespaces"
  printf "\n\$NS set to $NS'\n\n"
  # Prepend '-n ' to given namespace for ease later
else
  NS="-n $NS"
fi
####


##############
# Gather info#
##############

# Load functions
source ./oc-gather-lib.sh

# Start of redirected commands
{

# Boilerplate
printf "==Started gather==\n"
date
printf "\nOptions used: output file = $FILE, namespace string = \'$NS\'"

gather_version
gather_misc
gather_nodes
gather_etcd
gather_storage
gather_network
gather_deployment errors
gather_events
gather_docker

printf "\n==End of gather==\n\n"

} | tee $FILE
