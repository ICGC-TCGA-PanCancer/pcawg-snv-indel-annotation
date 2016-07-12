#! /bin/bash

PATH_TO_INDEL=$1
OUTPUT_FILE=${PATH_TO_INDEL/.vcf.gz/}.extracted-SNVs.vcf
OUTPUT_FILE="/var/spool/cwl/$(basename $OUTPUT_FILE)"

echo "OUTPUT_FILE is $OUTPUT_FILE.gz"

touch "$OUTPUT_FILE.gz"

bgzip -d -c $PATH_TO_INDEL > /tmp/indel.vcf \
	&& grep -e '^#' -i -e '^[^#].*[[:space:]][ACTG][[:space:]][ACTG][[:space:]]' /tmp/indel.vcf > $OUTPUT_FILE \
	&& bgzip -f $OUTPUT_FILE \
	&& tabix -f -p vcf $OUTPUT_FILE.gz
