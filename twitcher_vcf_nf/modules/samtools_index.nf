/*
 * Index a BAM file with samtools.
 */

process SAMTOOLS_INDEX {
    tag "${bam.simpleName}"
    label 'low_mem'

    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    path bam

    output:
    path "${bam}.bai", emit: bai

    script:
    """
    samtools index -@ ${task.cpus} ${bam}
    """
}
