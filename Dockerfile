FROM ubuntu:16.04
LABEL MAINTAINER solomon.shorser@oicr.on.ca
RUN mkdir -p /opt/gitroot

RUN apt-get update && apt-get -y install apt-utils \
	pkg-config git tabix bash gcc make zlib1g-dev \
	libstring-random-perl dh-autoreconf samtools
RUN apt-get autoremove

# Install bcftools - this is used for normalizing VCFs
RUN cd /opt/gitroot && git clone https://github.com/samtools/htslib.git
RUN cd /opt/gitroot && git clone https://github.com/samtools/bcftools.git
RUN cd /opt/gitroot && git clone https://github.com/vcftools/vcftools.git

RUN cd /opt/gitroot/htslib \
	&& git checkout 1.3.1 \
	&& make && make install

RUN cd /opt/gitroot/bcftools \
	&& git checkout 1.3.1 \
	&& make && make install

# Instal VCFTools - this is used for vcf-sort in the vcf_merge_by_type.pl script
RUN cd /opt/gitroot/vcftools \
	&& git checkout v0.1.14 \
	&& ./autogen.sh && ./configure && make && make install

# Copy in the scripts.
RUN mkdir -p /opt/oxog_scripts
COPY ./scripts/* /opt/oxog_scripts/
RUN chmod a+x /opt/oxog_scripts/*.*
