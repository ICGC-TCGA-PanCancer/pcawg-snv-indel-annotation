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
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: ./preprocess_util.js }
        # Shouldn't have to *explicitly* include vcf_merge_util.js but there's
        # probably a bug somewhere that makes it necessary
        - { $include: ./vcf_merge_util.js }
    - class: SubworkflowFeatureRequirement

inputs:
    - id: vcfdir
      type: Directory
    - id: ref
      type: File
    - id: out_dir
      type: string

# There are three output sets:
# - The merged VCFs.
# - The VCFs that are cleaned and normalized.
# - The SNVs that were extracted from INDELs (if there were any - usually there are none).
outputs:
    preprocessedFiles:
        type: "PreprocessedFilesType.yaml#PreprocessedFileset"
        outputSource: populate_output_record/output_record

    # mergedVCFs:
    #   type: File[]
    #   outputSource: merge_vcfs/output
    # normalizedVCFs:
    #   type: File[]
    #   outputSource: normalize/normalized-vcf
    # extractedSNVs:
    #   type: File[]
    #   outputSource: extract_snv/extracted_snvs



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

    #############################################
    # Gather SNVs on a per-workflow basis
    #############################################

    gather_sanger_snvs:
      in:
        clean_vcfs:
            source: clean/clean_vcf
        extracted_snvs:
            source: extract_snv/extracted_snvs
      out: [snvs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          clean_vcfs: File[]
          extracted_snvs: File[]
        outputs:
          snvs_for_merge: File[]
        expression: |
            $({ snvs_for_merge: (filterFor("svcp","snv_mnv",inputs.clean_vcfs)).concat(filterFor("svcp","snv_mnv",inputs.extracted_snvs)) })

    gather_dkfz_embl_snvs:
      in:
        clean_vcfs:
            source: clean/clean_vcf
        extracted_snvs:
            source: extract_snv/extracted_snvs
      out: [snvs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          clean_vcfs: File[]
          extracted_snvs: File[]
        outputs:
          snvs_for_merge: File[]
        expression: |
            $({ snvs_for_merge: (filterFor("dkfz-snvCalling","snv_mnv",inputs.clean_vcfs)).concat(filterFor("dkfz-snvCalling","snv_mnv",inputs.extracted_snvs)) })

    gather_broad_snvs:
      in:
        clean_vcfs:
            source: clean/clean_vcf
        extracted_snvs:
            source: extract_snv/extracted_snvs
      out: [snvs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          clean_vcfs: File[]
          extracted_snvs: File[]
        outputs:
          snvs_for_merge: File[]
        expression: |
            $({ snvs_for_merge: (filterFor("broad-mutect","snv_mnv",inputs.clean_vcfs)).concat(filterFor("broad-mutect","snv_mnv",inputs.extracted_snvs)) })

    gather_muse_snvs:
      in:
        clean_vcfs:
            source: clean/clean_vcf
        extracted_snvs:
            source: extract_snv/extracted_snvs
      out: [snvs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          clean_vcfs: File[]
          extracted_snvs: File[]
        outputs:
          snvs_for_merge: File[]
        expression: |
            $({ snvs_for_merge: (filterFor("MUSE","snv_mnv",inputs.clean_vcfs)).concat(filterFor("MUSE","snv_mnv",inputs.extracted_snvs)) })

    #############################################
    # Gather INDELs on a per-workflow basis
    #############################################

    gather_sanger_indels:
      in:
        normalized_vcfs: normalize/normalized-vcf
      out: [indels_for_merge]
      run:
        class: ExpressionTool
        inputs:
          normalized_vcfs: File[]
        outputs:
          indels_for_merge: File[]
        expression: |
            $({ indels_for_merge: filterFor("svcp","indel",inputs.normalized_vcfs) })

    gather_dkfz_embl_indels:
      in:
        normalized_vcfs: normalize/normalized-vcf
      out: [indels_for_merge]
      run:
        class: ExpressionTool
        inputs:
          normalized_vcfs: File[]
        outputs:
          indels_for_merge: File[]
        expression: |
            $({ indels_for_merge: filterFor("dkfz-indelCalling","indel",inputs.normalized_vcfs) })

    gather_broad_indels:
      in:
        normalized_vcfs: normalize/normalized-vcf
      out: [indels_for_merge]
      run:
        class: ExpressionTool
        inputs:
          normalized_vcfs: File[]
        outputs:
          indels_for_merge: File[]
        expression: |
            $({ indels_for_merge: filterFor("broad-snowman","indel",inputs.normalized_vcfs) })

    gather_smufin_indels:
      in:
        normalized_vcfs: normalize/normalized-vcf
      out: [indels_for_merge]
      run:
        class: ExpressionTool
        inputs:
          normalized_vcfs: File[]
        outputs:
          indels_for_merge: File[]
        expression: |
            $({ indels_for_merge: filterFor("smufin","indel",inputs.normalized_vcfs) })


    #############################################
    # Gather SVs on a per-workflow basis
    #############################################

    gather_sanger_svs:
      in:
        in_vcf: pass_filter/output
      out: [svs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          in_vcf: File[]
        outputs:
          svs_for_merge: File[]
        expression: |
            $({ svs_for_merge: filterFor("svfix",".sv.",inputs.in_vcf) })

    gather_broad_svs:
      in:
        in_vcf: pass_filter/output
      out: [svs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          in_vcf: File[]
        outputs:
          svs_for_merge: File[]
        expression: |
            $({ svs_for_merge: filterFor("broad-dRanger_snowman",".sv.",inputs.in_vcf) })

    gather_dkfz_embl_svs:
      in:
        in_vcf: pass_filter/output
      out: [svs_for_merge]
      run:
        class: ExpressionTool
        inputs:
          in_vcf: File[]
        outputs:
          svs_for_merge: File[]
        expression: |
            $({ svs_for_merge: filterFor("embl-delly",".sv.",inputs.in_vcf) })


    ###############################################
    # Do the VCF Merge
    ###############################################

    merge_vcfs:
      run:
        vcf_merge.cwl
      in:
        sanger_snv:
            source: gather_sanger_snvs/snvs_for_merge
        de_snv:
            source: gather_dkfz_embl_snvs/snvs_for_merge
        broad_snv:
            source: gather_broad_snvs/snvs_for_merge
        muse_snv:
            source: gather_muse_snvs/snvs_for_merge
        sanger_indel:
            source: gather_sanger_indels/indels_for_merge
        de_indel:
            source: gather_dkfz_embl_indels/indels_for_merge
        broad_indel:
            source: gather_broad_indels/indels_for_merge
        smufin_indel:
            source: gather_smufin_indels/indels_for_merge
        sanger_sv:
            source: gather_sanger_svs/svs_for_merge
        de_sv:
            source: gather_dkfz_embl_svs/svs_for_merge
        broad_sv:
            source: gather_broad_svs/svs_for_merge
        out_dir: out_dir
      out:
          [output]


    populate_output_record:
        in:
            mergedVcfs : merge_vcfs/output
            extractedSnvs : extract_snv/extracted_snvs
            normalizedVcfs: normalize/normalized-vcf
            cleanedVcfs: clean/clean_vcf
        out:
            [output_record]
        run:
            class: ExpressionTool
            inputs:
                mergedVcfs: File[]
                extractedSnvs: File[]
                normalizedVcfs: File[]
                cleanedVcfs: File[]
            outputs:
              output_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            expression: |
                    $(
                        {output_record: {
                            "cleanedVcfs": inputs.cleanedVcfs,
                            "mergedVcfs": inputs.mergedVcfs,
                            "extractedSnvs": inputs.extractedSnvs,
                            "normalizedVcfs": inputs.normalizedVcfs
                        }}
                    )
