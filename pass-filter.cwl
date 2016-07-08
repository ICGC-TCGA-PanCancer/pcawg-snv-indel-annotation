#!/usr/bin/env cwl-runner
cwlVersion: cwl:draft-3
class: CommandLineTool
id: "pass-filter"
label: "pass-filter"

description: |
    This tool will pass-filter a VCF.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: pancancer/oxog-tools:1.0.0

inputs:
    - id: "#vcf-dir"
      type: Directory
      inputBinding:
        position: 1

outputs:
    - id: "#pass-filtered-filnames"
      type: File
      outputBinding:
        glob: pass-filtered-vcfs.txt

baseCommand: /opt/oxog_scripts/pass_filter.sh
