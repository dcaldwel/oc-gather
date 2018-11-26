# oc-gather.sh

## Summary
A bash script to automate the gathering of frequently collected logs and ``oc`` commands used for troubleshooting OpenShift.

## Specification
### Usage
``oc-gather -f <output file> [-n <namespace>]``
  
### General Functionality
*oc-gather* gathers logs and ``oc`` command output for the currently logged-in OpenShift cluster. It will write to the output file specified by ``-f``. If an optional namespace is supplied, that namespace will be the focus for most of the ``oc`` commands, otherwise, the ``--all-namespaces`` option will be used in place of ``-n <namespace>``.

If this script is *not* executed as a privileged user then certain commands -- such as ``docker ps`` -- for example, will be fail. All ``oc`` commands will function regardless, provided the logged-in OpenShift user is has sufficient privileges.

