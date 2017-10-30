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
        - { $include: oxog_varbam_annotate_util.js }
        # Shouldn't have to *explicitly* include these but there's
        # probably a bug somewhere that makes it necessary
        - { $include: preprocess_util.js }
        - { $include: vcf_merge_util.js }
    - class: SubworkflowFeatureRequirement

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
    refDataDir:
      type: Directory
    minibamName:
      type: string
    vcfdir:
      type: Directory
    # "tumours" is an array of records. Each record contains the tumour ID, BAM
    # file name, and an array of VCFs.
    tumours:
      type:
        type: array
        items: "TumourType.yaml#TumourType"

outputs:
    oxog_filtered_files:
        type: File[]
        outputSource: flatten_oxog_output/oxogVCFs
        secondaryFiles: "*.tbi"
    minibams:
        type: File[]
        outputSource: gather_minibams/minibams
        secondaryFiles: "*.bai"
    annotated_files:
        type: File[]
        outputSource: gather_annotated_vcfs/annotated_vcfs

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
                    //return self[0].associatedVcfs
                }
      run: preprocess_vcf.cwl
      out: [preprocessedFiles]

    get_merged_vcfs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                merged_vcfs: File[]
            expression: |
                $( { merged_vcfs:  inputs.in_record.mergedVcfs } )
        out: [merged_vcfs]

    get_cleaned_vcfs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                cleaned_vcfs: File[]
            expression: |
                $( { cleaned_vcfs:  inputs.in_record.cleanedVcfs } )
        out: [cleaned_vcfs]

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

    get_extracted_snvs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                extracted_snvs: File[]?
            expression: |
                $( { extracted_snvs:  inputs.in_record.extractedSnvs } )
        out: [extracted_snvs]

    filter_merged_snv:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_snv_vcf: File
            expression: |
                $({ merged_snv_vcf: filterFileArray("snv",inputs.in_vcfs) })
        out: [merged_snv_vcf]

    filter_merged_indel:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_indel_vcf: File
            expression: |
                $({ merged_indel_vcf: filterFileArray("indel",inputs.in_vcfs) })
        out: [merged_indel_vcf]

    filter_merged_sv:
        in:
            in_vcfs: get_merged_vcfs/merged_vcfs
        run:
            class: ExpressionTool
            inputs:
                in_vcfs: File[]
            outputs:
                merged_sv_vcf: File
            expression: |
                $({ merged_sv_vcf: filterFileArray("sv",inputs.in_vcfs) })
        out: [merged_sv_vcf]

    ########################################
    # Do Variantbam                        #
    ########################################
    # This needs to be run for each tumour, using VCFs that are merged pipelines per tumour.
    run_variant_bam:
        in:
            in_data:
                source: tumours
            indel-padding: indel-padding
            snv-padding: snv-padding
            sv-padding: sv-padding
            input-snv: filter_merged_snv/merged_snv_vcf
            input-sv: filter_merged_sv/merged_sv_vcf
            input-indel: filter_merged_indel/merged_indel_vcf
            inputFileDirectory: inputFileDirectory
        out: [minibam]
        scatter: [in_data]
        run: ./minibam_sub_wf.cwl

    # Create minibam for normal BAM. It would be nice to figure out how to get this into
    # the main run_variant_bam step that currently only does tumour BAMs.
    run_variant_bam_normal:
        in:
            indel-padding: indel-padding
            snv-padding: snv-padding
            sv-padding: sv-padding
            input-snv: filter_merged_snv/merged_snv_vcf
            input-sv: filter_merged_sv/merged_sv_vcf
            input-indel: filter_merged_indel/merged_indel_vcf
            inputFileDirectory: inputFileDirectory
            input-bam: normalBam
            outfile:
                source: normalBam
                valueFrom: $("mini-".concat(self.basename))
        run: Variantbam-for-dockstore/variantbam.cwl
        out: [minibam]

    # Gather all minibams into a single output array.
    gather_minibams:
        in:
            tumour_minibams: run_variant_bam/minibam
            normal_minibam: run_variant_bam_normal/minibam
        run:
            class: ExpressionTool
            inputs:
                tumour_minibams: File[]
                normal_minibam: File
            outputs:
                minibams: File[]
            expression: |
                $( { minibams: inputs.tumour_minibams.concat(inputs.normal_minibam) } )
        out: [minibams]

    ### Prepare for OxoG!
    # First we need to zip and index the VCFs - the OxoG filter requires them to be
    # zipped and index.
    zip_and_index_files_for_oxog:
        in:
            vcf:
                source: get_cleaned_vcfs/cleaned_vcfs
        scatter: [vcf]
        out: [zipped_file]
        run: zip_and_index_vcf.cwl

    # Gather the appropriate VCFS.
    # All SNVs, and all SNVs extracted from INDELs.
    gather_vcfs_for_oxog:
        in:
            vcf:
                source: [zip_and_index_files_for_oxog/zipped_file]
                valueFrom: |
                    ${
                        var snvs = []
                        for (var i in self)
                        {
                            if (self[i].basename.indexOf("snv") !== -1)
                            {
                                snvs.push(self[i])
                            }
                        }
                        return snvs
                    }
            extractedSNVs:
                source: get_extracted_snvs/extracted_snvs
        run:
            class: ExpressionTool
            inputs:
                vcf: File[]
                extractedSNVs: File[]?
            outputs:
                vcfs: File[]
            expression: |
                $(
                    { vcfs: inputs.vcf.concat(inputs.extractedSNVs) }
                )
        out: [vcfs]


    ########################################
    # Do OxoG Filtering                    #
    ########################################
    #
    # OxoG only runs on SNV VCFs
    run_oxog:
        in:
            in_data:
                source: tumours
            inputFileDirectory: inputFileDirectory
            refDataDir: refDataDir
            vcfsForOxoG: gather_vcfs_for_oxog/vcfs
        out: [oxogVCF]
        scatter: [in_data]
        run: oxog_sub_wf.cwl

    flatten_oxog_output:
        in:
            array_of_arrays: run_oxog/oxogVCF
        run:
            class: ExpressionTool
            inputs:
                array_of_arrays:
                    type: { type: array, items: { type: array, items: File } }
            expression: |
                $(
                    { oxogVCFs: flatten_nested_arrays(inputs.array_of_arrays) }
                )
            outputs:
                oxogVCFs: File[]
        out:
            [oxogVCFs]

    ########################################
    # Do Annotation.                       #
    ########################################
    #
    # we need OxoG filtered files, and minibams (tumour and normal).
    # Then we need to scatter. We can scatter on minibams, and perform all annotations
    # for each minibam at a time.
    run_annotator_snvs:
        in:
            tumourMinibams: run_variant_bam/minibam
            VCFs: flatten_oxog_output/oxogVCFs
            tumour_record:
                source: tumours
            normalMinibam: run_variant_bam_normal/minibam
            variantType:
                default: "SNV"
        out: [ annotated_vcfs ]
        scatter: [tumour_record]
        run: annotator_sub_wf.cwl

    # Annotation must also be performed on INDELs but since INDELs don't get OxoG-filtered,
    # we will use the normalized INDELs.
    run_annotator_indels:
        in:
            tumourMinibams: run_variant_bam/minibam
            VCFs: get_normalized_vcfs/normalized_vcfs
            tumour_record:
                source: tumours
            normalMinibam: run_variant_bam_normal/minibam
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

    # Now run the QA check.
    qa_check:
        in:
            tumourMinibams: run_variant_bam/minibam
            tumour_record:
                source: tumours
            normal_bam: normalBam
            vcfs: flatten_oxog_output/oxogVCFs
            normalMinibam: run_variant_bam_normal/minibam
            inputFileDirectory: inputFileDirectory
        scatter: [tumour_record]
        run:
            class: Workflow
            inputs:
                inputFileDirectory:
                    type: Directory
                tumour_record:
                    type: "TumourType.yaml#TumourType"
                vcfs:
                    type: File[]
                normal_bam:
                    type: File
                    secondaryFiles: .bai
                tumourMinibams:
                    type: File[]
                normalMinibam:
                    type: File
            steps:
                run_qa_check:
                    in:
                        tumour_record: tumour_record
                        vcfs: vcfs
                        normal_bam: normal_bam
                        normal_minibam: normalMinibam
                        tumour_minibam:
                            source: [tumour_record, tumourMinibams]
                            valueFrom: |
                                ${
                                    for (var i in self[1])
                                    {
                                        var tumourMinibam = self[1][i]
                                        if (tumourMinibam.basename.indexOf( self[0].bamFileName ) !== -1)
                                        {
                                            return tumourMinibam
                                        }
                                    }
                                }
                        tumour_bam:
                            source: [inputFileDirectory, tumour_record]
                            valueFrom: |
                                ${
                                    return { "class":"File", "location": self[0].location + "/" + self[1].bamFileName }
                                }
                    out: [qa_result]
                    run: qa_check_subwf.cwl
            outputs:
                qa_result:
                    type: File
        out:
            [qa_result]
