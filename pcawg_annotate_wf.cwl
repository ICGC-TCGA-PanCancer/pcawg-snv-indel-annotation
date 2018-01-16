#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow

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


doc: |

    This workflow will run OxoG, variantbam, and annotate.
    Run this as `dockstore --script --debug workflow launch --descriptor cwl --local-entry --entry ./oxog_varbam_annotate_wf.cwl --json oxog_varbam_annotat_wf.input.json `

    ## Run the workflow with your own data
    ### Prepare compute environment and install software packages
    The workflow has been tested in Ubuntu 16.04 Linux environment with the following hardware
    and software settings.

    #### Hardware requirement (assuming 30X coverage whole genome sequence)
    - CPU core: 16
    - Memory: 64GB
    - Disk space: 1TB

    #### Software installation
    - Docker (1.12.6): follow instructions to install Docker https://docs.docker.com/engine/installation
    - CWL tool
    ```
    pip install cwltool==1.0.20170217172322
    ```

    ### Prepare input data
    #### Input unaligned BAM files

    #The workflow uses lane-level unaligned BAM files as input, one BAM per lane (aka read group).
    #Please ensure *@RG* field is populated properly in the BAM header, the following is a
    #valid *@RG* entry. *ID* field has to be unique among your dataset.
    ```
    #@RG	ID:WTSI:9399_7	CN:WTSI	PL:ILLUMINA	PM:Illumina HiSeq 2000	LB:WGS:WTSI:28085	PI:453	SM:f393ba16-9361-5df4-e040-11ac0d4844e8	PU:WTSI:9399_7	DT:2013-03-18T00:00:00+00:00
    ```

    #### Reference genome sequence files

    The reference genome files can be downloaded from the ICGC Data Portal at
    under https://dcc.icgc.org/releases/PCAWG/reference_data/pcawg-bwa-mem. Please download all
    reference files and put them under a subfolder called *reference*.

    #### Job JSON file for CWL

    Finally, we need to prepare a JSON file with input, reference and output files specified. Please
    replace the *reads* parameter with your real BAM file name.

    Name the JSON file: *pcawg-snv-indel-annotation.job.json*
    ```
    {
        "refFile": {
            "path": "/Homo_sapiens_assembly19.fasta",
            "class": "File"
        },
        "tumourBams": [
            {
                "path": "/tumour.bam",
                "class": "File"
            }
        ],
        "normalBam": {
            "path": "/normal.bam",
            "class": "File"
        },
        "tumours":
        [
            {
                "tumourId": "tumour",
                "bamFileName": "tumour.bam",
                "associatedVcfs":
                [
                    "*.somatic.snv_mnv.vcf.gz",
                    "*.somatic.sv.vcf.gz",
                    "*.somatic.indel.vcf.gz",
                    "*.somatic.snv_mnv.vcf.gz"
                ],
                "oxoQScore":0.0
            }
        ],
        "out_dir": "/var/spool/cwl/",
        "inputFileDirectory": {
            "class":"Directory",
            "path":"/files_for_workflow",
            "location":"/files_for_workflow"
        },
        "oxogVCFs":
        [
            {
                "path": "*.cleaned.oxoG.vcf.gz",
                "class": "File"
            },
            {
                "path": "*.somatic.snv_mnv.cleaned.oxoG.vcf.gz",
                "class": "File"
            },
            {
                "path": "*.somatic.snv_mnv.pass-filtered.cleaned.oxoG.vcf.gz",
                "class": "File"
            },
            {
                "path": "*.somatic.snv_mnv.pass-filtered.cleaned.oxoG.vcf.gz",
                "class": "File"
            },
            {
                "path": "*.somatic.snv_mnv.pass-filtered.cleaned.oxoG.vcf.gz",
                "class": "File"
            }
        ]
    }
    ```

    ### Run the workflow
    #### Option 1: Run with CWL tool
    - Download CWL workflow definition file
    ```
    #wget -O pcawg-bwa-mem-aligner.cwl "https://raw.githubusercontent.com/ICGC-TCGA-PanCancer/Seqware-BWA-Workflow/2.6.8_1.3/Dockstore.cwl"
    ```

    - Run *cwltool* to execute the workflow
    ```
    nohup cwltool --debug --non-strict pcawg_annotate_wf.cwl pcawg_annotate_wf.job.json > pcawg_annotate_wf.log 2>&1 &
    ```

    #### Option 2: Run with the Dockstore CLI
    See the *Launch with* section below for details

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
