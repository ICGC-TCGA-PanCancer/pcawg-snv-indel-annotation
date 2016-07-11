#!/usr/bin/env cwl-runner
cwlVersion: cwl:draft-3
class: CommandLineTool
id: "merge_vcfs"
label: "merge_vcfs"

description: |
    This tool will merge VCFs by type (SV, SNV, INDEL). This CWL wrapper was written by Solomon Shorser.
    The Perl script was originall written by Brian O'Connor and maintained by Solomon Shorser.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/pancancer/pcawg-oxog-tools:1.0.0

inputs:
    - id: "#broad_snv"
      type: File
      inputBinding:
        position: 1
        prefix: --broad_snv

    - id: "#sanger_snv"
      type: File
      inputBinding:
        position: 2
        prefix: --sanger_snv

    - id: "#de_snv"
      type: File
      inputBinding:
        position: 3
        prefix: --de_snv

    - id: "#muse_snv"
      type: File
      inputBinding:
        position: 4
        prefix: --muse_snv

    - id: "#broad_sv"
      type: File
      inputBinding:
        position: 5
        prefix: --broad_sv

    - id: "#sanger_sv"
      type: File
      inputBinding:
        position: 6
        prefix: --sanger_sv

    - id: "#de_sv"
      type: File
      inputBinding:
        position: 7
        prefix: --de_sv

    - id: "#broad_indel"
      type: File
      inputBinding:
        position: 8
        prefix: --broad_indel

    - id: "#sanger_indel"
      type: File
      inputBinding:
        position: 9
        prefix: --sanger_indel

    - id: "#de_indel"
      type: File
      inputBinding:
        position: 10
        prefix: --de_indel

    - id: "#smufin_indel"
      type: File
      inputBinding:
        position: 11
        prefix: --smufin_indel

    - id: "#in_dir"
      type: Directory
        position: 12
        prefix: --indir

    - id: "#out_dir"
      type: Directory
        position: 13
        prefix: --outdir

outputs:
    outdir:
      type: Directory
      outputBinding:
          glob: *.clean.sorted.vcf.gz

baseCommand: /opt/oxog_scripts/vcf_merge_by_type.pl
