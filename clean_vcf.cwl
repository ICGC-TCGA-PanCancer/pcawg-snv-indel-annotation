#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
id: "clean-vcf"
label: "clean-vcf"

doc: |
    This tool will clean a VCF for use in the OxoG workflow.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/pancancer/pcawg-oxog-tools

inputs:
    - id: "#vcf"
      type: File
      inputBinding:
        position: 1

outputs:
    clean_vcf:
      type: File
      outputBinding:
        glob: "*.cleaned.vcf"

baseCommand: /opt/oxog_scripts/clean_vcf.sh
