# oc-gather

## Summary
A small collection of two bash scripts to automate the gathering of frequently collected logs and ``oc`` commands used for troubleshooting OpenShift 3.11 and earlier.

``oc-gather.sh`` is the main control file. It executes each test function based upon simple logic. The test functions are stored in ``oc-gather-lib.sh``. 

**Note:**

- *You will need to be already logged into your OpenShift cluster before running this script.*
- *Certain commands, like the Docker commands, for example, will only work or be relevant when ``oc-gather`` is executed within the cluster -- preferably a master.*

## Specification
### Usage
``oc-gather -f <output file> [-n <namespace>] [-m <test module(s) to run>]``

#### Examples
To execute all tests: ``$ ./oc-gather.sh -f output.log``. Because no namespace is specified, the ``default`` namespace will be used for some tests and some tests will be skipped.

To execute all tests within the ``myproject`` namespace: ``$ oc-gather.sh -f output.log -n myproject``.

To execute only the ``gather_version`` module within ``myproject`` namespace: ``$ oc-gather.sh -f output.log -n myproject -m gather_version``.

To execute only the tests ``gather_version`` and ``gather_network`` within the namespace ``myproject``: ``$ oc-gather.sh -f output.log -n myproject -m "gather_version gather_network"``.

To ensure that certain privileged OS functions succeed, use ``sudo``: ``$ sudo oc-gather.sh -f output.log -n myproject -m "gather_version gather_network"``.

### General Functionality
*oc-gather* gathers logs and ``oc`` command output for the currently logged-in OpenShift cluster. It will write to the output file specified by ``-f``. If an optional namespace is supplied, that namespace will be the focus for most of the ``oc`` commands, otherwise, the ``--all-namespaces`` option will be used in place of ``-n <namespace>``.

If you wish to run one or more *specific* test modules, they can be specified using ``-m``. If ``-m`` is not passed on the commandline, then all test function modules that are present in the ``FLAGS`` variable (found in ``oc-gather.sh``) will be executed. The test function names for use with ``-m`` can be chosen from those listed in the ``FLAGS=`` directive in ``oc-gather.sh``. If you wish to specify more than one test function, surround them all in double quotes, separated with a space (see the examples, above).

If this script is *not* executed as a privileged user then certain commands -- such as ``docker ps`` -- for example, will fail. All ``oc`` commands will function regardless, provided the logged-in OpenShift user is has sufficient privileges.
