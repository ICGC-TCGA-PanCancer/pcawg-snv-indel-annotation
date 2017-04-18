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
  # - class: InitialWorkDirRequirement
  #   listing:
  #     - entry: $(inputs.tumourBam)
  #       writable: true
  #     - entry: $(inputs.tumourBamIndex)
  #       writable: true
  #     - entry: $(inputs.vcf)
  #       writable: true
  #     - entry: $(inputs.vcfIndex)
  #       writable: true


inputs:
    - id: inputFileDirectory
      type: Directory
      inputBinding:
          position: 0
    - id: tumourID
      type: string
      inputBinding:
        position: 1
    - id: tumourBamFilename
      type: string
      inputBinding:
        position: 2
    - id: tumourBamIndexFilename
      type: string
      inputBinding:
        position: 3
    - id: oxoQScore
      type: string
      inputBinding:
        position: 4
    - id: vcfName
      type: string
      inputBinding:
        position: 5
    - id: vcfIndexName
      type: string
      inputBinding:
        position: 6
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
    pipetteJobs:
      type: Directory?
      outputBinding:
          glob: "pipette_jobs/"

baseCommand: [gosu, root, python3, /cga/fh/pcawg_pipeline/run_oxog_tool.py ]
