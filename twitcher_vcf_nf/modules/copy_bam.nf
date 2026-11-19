/*
 * Download BAM and its index for TWB.
 */

process COPY_BAM {
    label 'download'

    storeDir "${projectDir}/results/alignments"

    input:
    tuple val(sample), path(bam), path(bai)

    output:
    tuple val(sample), path("${sample}.bam"), emit: bam
    tuple val(sample), path("${sample}.bam.bai"), emit: bai

    script:
    """
    cp ${bam} ${sample}.bam
    cp ${bai} ${sample}.bam.bai
    """
}