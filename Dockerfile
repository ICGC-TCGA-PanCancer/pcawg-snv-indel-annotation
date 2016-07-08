FROM ubuntu:14.04
MAINTAINER solomon.shorser@oicr.on.ca
RUN apt-get update

RUN apt-get install -y git tabix gcc make zlib1g-dev

RUN mkdir -p /opt/gitroot

RUN cd /opt/gitroot && git clone https://github.com/samtools/htslib.git \
	&& cd htslib \
	&& git checkout 1.3.1 \
	&& make

RUN cd /opt/gitroot && git clone https://github.com/samtools/bcftools.git \
	&& cd bcftools \
	&& git checkout 1.3.1 \
	&& make

# Copy in the scripts.
RUN mkdir -p /opt/oxog_scripts
COPY ./scripts/* /opt/oxog_scripts/
RUN chmod a+x /opt/oxog_scripts/*.*
