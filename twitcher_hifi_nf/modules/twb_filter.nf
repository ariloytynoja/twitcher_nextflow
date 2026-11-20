/*
 * Filter per-chromosome processed CSVs with twb cli, then concatenate
 * all filtered files into a single combined CSV with csvtk.
 * Both twb and csvtk are expected in the twb container.
 */

process TWB_FILTER {
    tag "${sample}"
    label 'twb'

    publishDir "${params.outdir}/twb/filtered", mode: 'copy'

    input:
    tuple val(sample), path(csvs)

    output:
    tuple val(sample), path("${sample}.filter1.csv"), emit: filter1, optional: true
    tuple val(sample), path("${sample}.filter2.csv"), emit: filter2, optional: true
    tuple val(sample), path("${sample}.filter3.csv"), emit: filter3, optional: true
    tuple val(sample), path("${sample}.filter1.report.json"), emit: filter1_report, optional: true
    tuple val(sample), path("${sample}.filter2.report.json"), emit: filter2_report, optional: true
    tuple val(sample), path("${sample}.filter3.report.json"), emit: filter3_report, optional: true

    script:
    def prefix = params.chrom ? "${sample}.${params.chrom}" : sample
    """
    # Filter each per-chromosome CSV
    for csv in ${csvs}; do
        chr=\$(basename \${csv} | rev | cut -d. -f3 | rev)
        name=${sample}.\${chr}
        if [ \$(wc -l < \${csv}) -le 1 ]; then
            echo "Skipping \${csv}: no data rows found"
        else
            twb cli -O \$(realpath \${csv}) \
                -o \${name}.filter1.csv \
                -f ts_2_3_max:gte:8 \
                -f tsm_copy_identity:eq:1 \
                -f duplicate_group_is_representative:eq:1 \
                -f repeat_overlap:eq:0 \
                -f delta_total_edit_bp:gte:2 \
                -R \${name}.filter1.report.json

            twb cli -O \${name}.filter1.csv \
                -o \${name}.filter2.csv \
                -f ts_2_3_max:gte:10 \
                -f tsm_copy_identity:eq:1 \
                -f duplicate_group_is_representative:eq:1 \
                -f repeat_overlap:eq:0 \
                -f delta_total_edit_bp:gte:2 \
                -R \${name}.filter2.report.json

            twb cli -O \${name}.filter2.csv \
                -o \${name}.filter3.csv \
                -f ts_2_3_max:gte:10 \
                -f tsm_copy_identity:eq:1 \
                -f duplicate_group_is_representative:eq:1 \
                -f delta_total_mismatch_bp:gte:1 \
                -f delta_total_edit_bp:gte:2 \
                -f repeat_overlap:eq:0 \
                -f identity_20bp_upstream:gte:0.9 \
                -f identity_20bp_downstream:gte:0.9 \
                -R \${name}.filter3.report.json
        fi
    done

    # Concatenate all filtered CSVs into one file
    filter1_files=\$(ls ${sample}.*.filter1.csv 2>/dev/null | sort -V)
    filter2_files=\$(ls ${sample}.*.filter2.csv 2>/dev/null | sort -V)
    filter3_files=\$(ls ${sample}.*.filter3.csv 2>/dev/null | sort -V)

    [ -n "\$filter1_files" ] && csvtk concat \${filter1_files} -o ${prefix}.filter1.csv
    [ -n "\$filter2_files" ] && csvtk concat \${filter2_files} -o ${prefix}.filter2.csv
    [ -n "\$filter3_files" ] && csvtk concat \${filter3_files} -o ${prefix}.filter3.csv

    filter1_files=\$(ls ${sample}.*.filter1.report.json 2>/dev/null | sort -V)
    filter2_files=\$(ls ${sample}.*.filter2.report.json 2>/dev/null | sort -V)
    filter3_files=\$(ls ${sample}.*.filter3.report.json 2>/dev/null | sort -V)

    [ -n "\$filter1_files" ] && cat \${filter1_files} > ${prefix}.filter1.report.json
    [ -n "\$filter2_files" ] && cat \${filter2_files} > ${prefix}.filter2.report.json
    [ -n "\$filter3_files" ] && cat \${filter3_files} > ${prefix}.filter3.report.json
    """
}
