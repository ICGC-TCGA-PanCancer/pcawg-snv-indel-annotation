#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: Workflow

doc: |
    This is a subworkflow of the main oxog_varbam_annotat_wf workflow - this is not meant to be
    run as a stand-alone workflow!

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

inputs:
    tumour_record:
        type: "TumourType.yaml#TumourType"
    tumourMinibams:
        type: File[]
    VCFs:
        type: File[]
    normalMinibam:
        type: File
    variantType:
        type: string
outputs:
    annotated_vcfs:
        type: File[]
        # type: { items: { type: array, items: File } , type: array}
        #outputSource: flatten_annotated_vcfs/flattened_annotated_vcfs_array
        outputSource: annotator_sub_workflow/annotated_vcf
steps:
    annotator_sub_workflow:
        in:
            # tumour_record: tumour_record
            # tumourMinibams: tumourMinibams
            tumour_bam:
                source: [tumourMinibams, tumour_record]
                valueFrom: |
                    ${
                        return chooseMiniBamForAnnotator(self[0], self[1])
                    }
            vcfsToAnnotate:
                source: [tumour_record, VCFs]
                valueFrom: |
                    ${
                        return chooseVCFsForAnnotator(self[1], self[0].associatedVcfs )
                    }
            variantType: variantType
            # VCFs: VCFs
            normalMinibam: normalMinibam
        scatter:
            [vcfsToAnnotate]
        out:
            [annotated_vcf]
        run:
            class: Workflow
            inputs:
                # tumour_record:
                #     type: "TumourType.yaml#TumourType"
                tumour_bam:
                    type: File
                vcfsToAnnotate:
                    type: File
                variantType:
                    type: string
                tumour_bam:
                    type: File
                normalMinibam:
                    type: File
            outputs:
                annotated_vcf:
                    type: File
                    outputSource: annotator_sub_sub_workflow/annotated_vcf
            steps:
                annotator_sub_sub_workflow:
                    in:
                        variant_type: variantType
                        input_vcf: vcfsToAnnotate
                        normal_bam: normalMinibam
                        tumour_bam: tumour_bam
                        output:
                            source: [vcfsToAnnotate]
                            valueFrom: $( self.basename.replace(".vcf","_annotated.vcf") )
                    out:
                        [ annotated_vcf ]
                    run: sga-annotate-docker/Dockstore.cwl

    # flatten_annotated_vcfs:
    #     in:
    #         array_of_arrays: annotator_sub_workflow/annotated_vcf
    #     run:
    #         class: ExpressionTool
    #         inputs:
    #             array_of_arrays:
    #                 type:  { type: array, items: { type: array, items: File } }
    #         outputs:
    #             flattened_annotated_vcfs_array: File[]
    #         expression: |
    #             $(
    #                 { flattened_annotated_vcfs_array: flatten_nested_arrays(inputs.array_of_arrays[0]) }
    #             )
    #     out:
    #         [flattened_annotated_vcfs_array]

    # flatten_oxog_output:
    #     in:
    #         array_of_arrays: run_oxog/oxogVCF
    #     run:
    #         class: ExpressionTool
    #         inputs:
    #             array_of_arrays:
    #                 type: { type: array, items: { type: array, items: File } }
    #         expression: |
    #             $({ oxogVCFs: flatten_nested_arrays(inputs.array_of_arrays[0]) })
    #         outputs:
    #             oxogVCFs: File[]
    #     out:
    #         [oxogVCFs]
