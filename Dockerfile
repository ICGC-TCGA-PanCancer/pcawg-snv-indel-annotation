FROM ubuntu:14.04
MAINTAINER solomon.shorser@oicr.on.ca
RUN apt-get update

RUN apt-get install -y git tabix gcc make zlib1g-dev

RUN mkdir -p /opt/gitroot

# Install bcftools - this is used for normalizing VCFs

RUN cd /opt/gitroot && git clone https://github.com/samtools/htslib.git \
	&& cd htslib \
	&& git checkout 1.3.1 \
	&& make

RUN cd /opt/gitroot && git clone https://github.com/samtools/bcftools.git \
	&& cd bcftools \
	&& git checkout 1.3.1 \
	&& make

# Instal VCFTools - this is used for vcf-sort in the vcf_merge_by_type.pl script
RUN apt-get install pkg-config dh-autoreconf -y
RUN cd /opt/gitroot && git clone https://github.com/vcftools/vcftools.git \
	&& cd vcftools \
	&& git checkout v0.1.14 \
	&& ./autogen.sh && ./configure && make && make install

# Copy in the scripts.
RUN mkdir -p /opt/oxog_scripts
COPY ./scripts/* /opt/oxog_scripts/
RUN chmod a+x /opt/oxog_scripts/*.*
