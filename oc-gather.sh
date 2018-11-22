#!/bin/bash

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
  printf "\nError creating file. Please check that the directory exists.\n\n"
  exit 1
fi


# If $NS is blank, set it to '--all-namespaces'
if [[ ! $NS = *[!\ ]* ]] ; then
  NS="--all-namespaces"
  printf "\n\$NS set to $NS'\n\n"
else
  NS="-n $NS"
fi


##############
# Gather info#
##############

# Boilerplate
printf "\n==Gathering data==\n\n" | tee -a $FILE
printf "oc-gather started: " >> $FILE
date >> $FILE
printf "\n" >> $FILE
printf "Options used: output file = $FILE, namespace string = \'$NS\'" >> $FILE

# Start of oc commands
printf "\n\n==oc commands==\n\n" >> $FILE
printf "\n\nLogged in to OpenShift as: \n" >> $FILE
oc whoami | tee -a $FILE
printf "\n\nVersion: \n" >> $FILE
oc version | tee -a $FILE
printf "\n\nStatus (verbose): \n" >> $FILE
oc status -v | tee -a $FILE

# Network
printf "\n\n==Network==\n" >> $FILE
printf "\nhostsubnet: \n" >> $FILE
oc get hostsubnet | tee -a $FILE
printf "\nclusternetwork: \n" >> $FILE
oc get clusternetwork | tee -a $FILE

# If networkpolicy plugin detected, get policies info
if grepMatch="$(oc get clusternetwork | grep 'networkpolicy')" ; then
  printf "\n\n==Detected networkpolicy plugin==\n" >> $FILE
  printf "\nnetnamespace: \n" >> $FILE
  oc get netnamespace | tee -a $FILE
  printf "\nGetting network policies: \n" >> $FILE
  oc get networkpolicy $NS | tee -a $FILE
  printf "\nDescribing network policies: \n" >> $FILE
  oc describe networkpolicy $NS | tee -a $FILE
  printf "\n==End of networkpolicy plugin section==\n" >> $FILE
fi

printf "\n==End of network section==\n\n" >> $FILE

printf "\n\n==EOF==\n\n" >> $FILE
