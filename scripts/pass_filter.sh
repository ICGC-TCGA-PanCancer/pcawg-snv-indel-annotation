#! /bin/bash

VCF_DIR=$1
RESULTS_FILE_NAME=$VCF_DIR/pass-filtered-vcfs.txt
PASS_FILTERED_FILES=""
for f in $(ls $VCF_DIR/*.vcf.gz | grep -v pass-filtered | tr '\n' ' ' ) ; do
    echo "processing $f"
	PASS_FILTERED_FILE_NAME=${f/.vcf.gz/}.pass-filtered.vcf
    bgzip -d -c $f | grep -Po "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > $PASS_FILTERED_FILE_NAME
    bgzip -f ${f/.vcf.gz/}.pass-filtered.vcf
	$PASS_FILTERED_FILES="$PASS_FILTERED_FILES\n$PASS_FILTERED_FILE_NAME"
    #bgzip -d -c $f | grep -Pv "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > ${f/.vcf.gz/}.non-pass-filtered.vcf
    #bgzip -f ${f/.vcf.gz/}.non-pass-filtered.vcf
done
cat $PASS_FITLERED_FILES > $RESULTS_FILE_NAME
# FILE_NAME=$1
#
# bgzip -d -c $FILE_NAME | grep -Po "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > ${FILE_NAME/.vcf.gz/}.pass-filtered.vcf
# bgzip -f ${FILE_NAME/.vcf.gz/}.pass-filtered.vcf
