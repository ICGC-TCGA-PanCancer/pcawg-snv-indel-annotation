#!/usr/bin/env cwl-runner

#run as dockstore --debug tool launch --descriptor cwl --local-entry --entry ./oxog.cwl --json oxog_tool_input.json
cwlVersion: v1.0
class: CommandLineTool

description: |
    This tool will run OxoG. The OxoG tool was written by Dimitri Livitz. This CWL wrapper was written by Solomon Shorser.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull:  pcawg/oxog_tool
  - class: InlineJavascriptRequirement

inputs:
    - id: tumourID
      type: string
      inputBinding:
        position: 1
    - id: tumourBam
      type: File
      inputBinding:
        position: 2
    - id: tumourBamIndex
      type: File
      inputBinding:
        position: 3
    - id: oxoQScore
      type: string
      inputBinding:
        position: 4
    - id: vcf
      type: File
      inputBinding:
        position: 5
    - id: vcfIndex
      type: File
      inputBinding:
        position: 5
    - id: refDataDir
      type: Directory
      inputBinding:
          position: 7


outputs:
    oxogTarFile:
      type: File?
      outputBinding:
#          glob: "failing_intermediates.tar"
          glob: "*.gnos_files.tar"
    debuggingOutput:
      type: File
      outputBinding:
          glob: "failing_intermediates.tar"

baseCommand: [gosu, root, python3, /cga/fh/pcawg_pipeline/run_oxog_tool.py ]
