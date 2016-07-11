# OxoG-Dockstore-Tools

[![Docker Repository on Quay](https://quay.io/repository/pancancer/pcawg-oxog-tools/status "Docker Repository on Quay")](https://quay.io/repository/pancancer/pcawg-oxog-tools)

A set of CWL tools that are based on scripts used in the OxoGWrapperWorkflow.

Tools contained within:
 - check_minibams.sh - Checks that minibams are OK
 - clean_vcf.sh - Cleans VCFS so that they are ready to be processed by the OxoGWrapperWorkflow
 - normalize.sh - Normalizes INDEL files by calling bcf-tools norm.
 - pass_filter.sh - Performs pass-filtering on VCFs.
 - vcf_merge_by_type.pl - Merges VCFs.
