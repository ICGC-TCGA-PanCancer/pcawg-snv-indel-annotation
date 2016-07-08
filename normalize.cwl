#!/usr/bin/env cwl-runner
cwlVersion: cwl:draft-3
class: CommandLineTool
id: "normalize"
label: "normalize"

description: |
    This tool will normalize an INDEL VCF using bcf-tools norm.

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
    - id: "#ref"
      type: File
      inputBinding:
        position: 2

outputs:
    - id: "#pass-filtered-filnames"
      type: File
      outputBinding:
        glob: *.normalized.vcf.gz

baseCommand: /opt/oxog_scripts/normalize.sh
