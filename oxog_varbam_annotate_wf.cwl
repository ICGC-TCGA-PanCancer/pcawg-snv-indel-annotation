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
    preprocessed_files_merged:
        type: File[]
        outputSource: preprocess_vcfs/preprocessedFiles
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

    # The filter_merged_* steps may need to be rewritten to handle multi-tumour situations.
    #
    # Need some ExpressionTool steps to get the specific names of merged VCFs to
    # feed into variantbam.
    filter_merged_snv:
        in:
            in_vcfs:
                source: preprocess_vcfs/preprocessedFiles
                valueFrom: self.mergedVcfs
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
            in_vcfs:
                source: preprocess_vcfs/preprocessedFiles
                valueFrom: self.mergedVcfs
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
            in_vcfs:
                source: preprocess_vcfs/preprocessedFiles
                valueFrom: self.mergedVcfs
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
            normalizedVcfs:
                source: preprocess_vcfs/preprocessedFiles
                valueFrom: normalizedVCFs
            extractedSnvs:
                source: preprocess_vcfs/preprocessedFiles
                valueFrom: extractedSnvs
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
                normalizedVcfs:
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
                            // Need to search through preprocess_vcfs/normalizedVCFs and preprocess_vcfs/extractedSNVs to find VCFs
                            // that match the names of those in in_data.inputs.associatedVCFs
                            //

                            for ( var i in inputs.in_data.associatedVcfs )
                            {
                                if ( inputs.in_data.associatedVcfs[i].indexOf('.snv') > 0 )
                                {
                                    for ( var j in inputs.normalizedVcfs )
                                    {
                                        if ( inputs.normalizedVcfs[j].indexOf( inputs.in_data.associatedVcfs[i].replace(".vcf.gz") ) >= 0 )
                                        {
                                            vcfsToUse.push( inputs.normalizedVcfs[j].path + inputs.normalizedVcfs[j].basename )
                                        }
                                    }
                                    // the normalized VCFs will end with ".normalized.vcf.gz" instead of ".vcf.gz"
                                    //if ( inputs.in_data.associatedVcfs[associatedVcf] )
                                }
                            }
                            return vcfsToUse
                        }
                tumourID:
                    valueFrom: $(inputs.in_data.tumourId)
                    type: string
            steps:
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
