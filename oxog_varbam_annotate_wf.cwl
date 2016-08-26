#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

description: |
    This workflow will run OxoG, variantbam, and annotate.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

inputs:
    - id: vcfdir
      type: Directory
    - id: ref
      type: File
    - id: in_dir
      type: string
    - id: out_dir
      type: string
    - id: normalBam
      type: File
    - id: snv-padding
      type: string
    - id: sv-padding
      type: string
    - id: indel-padding
      type: string
    - id: tumourBams
      type: File[]
    - id: minibamName
      type: string

outputs:
    outFiles:
      type: File[]
#      outputSource: normalize/normalized-vcf
      outputSource: run_variant_bam/minibam


requirements:
    - class: SubworkflowFeatureRequirement
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: oxog_varbam_annotate_util.js}
        # Shouldn't have to *explicitly* include these but there's
        # probably a bug somewhere that makes it necessary
        - { $include: preprocess_util.js }
        - { $include: vcf_merge_util.js }

steps:
    #preprocess the VCFs
    preprocess_vcfs:
      run: preprocess_vcf.cwl
      in:
        vcfdir: vcfdir
        ref: ref
        in_dir: in_dir
        out_dir: out_dir
      out: [outFiles]

    # Need some ExpressionTool steps to get the specific names of merged VCFs to
    # feed into variantbam.
    filter_merged_snv:
      in:
        in_vcfs: preprocess_vcfs/outFiles
      out: [merged_snv_vcf]
      run:
        class: ExpressionTool
        inputs:
          in_vcfs: File[]
        outputs:
          merged_snv_vcf: File
        expression: |
          $({ merged_snv_vcf: filterFileArray("snv",inputs.in_vcfs) })

    filter_merged_indel:
      in:
        in_vcfs: preprocess_vcfs/outFiles
      out: [merged_indel_vcf]
      run:
        class: ExpressionTool
        inputs:
          in_vcfs: File[]
        outputs:
          merged_indel_vcf: File
        expression: |
          $({ merged_indel_vcf: filterFileArray("indel",inputs.in_vcfs) })

    filter_merged_sv:
      in:
        in_vcfs: preprocess_vcfs/outFiles
      out: [merged_sv_vcf]
      run:
        class: ExpressionTool
        inputs:
          in_vcfs: File[]
        outputs:
          merged_sv_vcf: File
        expression: |
          $({ merged_sv_vcf: filterFileArray("sv",inputs.in_vcfs) })


    # Do variantbam
    run_variant_bam:
      run: Variantbam-for-dockstore/variantbam.cwl
      in:
        input-bam: tumourBams
        outfile: minibamName
        snv-padding: snv-padding
        sv-padding: sv-padding
        indel-padding: indel-padding
        input-snv: filter_merged_snv/merged_snv_vcf
        input-sv: filter_merged_sv/merged_sv_vcf
        input-indel: filter_merged_indel/merged_indel_vcf
      scatter: run_variant_bam/input-bam
      out: [minibam]

    # Do OxoG. Will also need some additional intermediate steps to sort out the
    # inputs and ensure that the VCFs and BAM for the same tumour are run
    # together.


    # Do Annotation. This will probably need some intermediate steps...
