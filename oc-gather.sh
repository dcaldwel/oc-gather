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


##############
# Gather info#
##############

# Start of redirected commands
{

# Boilerplate
printf "==Started==\n"
date
printf "\nOptions used: output file = $FILE, namespace string = \'$NS\'"

# Miscellaneous oc commands
printf "\n\n==Miscellaneous oc commands==\n"
printf "\nLogged in to OpenShift as: \n"
oc whoami
printf "\n\nStatus (verbose): \n"
oc status -v
printf "\n\nProjects:\n"
oc projects
printf "\n==End of miscellaneous section==\n\n"

# Versions
printf "\n\n==Version info==\n\n"
oc version
printf "\n"
docker --version
printf "\n"
etcdctl --version
printf "\n"
ansible --version 

# Nodes
printf "\n\n==Nodes==\n"
printf "\noc get nodes\n"
oc get nodes
printf "\n==End of nodes section==\n\n"

# etcd
printf "\n\n==etcd==\n"
printf "\netcdctl cluster-health:\n"
etcdctl cluster-health
printf "\n==End of etcd section==\n"

# Storage
printf "\n\n==Storage==\n"
printf "\nLocal storage:\n"
df
printf "\noc get pv:\n"
oc get pv -n default

if grepMatch="$(oc get pvc $NS | grep 'No resources found.')" ; then
  printf "\nNo PVCs for $NS\n"
else
  printf "\noc get pvc $NS:\n"
  oc get pvc $NS
  printf "\noc describe pvc $NS\n"
  oc get pvc | grep -v 'NAME' | awk '{print $1}' | while read data; do oc describe pvc $data ; done
fi
printf "\n==End of storage section=="

# Network
printf "\n\n==Network==\n"
printf "\nhostsubnet: \n"
oc get hostsubnet
printf "\nclusternetwork: \n"
oc get clusternetwork

# If networkpolicy plugin detected, get policies info
if grepMatch="$(oc get clusternetwork | grep 'networkpolicy')" ; then
  printf "\n\n==Detected networkpolicy plugin==\n"
  printf "\nnetnamespace: \n"
  oc get netnamespace
  printf "\nGetting network policies for $NS: \n"
  oc get networkpolicy $NS
  printf "\nDescribing network policies for $NS: \n"
  oc describe networkpolicy $NS
  
  # Skip if using --all-namespaces
  if NS="--all-namespaces" ; then
    printf "\n[Skipping as namespace = --all-namespaces]\n"
  else
    printf "\nGetting network policies for -n default: \n"
    oc get networkpolicy -n default
    printf "\nDescribing network policies for -n default: \n"
    oc describe networkpolicy -n default
  fi
  
  printf "\n==End of networkpolicy plugin section==\n"

else

    printf "\n==No networkpolicy plugin detected==\n"
fi

printf "\n==End of network section==\n\n"


# Deployment pods in error
if grepMatch="$(oc get pods $NS | grep deploy | grep Error | awk '{print $1}')" ; then
  printf "\n==Deployment pods in error==\n"
  printf "\n\noc get pods $NS:\n"
  oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | while read data; do oc get pods $NS $data -o yaml ; done

  # Skips some oc commands if $NS = "--all-namespaces"
  if NS="--all-namespaces" ; then
    printf "\n[Skipping as namespace = --all-namespaces]\n"
  else
    printf "\n\noc describe pods $NS:\n"
    oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | while read data; do oc describe pods $NS $data ; done
    # describe the rc using the awk output and removing the last seven characters ('-deploy') using ${1:0:${#1}-7}:
    printf "\n\noc describe rc $NS:\n"
    oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | echo ${1:0:${#1}-7} | while read data; do oc describe rc $NS $data ; done
    printf "\n\noc logs $NS:\n"
    oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | while read data; do oc logs $NS $data ; done
    # describe some deployment configs - need to cut the awk output at the first '-'
    printf "\n\noc describe dc $NS:\n"
    oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | cut -d'-' -f1 | while read data; do oc describe dc $NS $data ; done
  fi
else
  printf "\n==No deployment pods in error detected==\n"
fi
printf "\n==End of deployment pods section==\n\n"

# Events
printf "\n\n==Events==\n"
printf "\noc get events $NS:\n"
oc get events $NS
printf "\noc get events -n default:\n"
oc get events -n default
printf "\n==End of events section==\n\n"

# docker
printf "\n\n==Docker==\n"
printf "\ndocker ps -a (this will fail if user is not privileged):\n"
docker ps -a
printf "\n\n==End of Docker section==\n"

printf "\n\n==Finished==\n"
date

# End of redirected output
} | tee $FILE


