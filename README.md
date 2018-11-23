# oc-gather

## Summary
A script to automate gathering logs and various 'oc' outputs for troubleshooting OpenShift.

## Specification
### Usage
``oc-gather -f <output file> [-n <namespace>]``
  
### General Functionality
*oc-gather* should gather logs and *oc* output from a set of default namespaces. It will write to the output file specified. If an optional namespace is supplied, info from that namespace will be gathered, otherwise, the ``--all-namespaces`` option will be used.

