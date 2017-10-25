#! /bin/bash
VCF_DIR=$1
shift
FILES_TO_FILTER=( "$@" )
echo "Contents of $VCF_DIR"
ls -lht $VCF_DIR
echo "Files to filter include: $FILES_TO_FILTER"
echo "Pass-filtering files in $VCF_DIR"
for n in ${FILES_TO_FILTER[@]} ; do
    echo "File: $n"
    f=$VCF_DIR/$n
    echo "processing $f"
    PASS_FILTERED_FILE_NAME=${f/.vcf.gz/}.pass-filtered.vcf
    PASS_FILTERED_FILE_NAME="/var/spool/cwl/$(basename $PASS_FILTERED_FILE_NAME)"
    bgzip -d -c $f | grep -Po "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > $PASS_FILTERED_FILE_NAME
    bgzip -f $PASS_FILTERED_FILE_NAME
    #bgzip -d -c $f | grep -Pv "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > ${f/.vcf.gz/}.non-pass-filtered.vcf
    #bgzip -f ${f/.vcf.gz/}.non-pass-filtered.vcf
done
