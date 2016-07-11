#! /bin/bash

for pipeline in sanger broad dkfz_embl muse smufin; do

	echo "================================================================"
	echo "PIPELINE IS: $pipeline"

	SNV_PATTERN=""
	if [ "$pipeline" == "muse" ] ; then
		SNV_PATTERN="/datastore/vcf/$pipeline/*/*somatic.snv*vcf.gz"
		stat $SNV_PATTERN
		if [ $? == "1" ] ; then
			SNV_PATTERN="/datastore/vcf/$pipeline/*somatic.snv*vcf.gz"
			stat $SNV_PATTERN
			if [ $? == "1" ] ; then
				echo "Could not find file /datastore/vcf/$pipeline/*/*somatic.snv*vcf.gz or /datastore/vcf/$pipeline/*somatic.snv*vcf.gz - cannot proceed!"
				exit 1
			fi
		fi
	elif [ "$pipeline" == "smufin" ] ; then
		SNV_PATTERN="/datastore/vcf/$pipeline/*/*somatic.indel*bcftools-norm*vcf.gz"
		stat $SNV_PATTERN
		if [ $? == "1" ] ; then
			SNV_PATTERN="/datastore/vcf/$pipeline/*somatic.indel*bcftools-norm*vcf.gz"
			stat $SNV_PATTERN
			if [ $? == "1" ] ; then
				echo "Could not find file /datastore/vcf/$pipeline/*/*somatic.indel*bcftools-norm*vcf.gz or /datastore/vcf/$pipeline/*somatic.indel*bcftools-norm*vcf.gz - cannot proceed!"
				exit 1
			fi
		fi
	else
		SNV_PATTERN="/datastore/vcf/$pipeline/*/*somatic.snv*pass-filtered*vcf.gz"
		stat $SNV_PATTERN
		if [ $? == "1" ] ; then
			SNV_PATTERN="/datastore/vcf/$pipeline/*somatic.snv*pass-filtered*vcf.gz"
			stat $SNV_PATTERN
			if [ $? == "1" ] ; then
				echo "Could not find file /datastore/vcf/$pipeline/*/*somatic.snv*pass-filtered*vcf.gz or /datastore/vcf/$pipeline/*somatic.snv*pass-filtered*vcf.gz - cannot proceed!"
				exit 1
			fi
		fi
	fi

	for snv_vcf in $(ls $SNV_PATTERN); do
		echo "----------------------------------------------------------------"
		echo "pipeline snv vcf is: $snv_vcf"
		OUTFILE=$(basename $snv_vcf)
		OUTFILE=${OUTFILE/\.vcf\.gz/.chr22.positions.txt}
		zcat $snv_vcf | grep ^22 | cut -f2 > /datastore/vcf/$OUTFILE

		while read location; do
			echo "for location $location:"
			PATH_TO_NORMAL=$( ( [ -f /datastore/bam/normal/*/*.bam ] && echo /datastore/bam/normal/*/*.bam) || ([ -f /datastore/bam/normal/*.bam ] && echo /datastore/bam/normal/*.bam))
			COUNT_IN_NORMAL=$(samtools view $PATH_TO_NORMAL 22:$location-$location -c)
			echo "count in normal - original bam: $COUNT_IN_NORMAL"

			NORMAL_FILE_BASENAME=$(basename /datastore/bam/normal/*/*.bam)
			COUNT_IN_NORMAL_MINIBAM=$(samtools view /datastore/variantbam_results/${NORMAL_FILE_BASENAME/\.bam/_minibam.bam} 22:$location-$location -c)
			echo "count in normal - minibam: $COUNT_IN_NORMAL_MINIBAM"

			if [ "$COUNT_IN_NORMAL" != "$COUNT_IN_NORMAL_MINIBAM" ] ; then
				echo "MISMATCH! Something may have gone wrong in vcf merge or in variantbam!"
				exit 1;
			fi

			for tumour in $(ls /datastore/bam/tumour/*/*.bam /datastore/bam/tumour/*.bam) ; do
				TUMOUR_FILE_BASENAME=$(basename $tumour)
				COUNT_IN_TUMOUR_1=$(samtools view $tumour 22:$location-$location -c)
				echo "count in tumour ${TUMOUR_FILE_BASENAME}: $COUNT_IN_TUMOUR_1"
				COUNT_IN_TUMOUR_1_MINIBAM=$(samtools view /datastore/variantbam_results/${TUMOUR_FILE_BASENAME/\.bam/_minibam.bam} 22:$location-$location -c)
				echo "count in tumour ${TUMOUR_FILE_BASENAME/\.bam/_minibam.bam}: $COUNT_IN_TUMOUR_1_MINIBAM"
				if [ "$COUNT_IN_TUMOUR_1" != "$COUNT_IN_TUMOUR_1_MINIBAM" ] ; then
					echo "MISMATCH! Something may have gone wrong in vcf merge or in variantbam!"
					exit 1;
				fi
			done
		done </datastore/vcf/$OUTFILE
	done
done
