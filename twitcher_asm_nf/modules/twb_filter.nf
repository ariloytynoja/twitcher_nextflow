/*
 * Filter per-chromosome processed CSVs with twb cli, then concatenate
 * all filtered files into a single combined CSV with csvtk.
 * Both twb and csvtk are expected in the twb container.
 */

process TWB_FILTER {
    tag "${sample}"
    label 'twb'

    publishDir "${params.outdir}/twb/${sample}/filtered", mode: 'copy'

    input:
    tuple val(sample), path(csvs)

    output:
    tuple val(sample), path("${sample}.filter.loose.csv"),  emit: loose, optional: true
    tuple val(sample), path("${sample}.filter.strict.csv"), emit: strict, optional: true
    tuple val(sample), path("${sample}.filter.loose_report.json"),  emit: loose_report, optional: true
    tuple val(sample), path("${sample}.filter.strict_report.json"), emit: strict_report, optional: true

    script:
    """
    # Filter each per-chromosome CSV
    for csv in ${csvs}; do
        chr=\$(basename \${csv} | rev | cut -d. -f3 | rev)
        name=${sample}.\${chr}
        if [ \$(wc -l < \${csv}) -le 1 ]; then
            echo "Skipping \${csv}: no data rows found"
        else
            twb cli -O \$(realpath \${csv}) \
                -o \${name}.filter.loose.csv \
                -f ts_2_3_max:gte:8 \
                -f tsm_copy_identity:eq:1 \
                -f duplicate_group_is_representative:eq:1 \
                -f repeat_overlap:eq:0 \
                -f delta_total_mismatch_bp:gte:0 \
                -f delta_total_edit_bp:gte:2 \
                -R \${name}.filter.loose_report.json

            twb cli -O \$(realpath \${csv}) \
                -o \${name}.filter.strict.csv \
                -f identity_20bp_upstream:eq:1 \
                -f identity_20bp_downstream:eq:1 \
                -f ts_2_3_max:gte:10 \
                -f tsm_copy_identity:eq:1 \
                -f duplicate_group_is_representative:eq:1 \
                -f repeat_overlap:eq:0 \
                -f delta_total_mismatch_bp:gte:1 \
                -f delta_total_edit_bp:gte:2 \
                -R \${name}.filter.strict_report.json
        fi
    done

    # Concatenate all filtered CSVs into one file
    loose_files=\$(ls ${sample}.*.filter.loose.csv | sort -V)
    strict_files=\$(ls ${sample}.*.filter.strict.csv | sort -V)

    csvtk concat \${loose_files}  -o ${sample}.filter.loose.csv
    csvtk concat \${strict_files} -o ${sample}.filter.strict.csv

    loose_files=\$(ls ${sample}.*.filter.loose_report.json | sort -V)
    strict_files=\$(ls ${sample}.*.filter.strict_report.json | sort -V)

    cat \${loose_files}  > ${sample}.filter.loose_report.json
    cat \${strict_files} > ${sample}.filter.strict_report.json
    """
}