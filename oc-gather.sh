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

# Miscellaneous oc commands
printf "\n\n==Miscellaneous oc commands==\n" >> $FILE
printf "\nLogged in to OpenShift as: \n" >> $FILE
oc whoami | tee -a $FILE
printf "\n\nStatus (verbose): \n" >> $FILE
oc status -v | tee -a $FILE
printf "\n\nProjects:\n" >> $FILE
oc projects | tee -a $FILE
printf "\n==End of miscellaneous section==\n\n" >> $FILE

# Versions
printf "\n\n==Version info==\n\n" >> $FILE
printf "\noc version\n" >> $FILE
oc version | tee -a $FILE
printf "\ndocker --version\n" >> $FILE
docker --version | tee -a $FILE
printf "\netcd --version\n" >> $FILE
etcdctl --version | tee -a $FILE
printf "\nansible --version\n" >> $FILE
ansible --version  | tee -a $FILE

# etcd
printf "\n\n==etcd==\n" >> $FILE
printf "\netcdctl cluster-health:\n" >> $FILE
etcdctl cluster-health | tee -a $FILE
printf "\n==End of etcd section==\n" >> $FILE

# Storage
printf "\n\n==Storage==\n" >> $FILE
printf "\noc get pv:" >> $FILE
oc get pv -n default | tee -a $FILE

if grepMatch="$(oc get pvc $NS | grep 'No resources found.')" ; then
  printf "\nNo PVCs for $NS\n" >> $FILE
else
  printf "\noc get pvc $NS" >> $FILE
  oc get pvc $NS | tee -a $FILE
  printf "\noc describe pvc $NS\n" >> $FILE
  oc get pvc | grep -v 'NAME' | awk '{print $1}' | while read data; do oc describe pvc $data ; done | tee -a $FILE
fi
printf "\n==End of storage section==" >> $FILE

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
  printf "\nGetting network policies for $NS: \n" >> $FILE
  oc get networkpolicy $NS | tee -a $FILE
  printf "\nDescribing network policies for $NS: \n" >> $FILE
  oc describe networkpolicy $NS | tee -a $FILE
  printf "\nGetting network policies for -n default: \n" >> $FILE
  oc get networkpolicy -n default | tee -a $FILE
  printf "\nDescribing network policies for -n default: \n" >> $FILE
  oc describe networkpolicy -n default | tee -a $FILE
  printf "\n==End of networkpolicy plugin section==\n" >> $FILE
else
  printf "\n==No networkpolicy plugin detected==\n" >> $FILE
fi

printf "\n==End of network section==\n\n" >> $FILE

# Deployment pods in error
if grepMatch="$(oc get pods | grep deploy | grep Error | awk '{print $1}')" ; then
  printf "\n==Deployment pods in error:==\n" >> $FILE
  printf "\n\noc get pods:\n" >> $FILE
  oc get pods | grep deploy | grep Error | awk '{print $1}' | while read data; do oc get pods $data -o yaml ; done | tee -a $FILE
  printf "\n\noc describe pods:\n" >> $FILE
  oc get pods | grep deploy | grep Error | awk '{print $1}' | while read data; do oc describe pods $data ; done | tee -a $FILE
  printf "\n\noc describe rc:\n" >> $FILE
  oc get pods | grep deploy | grep Error | awk '{print $1}' | echo ${1:0:${#1}-7} | while read data; do oc describe rc $data ; done | tee -a $FILE
  printf "\n\noc logs:\n" >> $FILE
  oc get pods | grep deploy | grep Error | awk '{print $1}' | while read data; do oc logs $data ; done | tee -a $FILE
  printf "\n\noc describe dc:\n" >> $FILE
  oc get pods | grep deploy | grep Error | awk '{print $1}' | cut -d'-' -f1 | while read data; do oc describe dc $data ; done | tee -a $FILE
else
  printf "\n==No deployment pods in error detected==\n" >> $FILE
fi
printf "\n==End of deployment pods section==\n\n" >> $FILE

# Events
printf "\n\n==Events==\n" >> $FILE
printf "\noc get events $NS:\n" >> $FILE
oc get events $NS | tee -a $FILE
printf "\noc get events -n default:\n" >> $FILE
oc get events -n default | tee -a $FILE
printf "\n==End of events section==\n\n" >> $FILE

printf "\n\n==EOF==\n\n" >> $FILE
