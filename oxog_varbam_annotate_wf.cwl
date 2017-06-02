#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

doc: |
    This workflow will run OxoG, variantbam, and annotate.
    Run this as: `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

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
    oxoQScore:
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
    minibams:
        type: File[]
        outputSource: gather_minibams/minibams
        secondaryFiles: "*.bai"
    annotated_files:
        type: File[]
        outputSource: flatten_annotator_output/annotated_vcfs

steps:
    #preprocess the VCFs
    preprocess_vcfs:
      run: preprocess_vcf.cwl
      in:
        vcfdir: inputFileDirectory
        ref: refFile
        out_dir: out_dir
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

    get_extracted_snvs:
        in:
            in_record: preprocess_vcfs/preprocessedFiles
        run:
            class: ExpressionTool
            inputs:
                in_record: "PreprocessedFilesType.yaml#PreprocessedFileset"
            outputs:
                extracted_snvs: File[]
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
                #type: string
                source: normalBam
                valueFrom: $("mini-".concat(self.basename))
        run: Variantbam-for-dockstore/variantbam.cwl
        out: [minibam]

    # Do variantbam
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
            input-bam:
                default: ""
            outfile:
                default: ""
        out: [minibam]
        scatter: [in_data]
        run:
            class: Workflow
            outputs:
                minibam:
                    outputSource: sub_run_var_bam/minibam
                    type: File
            inputs:
                inputFileDirectory:
                    type: Directory
                in_data:
                    type: "TumourType.yaml#TumourType"
                indel-padding:
                    type: string
                snv-padding:
                    type: string
                sv-padding:
                    type: string
                input-indel:
                    type: File
                input-snv:
                    type: File
                input-sv:
                    type: File
                input-bam:
                    type: File
                    valueFrom: |
                        $( { "class":"File", "location": inputs.inputFileDirectory.location + "/" + inputs.in_data.bamFileName } )
                outfile:
                    type: string
                    valueFrom: $("mini-".concat(inputs.in_data.tumourId).concat(".bam"))
            steps:
                sub_run_var_bam:
                    run: Variantbam-for-dockstore/variantbam.cwl
                    in:
                        input-bam: input-bam
                        outfile: outfile
                        snv-padding: snv-padding
                        sv-padding: sv-padding
                        indel-padding: indel-padding
                        input-snv: input-snv
                        input-sv: input-sv
                        input-indel: input-indel
                    out: [minibam]

    #Gather all minibams into a single output array.
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

    zip_and_index_files_for_oxog:
        in:
            vcf:
                source: get_cleaned_vcfs/cleaned_vcfs
                #type: File[]
        scatter: [vcf]
        out: [zipped_file]
        run: zip_and_index_vcf.cwl

    # Do OxoG. Will also need some additional intermediate steps to sort out the
    # inputs and ensure that the  VCFs and BAM for the same tumour are run
    # together. OxoG only runs on SNV VCFs
    run_oxog:
        in:
            in_data:
                source: tumours
            inputFileDirectory: inputFileDirectory
            tumourBamFilename:
                default: ""
            refDataDir: refDataDir
            oxoQScore: oxoQScore
            # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
            vcfNames:
                default: []
            tumourID:
                default: ""
            vcfsForOxoG: zip_and_index_files_for_oxog/zipped_file
            extractedSnvs: get_extracted_snvs/extracted_snvs
        out: [oxogVCF]
        scatter: [in_data]
        run:
            class: Workflow
            outputs:
                oxogVCF:
                    outputSource: sub_run_oxog/oxogVCF
                    type: File[]
            inputs:
                vcfsForOxoG:
                    type: File[]
                extractedSnvs:
                    type: File[]
                inputFileDirectory:
                    type: Directory
                in_data:
                    type: "TumourType.yaml#TumourType"
                tumourBamFilename:
                    type: File
                    valueFrom: |
                        $( { "class":"File", "location": inputs.inputFileDirectory.location + "/" + inputs.in_data.bamFileName } )
                refDataDir:
                    type: Directory
                oxoQScore:
                    type: string
                # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
                vcfNames:
                    type: File[]
                    valueFrom: |
                        ${
                            return createArrayOfFilesForOxoG(inputs)
                        }
                tumourID:
                    type: string
                    valueFrom: $(inputs.in_data.tumourId)
            steps:
                sub_run_oxog:
                    run: oxog.cwl
                    in:
                        inputFileDirectory: inputFileDirectory
                        tumourBamFilename: tumourBamFilename
                        refDataDir: refDataDir
                        oxoQScore: oxoQScore
                        vcfNames: vcfNames
                        tumourID: tumourID
                    out: [oxogVCF]

    flatten_oxog_output:
        in:
            array_of_arrays: run_oxog/oxogVCF
        run:
            class: ExpressionTool
            inputs:
                array_of_arrays:
                    type: { type: array, items: { type: array, items: File } }
            expression: |
                $({ oxogVCFs: flatten_nested_arrays(inputs.array_of_arrays[0]) })
            outputs:
                oxogVCFs: File[]
        out:
            [oxogVCFs]

    # Do Annotation. This will probably need some intermediate steps...
    # we need OxoG filtered files, and minibams (tumour and normal).
    # Then we need to scatter. We can scatter on minibams, and perform all annotations
    # for each minibam at a time.
    run_annotator:
        in:
            tumourMinibams: run_variant_bam/minibam
            oxogVCFs: flatten_oxog_output/oxogVCFs
            tumours_list:
                source: tumours
            normalMinibam: run_variant_bam_normal/minibam
            tumourMinibamToUse:
                default: ""
            snvsToUse:
                default: []
            indelsToUse:
                default: []
        out:
            [annotated_vcfs]
        scatter: [tumours_list]
        run:
            class: Workflow
            inputs:
                tumours_list:
                    type: "TumourType.yaml#TumourType"
                tumourMinibams:
                    type: File[]
                tumourMinibamToUse:
                    type: File
                    valueFrom: |
                        ${
                            return chooseMiniBamsForAnnotator(inputs)
                        }
                oxogVCFs:
                    type: File[]
                indelsToUse:
                    type: File[]
                    valueFrom: |
                        ${
                            return getListOfVcfsForAnnotator(inputs)
                        }
                snvsToUse:
                    type: File[]
                    valueFrom: |
                        ${
                            return chooseSNVsForAnnotator(inputs)
                        }
                tumours_list:
                    type: "TumourType.yaml#TumourType"
                normalMinibam:
                    type: File
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
                        input_vcf: indelsToUse
                        normal_bam: normalMinibam
                        tumour_bam: tumourMinibamToUse
                        output:
                            valueFrom: $(inputs.input_vcf.basename.replace(".vcf","_annotated.vcf"))
                    scatter: [input_vcf]
                    out:
                        [annotated_vcf]
                    run: sga-annotate-docker/Dockstore.cwl
                # This subworkflow step will annotate ALL SNVs for a specific tumour
                # needs to scatter over snvsToUse
                annotate_snvs:
                    in:
                        variant_type:
                            valueFrom: "SNV"
                        input_vcf: snvsToUse
                        normal_bam: normalMinibam
                        tumour_bam: tumourMinibamToUse
                        output:
                            valueFrom: $(inputs.input_vcf.basename.replace(".vcf","_annotated.vcf"))
                    scatter: [input_vcf]
                    out:
                        [annotated_vcf]
                    run: sga-annotate-docker/Dockstore.cwl

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
                            $({ annotated_vcfs: inputs.annotated_indels.concat(inputs.annotated_snvs) })
                    out:
                        [annotated_vcfs]


    flatten_annotator_output:
        in:
            array_of_arrays: run_annotator/annotated_vcfs
        run:
            class: ExpressionTool
            inputs:
                array_of_arrays:
                    type: { type: array, items: { type: array, items: File } }
            expression: |
                $({ annotated_vcfs: flatten_nested_arrays(inputs.array_of_arrays) })
            outputs:
                annotated_vcfs: File[]
        out:
            [annotated_vcfs]
    # Do consensus-calling.
