#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: |
    This workflow will perform preprocessing steps on VCFs for the OxoG/Variantbam/Annotation workflow.

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
    - class: SchemaDefRequirement
      types:
          - $import: PreprocessedFilesType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: ./preprocess_util.js }
    - class: SubworkflowFeatureRequirement

inputs:
    - id: vcfdir
      type: Directory
      doc: "The directory where the files are"
    - id: filesToPreprocess
      type: string[]
      doc: "The files to process"
    - id: ref
      type: File
      doc: "Reference file, used for normalized INDELs"
    - id: out_dir
      type: string
      doc: "The name of the output directory"

# There are three output sets:
# - The merged VCFs.
# - The VCFs that are cleaned and normalized.
# - The SNVs that were extracted from INDELs (if there were any - usually there are none).
outputs:
    preprocessedFiles:
        type: "PreprocessedFilesType.yaml#PreprocessedFileset"
        outputSource: populate_output_record/output_record

steps:
    # TODO: Exclude MUSE files from PASS-filtering. MUSE files still need to be cleaned, but should
    # not be PASS-filtered.
    pass_filter:
      doc: "Filter out non-PASS lines from the VCFs in filesToProcess."
      in:
        vcfdir: vcfdir
        filesToFilter:
            source: [ filesToPreprocess ]
            valueFrom: |
                ${
                    var VCFs = []
                    for (var i in self)
                    {
                        if (self[i].toLowerCase().indexOf("muse") == -1)
                        {
                            VCFs.push(self[i]);
                        }
                    }
                    return VCFs;
                }
      run: pass-filter.cwl
      out: [output]

    clean:
      doc: "Clean the VCFs."
      run: clean_vcf.cwl
      scatter: [vcf]
      in:
        vcf: pass_filter/output
      out: [clean_vcf]

    filter_for_indel:
      doc: "Filters the input list and selects the INDEL VCFs."
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
      doc: "Normalize the INDEL VCFs."
      run: normalize.cwl
      scatter: normalize/vcf
      in:
        vcf:
          source: filter_for_indel/out_vcf
        ref: ref
      out: [normalized-vcf]

    populate_output_record:
        in:
            normalizedVcfs: normalize/normalized-vcf
        out:
            [output_record]
        run:
            class: ExpressionTool
            inputs:
                normalizedVcfs: File[]
            outputs:
              output_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            expression: |
                    $(
                        {output_record: {
                            "normalizedVcfs": inputs.normalizedVcfs
                        }}
                    )
