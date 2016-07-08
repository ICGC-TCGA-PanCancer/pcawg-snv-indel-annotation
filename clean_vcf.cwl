#!/usr/bin/env cwl-runner
cwlVersion: cwl:draft-3
class: CommandLineTool
id: "clean-vcf"
label: "clean-vcf"

description: |
    This tool will clean a VCF for use in the OxoG workflow.

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
    - id: "#clean-vcf"
      type: File
      outputBinding:
        glob: *.cleaned.vcf

baseCommand: /opt/oxog_scripts/clean_vcf.sh
