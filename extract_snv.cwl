#!/usr/bin/env cwl-runner
cwlVersion: cwl:draft-3
class: CommandLineTool
id: "extract_snvs"
label: "extract_snvs"

description: |
    This tool will extract SNVs from INDEL VCFs

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: pancancer/oxog-tools:1.0.0

inputs:
    - id: "#vcf"
      type: File
      inputBinding:
        position: 1

outputs:
    - id: "#extracted-snvs"
      type: File
      outputBinding:
        glob: extracted_snvs.vcf.gz

baseCommand: /opt/oxog_scripts/extract_snvs_from_indels.sh
