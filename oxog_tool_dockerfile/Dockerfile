FROM broadinstitute/pcawg_public
LABEL maintainer "Solomon Shorser (solomon.shorser@oicr.on.ca)"
# Add our modified python script.
# Based on: https://github.com/broadinstitute/pcawg_public/blob/master/taskdef.pcawg_oxog.wdl#L24https://github.com/broadinstitute/pcawg_public/blob/master/taskdef.pcawg_oxog.wdl#L24
# (link valid as of 2017-04-21)
COPY run_oxog_tool.py /cga/fh/pcawg_pipeline/run_oxog_tool.py
# The Matlab cache directory needs to be writable so put it it in /tmp
ENV MCR_CACHE_ROOT /tmp/
VOLUME ["/opt/", "/root/.python-eggs"]
