#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
id: "merge_vcfs"
label: "merge_vcfs"

description: |
    This tool will merge VCFs by type (SV, SNV, INDEL). This CWL wrapper was written by Solomon Shorser.
    The Perl script was originaly written by Brian O'Connor and maintained by Solomon Shorser.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: pancancer/pcawg-oxog-tools

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
        prefix: --dkfz_embl_snv

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
        prefix: --dkfz_embl_sv

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
        prefix: --dkfz_embl_indel

    - id: "#smufin_indel"
      type: File
      inputBinding:
        position: 11
        prefix: --smufin_indel

    - id: "#in_dir"
      type: string
      inputBinding:
        position: 12
        prefix: --indir

    - id: "#out_dir"
      type: string
      inputBinding:
        position: 13
        prefix: --outdir
outputs:
    output:
      type:
        type: array
        items: File
      outputBinding:
          glob: "*.clean.sorted.vcf.gz"

baseCommand: /opt/oxog_scripts/vcf_merge_by_type.pl
