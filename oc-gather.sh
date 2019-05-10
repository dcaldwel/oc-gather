#!/bin/bash

##############################################################################
# oc-gather.sh                                                               #
# Utility to collect log and oc command output for troubleshooting OpenShift #
# https://github.com/dcaldwel/oc-gather                                      #
##############################################################################

# Add or remove a test function to or from FLAGS here to enable or disable the test.
# Test functions are defined in './oc-gather-lib.sh.'
# New functions should be prefixed with 'gather_' to distinguish then from shell commands and binaries.
 FLAGS="gather_misc gather_nodes gather_etcd gather_storage gather_network gather_pod_errors gather_deployment_errors gather_events gather_docker gather_certs"
#FLAGS="gather_network"

# Load test functions library
source ./oc-gather-lib.sh

# Get commandline arguments and place into $FILE, $NS and $MOD.
# $FILE - local filename to output to.
# $NS - OpenShift namespace context in which to run the commands.
# $MOD - A test module to run (default is to run all test modules).

parseArgs "$@"

# Start of redirected commands into log file $FILE
{

# Validate commandline arguments
gather_validate_options

# Always execute boilerplate and version.
gather_boilerplate
gather_version

# Execute enabled tests
for ENABLED_FUNCTION in $MOD ; do
  $ENABLED_FUNCTION
done

printf "\nEOF\n\n"

} | tee $FILE
