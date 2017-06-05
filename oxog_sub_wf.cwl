#!/usr/bin/env cwl-runner
cwlVersion: v1.0

doc: |
    This is a subworkflow of the main oxog_varbam_annotat_wf workflow - this is not meant to be
    run as a stand-alone workflow!

requirements:
    - class: SchemaDefRequirement
      types:
          - $import: TumourType.yaml
    - class: ScatterFeatureRequirement
    - class: StepInputExpressionRequirement
    - class: MultipleInputFeatureRequirement
    - class: InlineJavascriptRequirement
      expressionLib:
        - { $include: oxog_varbam_annotate_util.js }
    - class: SubworkflowFeatureRequirement


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
    refDataDir:
        type: Directory
    oxoQScore:
        type: string
    # Need to get VCFs for this tumour. Need an array made of the outputs of earlier VCF pre-processing steps, filtered by tumourID
steps:
    sub_run_oxog:
        run: oxog.cwl
        in:
            inputFileDirectory: inputFileDirectory
            tumourID:
                source: [in_data]
                valueFrom: |
                    ${
                        return self.tumourId
                    }
            tumourBamFilename:
                source: [inputFileDirectory, in_data]
                valueFrom: |
                    ${
                        return { "class":"File", "location": self[0].location + "/" + self[1].bamFileName }
                    }
            refDataDir: refDataDir
            oxoQScore: oxoQScore
            vcfNames:
                source: [in_data, vcfsForOxoG, extractedSnvs]
                valueFrom: |
                    ${
                        return createArrayOfFilesForOxoG(self[0], self[1], self[2])
                    }
        out: [oxogVCF]
