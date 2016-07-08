#! /bin/bash

INPUT_FILE=$1
REF_FILE=$2
OUTPUT_FILE=${$INPUT_FILE/.vcf.gz/}.normalized.vcf.gz

bcftools norm -c w -m -any -Oz -f $REF_FILE $INPUT_FILE > $OUTPUT_FILE
bgzip -f $OUTPUT_FILE
tabix -f -p vcf $OUTPUT_FILE
