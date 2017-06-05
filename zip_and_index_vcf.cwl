#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow
doc: |
    This is a very simple workflow of two steps. It will zip an input VCF file and then index it. The zipped file and the index file will be in the workflow output.

requirements:
    - class: InlineJavascriptRequirement

inputs:
    vcf:
        type: File
outputs:
    indexed_file:
        outputSource: index_step/indexed_file
        type: File
    zipped_file:
        outputSource: zip_step/zipped_file
        type: File
steps:
    zip_step:
        in:
            vcf_to_zip: vcf
        out: [zipped_file]
        run:
            class: CommandLineTool
            requirements:
              - class: DockerRequirement
                dockerPull: quay.io/pancancer/pcawg-oxog-tools
            inputs:
                vcf_to_zip:
                    type: File
                    inputBinding:
                        position: 0
                        prefix: "-c"
            stdout:  $( inputs.vcf_to_zip.basename + ".gz")
            outputs:
                zipped_file:
                    type: File
                    outputBinding:
                        glob: "*.gz"
            baseCommand: "bgzip"

    index_step:
        in:
            zipped_file: zip_step/zipped_file
        out: [indexed_file]
        run:
            class: CommandLineTool
            requirements:
              - class: DockerRequirement
                dockerPull: quay.io/pancancer/pcawg-oxog-tools
              - class: InitialWorkDirRequirement
                listing:
                    - $(inputs.zipped_file)
            inputs:
                zipped_file:
                    type: File
            arguments: [$(runtime.outdir + "/" + inputs.zipped_file.basename)]
            outputs:
                indexed_file:
                    type: File
                    outputBinding:
                        glob: "*.tbi"
            baseCommand: [tabix, -f, -p, vcf]
