#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

inputs:
    - id: vcfdir
      type: Directory
    - id: ref
      type: File

outputs:
    outFiles:
      type: File[]
#      outputSource: normalize/normalized-vcf
      outputSource: extract_snv/extracted_snvs

requirements:
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: preprocess_util.js }

steps:
    pass_filter:
      run: pass-filter.cwl
      in:
        vcfdir: vcfdir
      out: [output]

    clean:
      run: clean_vcf.cwl
      scatter: clean/vcf
      in:
        vcf: pass_filter/output
      out: [clean_vcf]

    filter:
      in:
        in_vcf: clean/clean_vcf
      out: [out_vcf]
      run:
        class: ExpressionTool
        inputs:
          in_vcf: File[]
        outputs:
          out_vcf: File[]
        expression: |
            $({ out_vcf: filterForIndels(inputs.in_vcf) })

    normalize:
      run: normalize.cwl
      scatter: normalize/vcf
      in:
        vcf:
          source: filter/out_vcf
        ref: ref
      out: [normalized-vcf]

    extract_snv:
      run: extract_snv.cwl
      scatter: extract_snv/vcf
      in:
          vcf: normalize/normalized-vcf
      out: [extracted_snvs]
