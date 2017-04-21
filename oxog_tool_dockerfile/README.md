# OxoG filter

A dockerfile based on broadinstitute/pcawg_public (created by Gordon Saksena). This dockerfile has the following changes:

 - It contains a script run_oxog_tool.py that is used to run the OxoG filter inside the container. This script is based on the `python_cmd` found in https://github.com/broadinstitute/pcawg_public/blob/master/taskdef.pcawg_oxog.wdl
 - It contains `gosu`, so that it can run certain programs as root, to get around some cwltool restrictions.
 - It declares the paths `/opt` and `/root/.python-eggs` as docker volumes to make them readable, to get around some cwltool restrictions on read-only filesystems.

[![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-oxog-filter/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-oxog-filter)
