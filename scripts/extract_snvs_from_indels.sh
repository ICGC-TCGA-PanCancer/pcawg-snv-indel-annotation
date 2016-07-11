#! /bin/bash

PATH_TO_INDEL=$1

bgzip -d -c $PATH_TO_INDEL > ${PATH_TO_INDEL}_somatic.indel.bcftools-norm.vcf \
	&& grep -e '^#' -i -e '^[^#].*[[:space:]][ACTG][[:space:]][ACTG][[:space:]]' ${PATH_TO_INDEL}_somatic.indel.bcftools-norm.vcf > ${PATH_TO_INDEL}_somatic.extracted-SNVs.vcf \
	&& bgzip -f ${PATH_TO_INDEL}_somatic.extracted-SNVs.vcf \
	&& tabix -f -p vcf ${PATH_TO_INDEL}_somatic.extracted-SNVs.vcf.gz
