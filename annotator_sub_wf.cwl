#!/usr/bin/env cwl-runner
cwlVersion: v1.0

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

class: Workflow
inputs:
    tumours_list:
        type: "TumourType.yaml#TumourType"
    tumourMinibams:
        type: File[]
    # tumourMinibamToUse:
    #     type: File
    #     valueFrom: |
    #         ${
    #             return chooseMiniBamsForAnnotator(tumourMinibams, tumours_list)
    #         }
    oxogVCFs:
        type: File[]
    # indelsToUse:
    #     type: File[]
    #     valueFrom: |
    #         ${
    #             return getListOfVcfsForAnnotator(inputs)
    #         }
    # snvsToUse:
    #     type: File[]
    #     valueFrom: |
    #         ${
    #             return chooseSNVsForAnnotator(oxogVCFs, tumours_list)
    #         }
    tumours_list:
        type: "TumourType.yaml#TumourType"
    normalMinibam:
        type: File
outputs:
    annotated_vcfs:
        type: File[]
        outputSource: gather_annotated_vcfs/annotated_vcfs
steps:
    # This subworkflow step will annotate ALL INDELs for a specific tumour
    # needs to scatter over indelsToUse
    annotate_indels:
        in:
            variant_type:
                valueFrom: "INDEL"
            input_vcf:
                source: [oxogVCFs, tumours_list]
                valueFrom: |
                    ${
                        return chooseINDELsForAnnotator(self[0], self[1])
                    }
            normal_bam: normalMinibam
            tumour_bam:
                source: [tumourMinibams, tumours_list]
                valueFrom: |
                    ${
                        return chooseMiniBamsForAnnotator(self[0], self[1])
                    }
            output:
                valueFrom: $( input_vcf.basename.replace(".vcf","_annotated.vcf") )
        scatter: [input_vcf]
        out:
            [annotated_vcf]
        run: sga-annotate-docker/Dockstore.cwl
    # This subworkflow step will annotate ALL SNVs for a specific tumour
    # needs to scatter over snvsToUse
    annotate_snvs:
        in:
            variant_type:
                valueFrom: "SNV"
            input_vcf:
                source: [oxogVCFs, tumours_list]
                valueFrom: |
                    ${
                        return chooseSNVsForAnnotator(self[0], self[1])
                    }
            normal_bam: normalMinibam
            tumour_bam:
                source: [tumourMinibams, tumours_list]
                valueFrom: |
                    ${
                        return chooseMiniBamsForAnnotator(self[0], self[1])
                    }
            output:
                valueFrom: $( input_vcf.basename.replace(".vcf","_annotated.vcf"))
        scatter: [input_vcf]
        out:
            [annotated_vcf]
        run: sga-annotate-docker/Dockstore.cwl

    gather_annotated_vcfs:
        in:
            annotated_indels: annotate_indels/annotated_vcf
            annotated_snvs: annotate_snvs/annotated_vcf
        run:
            class: ExpressionTool
            inputs:
                annotated_indels: File[]
                annotated_snvs: File[]
            outputs:
                annotated_vcfs: File[]
            expression: |
                $({ annotated_vcfs: inputs.annotated_indels.concat(inputs.annotated_snvs) })
        out:
            [annotated_vcfs]
