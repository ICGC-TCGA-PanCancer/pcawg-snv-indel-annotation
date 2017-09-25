#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool
id: "pass-filter"
label: "pass-filter"

doc: |
    This tool will pass-filter a VCF.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull: quay.io/pancancer/pcawg-oxog-tools
  - class: InlineJavascriptRequirement

inputs:
    - id: "#vcfdir"
      type: Directory
      doc: "The directory containing the files"
    - id: "#filesToFilter"
      type: string[]
      doc: "The names of the files that will actually be filtered"

outputs:
    output:
      type:
        type: array
        items: File
      outputBinding:
        glob: "*.pass-filtered.vcf.gz"

arguments: ["$(inputs.vcfdir.path)", "$(inputs.filesToFilter)"]
baseCommand: /opt/oxog_scripts/pass_filter.sh
