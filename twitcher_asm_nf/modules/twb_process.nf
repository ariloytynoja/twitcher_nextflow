/*
 * Run twb cli to post-process twitcher output.
 */

process TWB_PROCESS {
    tag "${sample}"
    label 'twb'

    publishDir "${params.outdir}/twb/${sample}/processed", mode: 'copy'

    input:
    tuple val(sample), path(csv)
    path ref_fa
    path ref_fai
    path ref_gzi
    path gff
    path gff_tbi
    path masking
    path masking_tbi

    output:
    tuple val(sample), path("*.processed.csv"),           emit: csv, optional: true
    tuple val(sample), path("*.postprocess_report.json"), emit: report, optional: true

    script:
    def chr  = csv.name.tokenize('.')[-2]
    def name = "${sample}.${chr}"
    """
    if [ \$(wc -l < ${csv}) -le 1 ]; then
        echo "Skipping ${csv}: no data rows found"
        touch ${name}.processed.csv ${name}.postprocess_report.json
    else
        twb cli ${csv} \
            -o ${name}.processed.csv \
            -r \$(realpath ${ref_fa}) \
            -g \$(realpath ${gff}) \
            -m \$(realpath ${masking}) \
            -R ${name}.postprocess_report.json
    fi
    """
}
