#!/bin/bash

##############################################################################
# oc-gather.sh                                                               #
# Utility to collect log and oc command output for troubleshooting OpenShift #
# https://github.com/dcaldwel/oc-gather                                      #
##############################################################################

# Add or remove a test function to or from FLAGS here to enable or disable the test.
# Test functions are defined in './oc-gather-lib.sh.'
# New functions should be prefixed with 'gather_' to distinguish then from shell commands and binaries.
# FLAGS="gather_boilerplate gather_misc gather_version gather_nodes gather_etcd gather_storage gather_network gather_pod_errors gather_deployment_errors gather_events gather_docker"
FLAGS="gather_endpoints"

# Load test functions library
source ./oc-gather-lib.sh

# Get commandline arguments and place into $FILE and $NS
parseArgs "$@"

# Start of redirected commands into log file $FILE
{

# Validate commandline arguments
gather_validate_options

# Execute enabled tests
for ENABLED_FUNCTION in $FLAGS ; do
#  printf "\n+++NS = \'$NS\'+++\n"
  $ENABLED_FUNCTION
done

printf "\n==End of gather==\n\n"

} | tee $FILE
