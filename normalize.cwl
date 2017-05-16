#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
id: "normalize"
label: "normalize"

doc: |
    This tool will normalize an INDEL VCF using bcf-tools norm.

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
    - id: "#ref"
      type: File
      inputBinding:
        position: 2
      secondaryFiles:
        - .fai


outputs:
    - id: "#normalized-vcf"
      type: File
      outputBinding:
        glob: "*.normalized.vcf.gz"

baseCommand: /opt/oxog_scripts/normalize.sh
