#!/usr/bin/env cwl-runner

#run as dockstore --debug tool launch --descriptor cwl --local-entry --entry ./oxog.cwl --json oxog_tool_input.json
cwlVersion: v1.0
class: CommandLineTool

description: |
    This tool will run OxoG. The OxoG tool was written by Dimitri Livitz. This CWL wrapper was written by Solomon Shorser.

# Input file should look like this:
# {
#     "oxoQScore":"10.5",
#     "tumourID":"123456789",
#     "inputFileDirectory" : {
#         "class":"Directory",
#         "path":"/media/sshorser/Data/oxog_test_data",
#         "location":"/media/sshorser/Data/oxog_test_data"
#     },
#     "tumourBamFilename" : "f5c9381090a53c54358feb2ba5b7a3d7.bam",
#     "tumourBamIndexFilename" : "f5c9381090a53c54358feb2ba5b7a3d7.bam.bai",
#     "vcfName" : "f7b84c09-15d4-3046-e040-11ac0c4847ff.svcp_1-0-3.20150120.somatic.snv_mnv.cleaned.vcf.gz",
#     "vcfIndexName" : "f7b84c09-15d4-3046-e040-11ac0c4847ff.svcp_1-0-3.20150120.somatic.snv_mnv.cleaned.vcf.gz.tbi",
#     "refDataDir": {
#         "class":"Directory",
#         "path":"/datastore/oxog_refdata",
#         "location":"/datastore/oxog_refdata"
#     }
# }

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
  - class: DockerRequirement
    dockerPull:  pcawg/oxog_tool
  - class: InlineJavascriptRequirement

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
