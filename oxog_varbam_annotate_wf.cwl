#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

description: |
    This workflow will run OxoG, variantbam, and annotate.
    Run this as: `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

inputs:
    inputFileDirectory:
      type: Directory
    refFile:
      type: File
    out_dir:
      type: string
    normalBam:
      type: File
    snv-padding:
      type: string
    sv-padding:
      type: string
    indel-padding:
      type: string
    oxoQScore:
      type: string
    refDataDir:
      type: Directory
    # "tumours" is an array of records. Each record contains the tumour ID, BAM
    # file name, and an array of VCFs.
    tumours:
      type:
        type: array
        items:
          type: record
          name: tumour
          fields:
            tumourId:
              type: string
              inputBinding:
                  position: 0
            bamFileName:
              type: string
              inputBinding:
                  position: 2
            associatedVcfs:
              type: string[]
              inputBinding:
                  position: 1


outputs: []
    # blah:
    #   type: File[]
    #     outputSource: filter_merged_sv/merged_sv_vcf
#     miniBams:
#       type: File[]
# #      outputSource: normalize/normalized-vcf
#       outputSource: run_variant_bam/minibam
#     # oxogOutputs:outFiles

requirements:
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
    - class: SubworkflowFeatureRequirement
      expressionLib:
        - { $include: oxog_varbam_annotate_util.js }
        # Shouldn't have to *explicitly* include these but there's
        # probably a bug somewhere that makes it necessary
        - { $include: preprocess_util.js }
        - { $include: vcf_merge_util.js }

steps:
    #preprocess the VCFs
    preprocess_vcfs:
      run: preprocess_vcf.cwl
      in:
        vcfdir: inputFileDirectory
        ref: refFile
        out_dir: out_dir
      out: [mergedVCFs]

    # The filter_merged_* steps may need to be rewritten to handle multi-tumour situations.
    #
    # Need some ExpressionTool steps to get the specific names of merged VCFs to
    # feed into variantbam.
    # filter_merged_snv:
    #   in:
    #     in_vcfs: preprocess_vcfs/mergedVCFs
    #   out: [merged_snv_vcf]
    #   run:
    #     class: ExpressionTool
    #     inputs:
    #       in_vcfs: File[]
    #     outputs:
    #       merged_indel_vcf: File
    #     expression: |
    #       $({ merged_snv_vcf: filterFileArray("snv",inputs.in_vcfs) })
    #
    # filter_merged_indel:
    #   in:
    #     in_vcfs: preprocess_vcfs/mergedVCFs
    #   out: [merged_indel_vcf]
    #   run:
    #     class: ExpressionTool
    #     inputs:
    #       in_vcfs: File[]
    #     outputs:
    #       merged_indel_vcf: File
    #     expression: |
    #       $({ merged_indel_vcf: filterFileArray("indel",inputs.in_vcfs) })
    #
    # filter_merged_sv:
    #   in:
    #     in_vcfs: preprocess_vcfs/mergedVCFs
    #   out: [merged_sv_vcf]
    #   run:
    #     class: ExpressionTool
    #     inputs:
    #       in_vcfs: File[]
    #     outputs:
    #       merged_sv_vcf: File
    #     expression: |
    #       $({ merged_sv_vcf: filterFileArray("sv",inputs.in_vcfs) })


    # Do variantbam
    # This needs to be run for each tumour, using VCFs that are merged pipelines per tumour.
    # run_variant_bam:
    #   run: Variantbam-for-dockstore/variantbam.cwl
    #   in:
    #     input-bam: tumourBams
    #     outfile: minibamName
    #     snv-padding: snv-padding
    #     sv-padding: sv-padding
    #     indel-padding: indel-padding
    #     input-snv: filter_merged_snv/merged_snv_vcf
    #     input-sv: filter_merged_sv/merged_sv_vcf
    #     input-indel: filter_merged_indel/merged_indel_vcf
    #   scatter: run_variant_bam/input-bam
    #   out: [minibam]

    # Do OxoG. Will also need some additional intermediate steps to sort out the
    # inputs and ensure that the  VCFs and BAM for the same tumour are run
    # together. OxoG only runs on SNV VCFs
    # run_oxog:
    #   run: oxog.cwl
    #   scatter: run_oxog/tumours
    #   in:
    #       # Scatter by tumour ID
    #       tumour: $(inputs.tumours)
    #       # Need to get the name of the tumour file that matches tumourID
    #       tumourBamFilename: $(self.tumourBam)
    #       tumourBamIndexFilename: $(self.tumourBamIndex)
    #       normalBam: $(inputs.normalBam)
    #       inputFileDirectory: $(inputs.inputFileDirectory)
    #       refDataDir: $(inputs.refDataDir)
    #       oxoQScore: $(inputs.oxoQScore)
    #       # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
    #       vcfNames: $(getVCFsForTumour(tumourID, filter_merged_snv, filter_merged_sv, filter_merged_indel))

    # Do Annotation. This will probably need some intermediate steps...

    # Do consensus-calling.
