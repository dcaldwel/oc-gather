#!/bin/bash


# Borrowed this short parseArgs() function from 
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
# This function reads the commandline options and populates variables with their value for 
# use in the test functions.
# 
# Options can be in any order and can be added to by adding cases below. Don't forget to 
# use the 'shift' command after a true case (apart from the last case).

parseArgs() {
while [[ $# > 0 ]] ; do
  case "$1" in
    -f)
      FILE=${2}
      shift
      ;;
    -n)
      NS=${2}
      shift
      ;;
    -m)
      MOD=${2}
      ;;
  esac
  shift
done
}
####


####
#Test functions
####

function gather_validate_options() {
# Validate commandline options. Check for file (-f) and namespace (-n)
printf "\n[Pre-flight checks]\n"
  # Exit if $FILE is blank
  if [[ ! $FILE = *[!\ ]* ]]
    then
      printf "\nNo output file supplied.\nUsage: oc-gather -f <output file> [-n <namespace>]\n"
      exit 1
  fi

# Exit if $FILE is set to '-'
  if [[ ! $FILE = *[!\-]* ]]
    then
      printf "\nNo output file supplied.\nUsage: oc-gather -f <output file> [-n <namespace>]\n"
      exit 1
  fi

# Exit if $FILE exists
  if test -e $FILE
      then
        printf "\nOutput file $FILE already exists. Please move/rename/delete existing output file and retry.\n\n"
        exit 1
  fi

# Create the file specified by $FILE
# but exit if touch returns an error value (non-zero)
  if touch $FILE ; then
    printf "\n$FILE created\n"
  else
    printf "\nError creating file. Please check that any relevant directories exist.\n\n"
    exit 1
  fi


# If $NS is blank, set it to '--all-namespaces'
  if [[ ! $NS = *[!\ ]* ]] ; then
    printf "\n\'-n\' not passed on commandline"
    NS="--all-namespaces"
    # Prepend '-n ' to given namespace for ease later
  else
    NS="-n $NS"
  fi
  
  printf "\n\$NS set to \'$NS\'\n"

# If $MOD is empty, set $MOD to $FLAGS
  if [[ ! $MOD = *[!\ ]* ]] ; then
    printf "\nSetting MOD to FLAGS\n"
    MOD="$FLAGS"
  fi
printf "\n[End of pre-flight]\n\n"
}

function gather_boilerplate() {
# Boilerplate
  printf "\n\n==Started gather==\n"
  date
  printf "\nOptions used: output file = $FILE, namespace string = \'$NS\'"
  printf "\nFunction flags: \'$MOD\'"
}

function gather_misc() {
# Miscellaneous oc commands
  printf "\n\n==Miscellaneous oc commands==\n"
  printf "\nLogged in to OpenShift as: \n"
  oc whoami
  printf "\n\nStatus (verbose): \n"
  oc status -v
  printf "\n\nProjects:\n"
  oc projects
  printf "\n==End of miscellaneous section==\n\n"
}

function gather_version() {
# Versions
  printf "\n\n==Version info==\n\n"
  oc version
  printf "\n"
  docker --version
  printf "\n"
  etcdctl --version
  printf "\n"
  ansible --version 
  printf "\n==End of version section==\n\n"
}

function gather_nodes() {
  # Nodes
  printf "\n\n==Nodes==\n"
  printf "\noc get nodes\n"
  oc get nodes -o wide
  printf "\n==End of nodes section==\n\n"
}

function gather_etcd() {
# etcd
  printf "\n\n==etcd==\n"
  printf "\netcdctl cluster-health:\n"
  etcdctl cluster-health
  printf "\n==End of etcd section==\n"
}

function gather_storage() {
# Storage
  printf "\n\n==Storage==\n"
  #printf "\nLocal storage:\n"
  #df
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
}

function gather_network() {
# Network
  printf "\n\n==Network==\n"
  printf "\nhostsubnet: \n"
  oc get hostsubnet
  printf "\nclusternetwork: \n"
  oc get clusternetwork
  printf "\nnetnamespace: \n"
  oc get netnamespace

# If networkpolicy plugin detected, get policies info
  if grepMatch="$(oc get clusternetwork | grep 'networkpolicy')" ; then
    printf "\n\n==Detected networkpolicy plugin==\n"
    printf "\nGetting network policies for $NS: \n"
    oc get networkpolicy $NS
    printf "\nDescribing network policies for $NS: \n"
    oc describe networkpolicy $NS 

    if [ "$NS" != "--all-namespaces" ] ; then
        printf "\nGetting network policies for --all-namespaces: \n"
        oc get networkpolicy --all-namespaces
        printf "\nDescribing network policies for --all-namespaces: \n"
        oc describe networkpolicy --all-namespaces
    fi

    printf "\n==End of networkpolicy plugin section==\n"

  else

    printf "\n==No networkpolicy plugin detected==\n"

  fi

  # Get ip route info
  printf "\nip route:\n"
  ip route
  ovs-vsctl list-br
  ovs-ofctl -O OpenFlow13 dump-ports-desc br0

  printf "\n==End of network section==\n\n"
}

function gather_deployment_errors() {
# Deployment pods in error
  if grepMatch="$(oc get pods $NS | grep deploy | grep Error | awk '{print $1}')" ; then
    printf "\n==Deployment pods in error.==\n"
    printf "\n\noc get pods $NS:\n"
    oc get pods $NS | grep deploy | grep Error | awk '{print "-n " $1 " " $2}' | while read data; do oc get pods $data -o yaml ; done

    # Skips some oc commands if $NS = "--all-namespaces"
    if [ "$NS" == "--all-namespaces" ] ; then
      printf "\n[Skipping oc describe pods as namespace = --all-namespaces]\n"
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
}

function gather_pod_errors() {
# Pods in error. Includes deployment pods.

  # If we find the string 'Error' in the oc output, get those pods
  if grepMatch="$(oc get pods $NS | grep Error | awk '{print $1}')" ; then
    printf "\n==Pods in error.==\n"
    printf "\n\noc get pods $NS:\n"
    oc get pods $NS | grep Error | awk '{print "-n " $1 " " $2}' | while read data; do oc get pods $data -o yaml ; done

    # Skips some oc commands if NS = "--all-namespaces"    
    if [ "$NS" == "--all-namespaces" ] ; then
      printf "\n[Skipping oc describe pods as namespace = --all-namespaces]\n"
          
    else
      printf "\n\noc describe pods $NS:\n"
      oc get pods $NS  | grep Error | awk '{print $1}' | while read data; do oc describe pods $NS $data ; done
      # describe the rc using the awk output and removing the last seven characters ('-deploy') using ${1:0:${#1}-7}:
      printf "\n\noc describe rc $NS:\n"
      oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | echo ${1:0:${#1}-7} | while read data; do oc describe rc $NS $data ; done
      printf "\n\noc logs $NS:\n"
      oc get pods $NS | grep Error | awk '{print $1}' | while read data; do oc logs $NS $data ; done
      # describe some deployment configs - need to cut the awk output at the first '-'
      printf "\n\noc describe dc $NS:\n"
      oc get pods $NS | grep deploy | grep Error | awk '{print $1}' | cut -d'-' -f1 | while read data; do oc describe dc $NS $data ; done
    fi
  
  else
    printf "\n==No pods in error detected==\n"
  fi

  printf "\n==End of pods in error section==\n\n"
}

function gather_events() {
# Events
  printf "\n\n==Events==\n"
  printf "\noc get events $NS:\n"
  oc get events $NS
  printf "\noc get events -n default:\n"
  oc get events -n default
  printf "\n==End of events section==\n\n"
}

function gather_docker() {
# docker
  printf "\n\n==Docker==\n"
  printf "\ndocker ps -a (this will fail if user is not privileged):\n"
  docker ps -a
  printf "\n\n==End of Docker section==\n"
}

function gather_sdn_logs() {
# Iterate oc logs over the sdn pods found in the openshift-sdn namespace
  printf "\n\n==SDN Logs==\n"
  printf "\noc logs <sdn pods> -n openshift-sdn:\n"
  oc get pods -n openshift-sdn | awk '{print $1}' | grep sdn | while read data; do oc logs -n openshift-sdn $data ; done
}

function gather_endpoints() {
# Get endpoints
  printf "\n\n==Endpoints==\n"
  printf "\noc get ep $NS\n"
  oc get ep $NS
  # describe the endpoints

  if [ "$NS" == "--all-namespaces" ] ; then
    printf "\n\noc describe ep -n default:\n"
    oc get ep -n default | grep -v 'NAME' | awk '{print $1}' | while read data; do oc describe ep -n default $data ; done
  else
    printf "\n\noc describe ep $NS:\n"
    oc get ep $NS | grep -v 'NAME' | awk '{print $1}' | while read data; do oc describe ep $NS $data ; done
  fi
}

function gather_certs() {
# Check certs
  printf "\n\n==Certificate checks==\n"
  printf "\nLooking for certificate end dates in /etc/origin/master/*.crt:\n\n"
  for i in /etc/origin/master/*.crt ; do echo $i; openssl x509 -noout -text -in $i | grep "Not After" ;done

  printf "\nLooking for certificate validity in *kubeconfig:\n\n"
  for config in $(find /etc/origin/ -name "*kubeconfig"); do echo "Config: $config";  file=$(basename $config); echo "  File: $file"; awk '/cert/ {print $2}' $config | sed "s/$file//" | base64 -d | openssl x509 -text -noout | grep Validity -A2 ; done

  printf "\nLooking to see if certificates have been signed by ca.crt:\n\n"
  for i in /etc/origin/master/*.crt ; do echo $i; openssl verify -CAfile /etc/origin/master/ca.crt $i ;done

  printf "\nLooking for subject and subject alternative names in the OCP certificate:\n\n"
  openssl x509 -in /etc/origin/master/master.server.crt -text -noout | grep -i 'subject:'
  openssl x509 -in /etc/origin/master/master.server.crt -text -noout | grep -A1 -i 'subject alternative'

  printf "\nGathering md5sums of admin.kubeconfig and .kube/config:\n\n"
  grep certificate-authority-data /etc/origin/master/admin.kubeconfig | awk '{ print $2 }' | base64 -d | md5sum
  grep certificate-authority-data /root/.kube/config | awk '{ print $2 }' | base64 -d | md5sum
  printf "\n==End of certificates section==\n"  
}
