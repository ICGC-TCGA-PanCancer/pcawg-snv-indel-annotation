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
        - { $include: annotate_util.js }
    - class: SubworkflowFeatureRequirement

inputs:
    tumour_record:
        type: "TumourType.yaml#TumourType"
    tumourBams:
        type: File[]
    VCFs:
        type: File[]
    normalBam:
        type: File
    variantType:
        type: string
outputs:
    annotated_vcfs:
        type: File[]
        outputSource: chooseVCFsToAnnotate/annotated_vcf
steps:
    # This step will prepare the next level by creating vcfsToAnnotate as an array of
    # vcfs that need to be annotated
    chooseVCFsToAnnotate:
        in:
            vcfsToAnnotate:
                source: [tumour_record, VCFs]
                valueFrom: |
                    ${
                        return chooseVCFsForAnnotator(self[1], self[0].associatedVcfs)
                    }
            tumour_bam:
                source: [tumour_record, tumourBams]
                valueFrom: |
                    ${
                        return chooseBamForAnnotator(self[1], self[0])
                    }
            variantType: variantType
            normalBam: normalBam
        out: [annotated_vcf]
        run:
            class: Workflow
            inputs:
                tumour_bam:
                    type: File
                vcfsToAnnotate:
                    type: File[]
                variantType:
                    type: string
                normalBam:
                    type: File
            outputs:
                annotated_vcf:
                    type: File[]
                    outputSource: processVCFs/annotated_vcf
            steps:
                # This step scatters across the array of VCFs created by chooseVCFsToAnnotate
                processVCFs:
                    in:
                        tumour_bam: tumour_bam
                        input_vcf: vcfsToAnnotate
                        variant_type: variantType
                        normal_bam: normalBam
                    scatter: [input_vcf]
                    out:
                        [annotated_vcf]
                    run:
                        class: Workflow
                        inputs:
                            tumour_bam:
                                type: File
                            input_vcf:
                                type: File
                            variant_type:
                                type: string
                            normal_bam:
                                type: File
                        steps:
                            # This step takes the scatter of processVCFs and executes the annotator on each VCF.
                            annotate:
                                in:
                                    tumour_bam: tumour_bam
                                    input_vcf: input_vcf
                                    variant_type: variant_type
                                    normal_bam: normal_bam
                                    output:
                                        source: [input_vcf]
                                        valueFrom: |
                                            ${
                                                return self.basename.replace('.vcf.gz','_annotated.vcf')
                                            }
                                out:
                                    [annotated_vcf]
                                run:
                                    sga-annotate-docker/Dockstore.cwl
                        outputs:
                            annotated_vcf:
                                type: File
                                outputSource: annotate/annotated_vcf
