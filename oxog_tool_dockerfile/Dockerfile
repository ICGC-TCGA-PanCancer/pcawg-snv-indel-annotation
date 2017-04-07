FROM broadinstitute/pcawg_public
# The original Broad OxoG container requires root, but CWL Tool runs as user 1001, so we need to use gosu to get around that.
ENV GOSU_VERSION 1.9
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
    && dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
    && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
    && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu \
    && gosu nobody true

# if you want to clean up after    && apt-get purge -y --auto-remove ca-certificates wget

COPY run_oxog_tool.py /cga/fh/pcawg_pipeline/run_oxog_tool.py

VOLUME /cga/fh/pcawg_pipeline/jobResults_pipette/
VOLUME /opt

# warning: this gives all future users, unknown and known the ability to gosu
RUN chown root:users /usr/local/bin/gosu && chmod +s /usr/local/bin/gosu
