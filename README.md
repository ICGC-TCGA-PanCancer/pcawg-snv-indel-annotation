# pcawg-snv-indel-annotation

This repository hosts the PCAWG Annotator as a CWL workflow. This workflow will _only_ run the annotator. For a workflow that runs PCAWG OxoG Filter, PCAWG Annotation, and generates Minibams, see this repository:  https://github.com/ICGC-TCGA-PanCancer/OxoG-Dockstore-Tools

The Anntoator was created by Jonathan Dursi. For more information, see this repo: https://github.com/ljdursi/sga-annotate-docker

The original SeqWare workflow can be found here: https://github.com/ICGC-TCGA-PanCancer/OxoGWrapperWorkflow
The Seqware workflow runs: the OxoG filter, produces mini-bams, and also runs Jonathan Dursi's PCAWG Annotator.

To visualize _this_ workflow, see here: https://view.commonwl.org/workflows/github.com/ICGC-TCGA-PanCancer/pcawg-snv-indel-annotation/blob/develop/pcawg_annotate_wf.cwl

You can run this workflow with the following command:
```
$ cwltool --debug --relax-path-checks --non-strict ./pcawg_annotate_wf.cwl ./my_input_file.json > out 2> err &
```
