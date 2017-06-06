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
    oxogVCFs:
        type: File[]
    normalMinibam:
        type: File
outputs:
    annotated_vcfs:
        type: File[]
        outputSource: annotator_sub_workflow/annotated_vcfs
steps:
    annotator_sub_workflow:
        in:
            tumour_record: tumour_record
            tumourMinibams: tumourMinibams
            oxogVCFs: oxogVCFs
            normalMinibam: normalMinibam
            indelsToAnnotate:
                source: [oxogVCFs, tumour_record]
                valueFrom: |
                    ${
                        return chooseINDELsForAnnotator(self[0], self[1])
                    }
            snvsToAnnotate:
                source: [oxogVCFs, tumour_record]
                valueFrom: |
                    ${
                        return chooseSNVsForAnnotator(self[0], self[1])
                    }
        out:
            [annotated_vcfs]
        run:
            class: Workflow
            inputs:
                tumour_record:
                    type: "TumourType.yaml#TumourType"
                tumourMinibams:
                    type: File[]
                oxogVCFs:
                    type: File[]
                normalMinibam:
                    type: File
                indelsToAnnotate:
                    type: File[]
                snvsToAnnotate:
                    type: File[]
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
                        input_vcf: indelsToAnnotate
                        normal_bam: normalMinibam
                        tumour_bam:
                            source: [tumourMinibams, tumour_record]
                            valueFrom: |
                                ${
                                    return chooseMiniBamsForAnnotator(self[0], self[1])
                                }
                        # output:
                        #     source: [input_vcf]
                        #     valueFrom: $( self.basename.replace(".vcf","_annotated.vcf") )
                    scatter: [input_vcf]
                    out:
                        [annotated_vcf]
                    # run: sga-annotate-docker/Dockstore.cwl
                    run:
                        class: Workflow
                        inputs:
                            variant_type:
                                type: string
                            input_vcf:
                                type: File
                            normal_bam:
                                type: File
                            tumour_bam:
                                type: File
                        steps:
                            sub_annotate_indels:
                                in:
                                    variant_type: variant_type
                                    input_vcf: input_vcf
                                    normal_bam: normal_bam
                                    tumour_bam: tumour_bam
                                    output:
                                        source: [input_vcf]
                                        valueFrom: $( self.basename.replace(".vcf","_annotated.vcf") )
                                out:
                                    [annotated_vcf]
                                run: sga-annotate-docker/Dockstore.cwl
                        outputs:
                            annotated_vcf:
                                type: File
                                outputSource: sub_annotate_indels/annotated_vcf

                # This subworkflow step will annotate ALL SNVs for a specific tumour
                # needs to scatter over snvsToUse
                annotate_snvs:
                    in:
                        variant_type:
                            valueFrom: "SNV"
                        input_vcf: snvsToAnnotate
                        normal_bam: normalMinibam
                        tumour_bam:
                            source: [tumourMinibams, tumour_record]
                            valueFrom: |
                                ${
                                    return chooseMiniBamsForAnnotator(self[0], self[1])
                                }
                        # output:
                        #     source: [input_vcf]
                        #     valueFrom: $( self.basename.replace(".vcf","_annotated.vcf"))
                    scatter: [input_vcf]
                    out:
                        [annotated_vcf]
                    # run: sga-annotate-docker/Dockstore.cwl
                    run:
                        class: Workflow
                        inputs:
                            variant_type:
                                type: string
                            input_vcf:
                                type: File
                            normal_bam:
                                type: File
                            tumour_bam:
                                type: File
                        steps:
                            sub_annotate_snvs:
                                in:
                                    variant_type: variant_type
                                    input_vcf: input_vcf
                                    normal_bam: normal_bam
                                    tumour_bam: tumour_bam
                                    output:
                                        source: [input_vcf]
                                        valueFrom: $( self.basename.replace(".vcf","_annotated.vcf") )
                                out:
                                    [annotated_vcf]
                                run: sga-annotate-docker/Dockstore.cwl
                        outputs:
                            annotated_vcf:
                                type: File
                                outputSource: sub_annotate_snvs/annotated_vcf

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
                            $( { annotated_vcfs: inputs.annotated_indels.concat(inputs.annotated_snvs) } )
                    out:
                        [annotated_vcfs]
