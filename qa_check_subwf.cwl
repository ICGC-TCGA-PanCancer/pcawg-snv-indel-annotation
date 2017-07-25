#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: |
    This subworkflow will perform a QA check on the OxoG outputs. It will perform the QA check on a single tumour and it associated VCFs

class: Workflow

requirements:
    - class: SchemaDefRequirement
      types:
        - $import: TumourType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: oxog_varbam_annotate_util.js }
    - class: SubworkflowFeatureRequirement

outputs:
    qa_check:
        File

inputs:
    tumour_record:
        type: "TumourType.yaml#TumourType"
    vcfs:
        type: File[]
    normal_bam:
        type: File
    normal_minibam:
        type: File
    tumour_bam:
        type: File
    tumour_minibam:
        type: File

steps:
    check_files:
        in:
            vcfs_to_check:
                source: [tumour_record, vcfs]
                valueFrom: |
                    ${
                        var tumour_record = self[0]
                        var vcfs = self[1]
                        var vcfsToUse = [];
                        //this might be a nested array if it came from the OxoG output.
                        var flattened_array = flatten_nested_arrays(vcfs);
                        var associated_vcfs = tumour_record.associatedVcfs
                        for (var i in associated_vcfs)
                        {
                            for (var j in flattened_array)
                            {
                                if ( flattened_array[j].basename.indexOf(associated_vcfs[i].replace(".vcf.gz","")) !== -1 )
                                {
                                    //console.log("OK "+flattened_array[j].basename + " was in "+associated_vcfs[i] +" so it will be annotated!")
                                    vcfsToUse.push( flattened_array[j] );
                                }
                                /*else
                                {
                                    //console.log("Not OK "+ flattened_array[j].basename + " was NOT in "+associated_vcfs[i] +" so it will NOT be annotated!")
                                }*/
                            }
                        }
                        return vcfsToUse;
                    }
            tumour_bam: tumour_bam
            tumour_minibam: tumour_minibam
            working_directory:
                default: '/tmp/'
            normal_bam: normal_bam
            normal_minibam: normal_minibam
        out:
            [qa_result]
        run:
            class: CommandLineTool
            requirements:
              - class: DockerRequirement
                dockerPull: quay.io/pancancer/pcawg-oxog-tools
              - class: InitialWorkDirRequirement
                listing:
                  - $( inputs.normal_bam )
                  - $( inputs.normal_minibam )
                  - $( inputs.tumour_bam )
                  - $( inputs.tumour_minibam )

            inputs:
                working_directory:
                    type: string
                    inputBinding:
                        position: 0
                normal_bam:
                    type: File
                    inputBinding:
                        position: 1
                normal_minibam:
                    type: File
                    inputBinding:
                        position: 2
                tumour_bam:
                    type: File
                    inputBinding:
                        position: 3
                tumour_minibam:
                    type: File
                    inputBinding:
                        position: 4
                vcfs_to_check:
                    type: File[]
                    inputBinding:
                        position: 5
            stdout:  qa_check.txt
            outputs:
                qa_result:
                    type: File
                    outputBinding:
                        glob: "qa_check.txt"
            baseCommand: /opt/oxog_scripts/check_minibams.sh
