    /*
 * Run twitcher over selected (main) chromosomes on a BAM file.
 */

process TWITCHER_VCF {
    tag "${sample}:${chr}"
    label 'twitcher'

    publishDir "${params.outdir}/twitcher/${sample}/${chr}", mode: 'copy', saveAs: { filename ->
        file("${task.workDir}/${filename}").size() > 0 ? filename : null
    }
    
    input:
    tuple val(sample), path(vcf), path(tbi), path(ref), path(ref_fai), path(ref_gzi),
        path(bam), path(bai), path(mask), path(mask_tbi), val(chr), val(db_ready)

    output:
    tuple val(sample), path("*.vcf.gz"),          emit: vcf, optional: true
    tuple val(sample), path("*.csv"),             emit: csv, optional: true
    tuple val(sample), path("*.failed.txt"),      emit: failed, optional: true
    tuple val(sample), path("*.stats.txt"),       emit: stats, optional: true
    tuple val(sample), path("*.alignstats.txt"),  emit: alignstats, optional: true
    tuple val(sample), path("*.unresolvable.txt"),emit: unresolvable, optional: true

    script:
    def mem = task.memory.toGiga() + "gb"
    def name   = "${sample}.${chr}"
    def mask_command = params.full_genome ? "" : "-T <(zgrep -w ${chr} ${mask})"
    """
    set -x
    mkdir -p ${params.db_dir}                          

    twitcher vcf \
        ${vcf} \
        --reference ${ref} \
        --phasing-bam ${bam} \
        -r ${chr} $mask_command \
        --db ${params.db_dir}/known.${chr}.db \
        --cluster-strategy edit-mass \
        --memory-limit ${mem} \
        --threads ${task.cpus} \
        -o ${name}.vcf.gz \
        --only-realigned \
        --csv ${name}.csv \
        --output-failed-alignments ${name}.failed.txt \
        --stat-output ${name}.stats.txt \
        --output-alignment-stats ${name}.alignstats.txt \
        --output-unresolvable  ${name}.unresolvable.txt \
        --range-extension ${params.range_extension} \
        2>${name}.log || { echo "twitcher failed on ${chr}, see ${name}.log"; cat ${name}.log; exit 1; }
    if [ \$(wc -l < ${name}.csv) -le 1 ]; then
        rm ${name}.csv ${name}.failed.txt ${name}.stats.txt ${name}.alignstats.txt ${name}.unresolvable.txt
    fi
    """
}

process TWITCHER_VCF_PHASED {
    tag "${sample}:${chr}"
    label 'twitcher'

    publishDir "${params.outdir}/twitcher/${sample}/${chr}", mode: 'copy', saveAs: { filename ->
        file("${task.workDir}/${filename}").size() > 0 ? filename : null
    }
    
    input:
    tuple val(sample), path(vcf), path(tbi), path(ref), path(ref_fai), path(ref_gzi),
        path(mask), path(mask_tbi), val(chr), val(db_ready)

    output:
    tuple val(sample), path("*.vcf.gz"),          emit: vcf, optional: true
    tuple val(sample), path("*.csv"),             emit: csv, optional: true
    tuple val(sample), path("*.failed.txt"),      emit: failed, optional: true
    tuple val(sample), path("*.stats.txt"),       emit: stats, optional: true
    tuple val(sample), path("*.alignstats.txt"),  emit: alignstats, optional: true
    tuple val(sample), path("*.unresolvable.txt"),emit: unresolvable, optional: true

    script:
    def mem = task.memory.toGiga() + "gb"
    def name   = "${sample}.${chr}"
    def mask_command = params.full_genome ? "" : "-T <(zgrep -w ${chr} ${mask})"
    """
    set -x
    mkdir -p ${params.db_dir}                          

    twitcher vcf \
        ${vcf} \
        --reference ${ref} \
        -r ${chr} $mask_command \
        --db ${params.db_dir}/known.${chr}.db \
        --cluster-strategy edit-mass \
        --memory-limit ${mem} \
        --threads ${task.cpus} \
        -o ${name}.vcf.gz \
        --only-realigned \
        --csv ${name}.csv \
        --output-failed-alignments ${name}.failed.txt \
        --stat-output ${name}.stats.txt \   
        --output-alignment-stats ${name}.alignstats.txt \
        --output-unresolvable  ${name}.unresolvable.txt \
        --range-extension ${params.range_extension} \
        2>${name}.log || { echo "twitcher failed on ${chr}, see ${name}.log"; cat ${name}.log; exit 1; }
    if [ \$(wc -l < ${name}.csv) -le 1 ]; then
        rm ${name}.csv ${name}.failed.txt ${name}.stats.txt ${name}.alignstats.txt ${name}.unresolvable.txt
    fi
    """
}