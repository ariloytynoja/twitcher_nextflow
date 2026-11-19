/*
 * Align a genome assembly against the reference using winnowmap,
 * then pipe directly into samtools to produce a BAM file.
 * Both winnowmap and samtools are available in the same container.
 */

process WINNOWMAP_ALIGN {
    tag "${assembly.simpleName}"
    label 'winnowmap'

    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    val sample
    path assembly
    path ref_fa
    path repetitive_kmers

    output:
    path "*.bam", emit: bam

    script:
    def wm_cpus = Math.max(1, Math.floor(task.cpus / 2).toInteger())
    """
    winnowmap \
        -R '@RG\\tID:$sample\\tSM:$sample' \
        --MD \
        -W ${repetitive_kmers} \
        -k ${params.kmer_size} \
        -ax map-pb \
        --sv-off \
        -t ${wm_cpus} \
        ${ref_fa} \
        ${assembly} \
    | samtools sort \
        -O BAM \
        -o ${sample}.bam \
        -T ${sample}.sort \
        --threads ${wm_cpus} -
    """
}
