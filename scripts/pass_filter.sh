#! /bin/bash
VCF_DIR=$1
shift
FILES_TO_FILTER=( "$@" )
RESULTS_FILE_NAME=$VCF_DIR/pass-filtered-vcfs.txt
# TODO: Second input to this script needs to be a list of filenames that will be filtered.
echo "Contents of $VCF_DIR"
ls -lht $VCF_DIR
echo "Files to filter include: $FILES_TO_FILTER"
echo "Pass-filtering files in $VCF_DIR"
for n in ${FILES_TO_FILTER[@]} ; do
    echo "File: $n"
    # for f in $(ls $VCF_DIR/$n | grep -v pass-filtered | tr '\n' ' ' ) ; do
        f=$VCF_DIR/$n
        echo "processing $f"
        PASS_FILTERED_FILE_NAME=${f/.vcf.gz/}.pass-filtered.vcf
        PASS_FILTERED_FILE_NAME="/var/spool/cwl/$(basename $PASS_FILTERED_FILE_NAME)"
        bgzip -d -c $f | grep -Po "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > $PASS_FILTERED_FILE_NAME
        bgzip -f $PASS_FILTERED_FILE_NAME
        #bgzip -d -c $f | grep -Pv "^#.*$|([^\t]*\t){6}(PASS\t|\\.\t).*" > ${f/.vcf.gz/}.non-pass-filtered.vcf
        #bgzip -f ${f/.vcf.gz/}.non-pass-filtered.vcf
    # done
done
