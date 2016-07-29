#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

inputs:
    - id: vcfdir
      type: Directory

outputs:
    outFiles:
      type: File[]
      outputSource: clean/clean-vcf

requirements:
    - class: ScatterFeatureRequirement
    - class: InlineJavascriptRequirement

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
      out: [clean-vcf]
