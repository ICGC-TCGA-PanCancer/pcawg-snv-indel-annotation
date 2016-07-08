#! /bin/bash

PATH_TO_INDEL=$1
PATH_TO_OUTPUT=$2

bgzip -d -c $PATH_TO_INDEL > ${PATH_TO_INDEL}_somatic.indel.bcftools-norm.vcf \
	&& grep -e '^#' -i -e '^[^#].*[[:space:]][ACTG][[:space:]][ACTG][[:space:]]' ${PATH_TO_INDEL}_somatic.indel.bcftools-norm.vcf > $PATH_TO_OUTPUT \
	&& bgzip -f $PATH_TO_OUTPUT \
	&& tabix -f -p vcf $PATH_TO_OUTPUT.gz
