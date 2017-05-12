#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

description: |
    This workflow will run OxoG, variantbam, and annotate.
    Run this as: `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

dct:creator:
    foaf:name: "Solomon Shorser"
    foaf:mbox: "solomon.shorser@oicr.on.ca"

requirements:
    - $import: TumourType.yaml
#    - $import: PreprocessedFilesType.yaml
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
    # preprocessed_files_merged:
    #     type: File[]
    #     outputSource: preprocess_vcfs/preprocessedFiles
    #     valueFrom: mergedVcfs
    # preprocessed_files_normalized:
    #     type: File[]
    #     outputSource: preprocess_vcfs/preprocessedFiles
    #     valueFrom: normalizedVcfs
    # preprocessed_files_extracted_snvs:
    #     type: File[]
    #     outputSource: preprocess_vcfs/preprocessedFiles
    #     valueFrom: extractedSnvs
    minibams:
        type: File[]
        outputSource: run_variant_bam/minibam
    # blah:
    #   type: File[]
    #     outputSource: filter_merged_sv/merged_sv_vcf
#     miniBams:
#       type: File[]
# #      outputSource: normalize/normalized-vcfminibamName
#       outputSource: run_variant_bam/minibam
#     # oxogOutputs:outFiles


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
                in_record: "TumourType.yaml#PreprocessedFileset"
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
                in_record: "TumourType.yaml#PreprocessedFileset"
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
                in_record: "TumourType.yaml#PreprocessedFileset"
            outputs:
                extracted_snvs: File[]
            expression: |
                $( { extracted_snvs:  inputs.in_record.extractedSnvs } )
        out: [extracted_snvs]
    # The filter_merged_* steps may need to be rewritten to handle multi-tumour situations.
    #
    # Need some ExpressionTool steps to get the specific names of merged VCFs to
    # feed into variantbam.
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
                        $(
                            {
                                "class":"File",
                                "location": inputs.inputFileDirectory.location + "/" + inputs.in_data.bamFileName
                            }
                        )
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



    # Do OxoG. Will also need some additional intermediate steps to sort out the
    # inputs and ensure that the  VCFs and BAM for the same tumour are run
    # together. OxoG only runs on SNV VCFs
    run_oxog:
        run: oxog.cwl
        scatter: run_oxog/tumours
        in:
            in_data:
                source: tumours
            inputFileDirectory: inputFileDirectory
            tumourBamFilename:
                default: ""
            tumourBamIndexFilename:
                default: ""
            # normalBam: normalBam
            refDataDir: refDataDir
            oxoQScore: oxoQScore
            # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
            vcfNames:
                default: ""
            tumourID:
                default: ""
            cleanedVcfs: get_cleaned_vcfs/cleaned_vcfs
            extractedSnvs: get_extracted_snvs/extracted_snvs
        out:
            [oxogVCF]
        scatter: [in_data]
        run:
            class: Workflow
            outputs:
                oxogVCF:
                    outputSource: sub_run_oxog/oxogVCF
                    type: File
            inputs:
                cleanedVcfs:
                    type: File[]
                extractedSnvs:
                    type: File[]
                inputFileDirectory:
                    type: Directory
                in_data:
                    type: "TumourType.yaml#TumourType"
                tumourBamFilename:
                    type: string
                    valueFrom: $( inputs.in_data.bamFileName )
                tumourBamIndexFilename:
                    type: string
                    valueFrom: $(inputs.in_data.tumourId + ".bai")
                # normalBam:
                #     type: string
                refDataDir:
                    type: Directory
                oxoQScore:
                    type: string
                # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
                vcfNames:
                    type: string[]
                    valueFrom: |
                        ${
                            var vcfsToUse = []
                            // Need to search through preprocess_vcfs/cleanedVCFs and preprocess_vcfs/extractedSNVs to find VCFs
                            // that match the names of those in in_data.inputs.associatedVCFs
                            //
                            var associatedVcfs = inputs.in_data.associatedVcfs
                            for ( var i in associatedVcfs )
                            {
                                if ( associatedVcfs[i].indexOf(".snv") !== -1 )
                                {
                                    //vcfsToUse.push( associatedVcfs[i] )
                                    for ( var j in inputs.cleanedVcfs )
                                    {
                                        if ( inputs.cleanedVcfs[j].basename.indexOf( associatedVcfs[i].replace(".vcf.gz","") ) !== -1 )
                                        {
                                            vcfsToUse.push(  inputs.cleanedVcfs[j].basename )
                                        }
                                    }
                                    // the normalized VCFs will end with ".normalized.vcf.gz" instead of ".vcf.gz"
                                    //if ( associatedVcfs[associatedVcf] )
                                }
                            }
                            return vcfsToUse
                        }
                tumourID:
                    valueFrom: $(inputs.in_data.tumourId)
                    type: string
            steps:
                # Need a step to move things from the preprocess_vcfs output dir into inputFileDirectory
                # move_vcfs:
                #     scatter: [vcfNames]
                #     in:
                #         vcfNames: vcfNames
                #     run:
                #         class: CommandLineTool
                #         inputs:
                #             vcfName:
                #                 type: string
                #
                #         outputs:
                #         basecommand: mv


                sub_run_oxog:
                    run: oxog.cwl
                    in:
                        inputFileDirectory: inputFileDirectory
                        tumourBamFilename: tumourBamFilename
                        tumourBamIndexFilename: tumourBamIndexFilename
#                        normalBam: normalBam
                        refDataDir: refDataDir
                        oxoQScore: oxoQScore
                        vcfNames: vcfNames
                        tumourID: tumourID
                    out: [oxogVCF]
    # Do Annotation. This will probably need some intermediate steps...

    # Do consensus-calling.
