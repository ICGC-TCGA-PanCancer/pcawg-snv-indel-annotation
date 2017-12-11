#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: |
    This workflow will run OxoG, variantbam, and annotate.
    Run this as `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
    - class: SchemaDefRequirement
      types:
          - $import: PreprocessedFilesType.yaml
          - $import: TumourType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: annotate_util.js }
    - class: SubworkflowFeatureRequirement

inputs:
    refFile:
      type: File
    out_dir:
      type: string
    tumourBams:
      type: File[]
    normalBam:
      type: File
    oxogVCFs:
      type: File[]
    inputFileDirectory:
      type: Directory
    tumours:
      type:
        type: array
        items: "TumourType.yaml#TumourType"

outputs:
    annotated_files:
        type: File[]
        outputSource: zip_annotated_vcfs/zipped_file

    annotated_files_indicies:
        type: File[]
        outputSource: zip_annotated_vcfs/indexed_file

steps:
    ########################################
    # Preprocessing                        #
    ########################################
    #
    # Execute the preprocessor subworkflow.
    preprocess_vcfs:
        in:
            vcfdir: inputFileDirectory
            ref: refFile
            out_dir: out_dir
            filesToPreprocess:
                source: [ tumours ]
                valueFrom: |
                    ${
                        // Put all VCFs into an array.
                        var VCFs = []
                        for (var i in self)
                        {
                            for (var j in self[i].associatedVcfs)
                            {
                                VCFs.push(self[i].associatedVcfs[j])
                            }
                        }
                        return VCFs;
                    }
        run: preprocess_vcf.cwl
        out: [preprocessedFiles]

    get_normalized_vcfs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                normalized_vcfs: File[]
            expression: |
                $( { normalized_vcfs:  inputs.in_record.normalizedVcfs } )
        out: [normalized_vcfs]

    ########################################
    # Do Annotation.                       #
    ########################################
    #
    # we need OxoG filtered files, and minibams (tumour and normal).
    # Then we need to scatter. We can scatter on minibams, and perform all annotations
    # for each minibam at a time.
    # Of course, this shoudl work with regular (non-mini) bams, but will probably run slower.
    run_annotator_snvs:
        in:
            tumourBams: tumourBams
            VCFs: oxogVCFs
            tumour_record:
                source: tumours
            normalBam: normalBam
            variantType:
                default: "SNV"
        out: [ annotated_vcfs ]
        scatter: [tumour_record]
        run: annotator_sub_wf.cwl

    # Annotation must also be performed on INDELs but since INDELs don't get OxoG-filtered,
    # we will use the normalized INDELs.
    run_annotator_indels:
        in:
            tumourBams: tumourBams
            VCFs: get_normalized_vcfs/normalized_vcfs
            tumour_record:
                source: tumours
            normalBam: normalBam
            variantType:
                default: "INDEL"
        out: [annotated_vcfs]
        scatter: [tumour_record]
        run: annotator_sub_wf.cwl

    gather_annotated_vcfs:
        in:
            annotated_snvs: run_annotator_snvs/annotated_vcfs
            annotated_indels: run_annotator_indels/annotated_vcfs
        run:
            class: ExpressionTool
            inputs:
                annotated_snvs:
                    type: { type: array, items: { type: array, items: File } }
                annotated_indels:
                    type: { type: array, items: { type: array, items: File } }
            outputs:
                annotated_vcfs: File[]
            expression: |
                $(
                    { annotated_vcfs: flatten_nested_arrays(inputs.annotated_snvs).concat(flatten_nested_arrays(inputs.annotated_indels)) }
                )
        out:
            [annotated_vcfs]


    zip_annotated_vcfs:
        in:
            vcf: gather_annotated_vcfs/annotated_vcfs
        scatter: [vcf]
        run: zip_and_index_vcf.cwl
        out: [ zipped_file, indexed_file ]
