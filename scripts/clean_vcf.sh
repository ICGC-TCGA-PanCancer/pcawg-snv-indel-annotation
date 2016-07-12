#! /bin/bash

INPUT_FILE=$1
OUTPUT_FILE=${INPUT_FILE/.vcf.gz/}.cleaned.vcf
TAB_CHAR="$(echo -e '\t')"
OUTPUT_FILE="/var/spool/cwl/$(basename $OUTPUT_FILE)"
echo "OUTPUT_FILE is $OUTPUT_FILE"
#The goal is a sed call that looks like this, where the "t" is a tab...
#sed -e 's/t$/t./g' -e 's/tt/t.t/g'  -e 's/\([^t]\)tt\([^t]\)/\1t.t\2/g' -e 's/tt/t.t/g' -e -e 's/^Mt/MTt/g' -e 's/\\(##.*\\);$/\\1/g'
#First, replace a tab at the end of a line with a tab and a dot because the dot was missing.
#Second, replace any two tabs next to each other with tab-dot-tab because the dot was missing in between them.
#Third, replace any two tabs that are still beside each other and are book-ended by non-tabs with
#the original leading/trailing characters and two tabs with a dot in between.
#Fourth, replace any remaining sequential tabs with tab-dot-tab.
#Fifth, replace any leading M with MT
#Sixth, get rid of trailing semi-colons in header lines.
set -x
bgzip -d -c $INPUT_FILE \
	| sed -e s/"${TAB_CHAR}"$/"${TAB_CHAR}"./g \
		-e s/"${TAB_CHAR}""${TAB_CHAR}"/"${TAB_CHAR}"."${TAB_CHAR}"/g \
		-e s/\([^"${TAB_CHAR}"]\)"${TAB_CHAR}""${TAB_CHAR}"\([^"${TAB_CHAR}"]\)/\1"${TAB_CHAR}"."${TAB_CHAR}"\2/g \
		-e s/"$TAB_CHAR""$TAB_CHAR"/"$TAB_CHAR"."$TAB_CHAR"/g \
		-e s/^M\([[:blank:]]\)/MT\1/g \
		-e s/\(##.*\)\;$/\1/g \
	> $OUTPUT_FILE
set +x
