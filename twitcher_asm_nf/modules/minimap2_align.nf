process MINIMAP2_ALIGN {
    tag "${assembly.simpleName}"
    label 'winnowmap'

    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    val sample
    path assembly
    path ref_fa
 
    output:
    path "*.bam", emit: bam

    script:
    def mm_cpus = Math.max(1, Math.floor(task.cpus / 2).toInteger())
    """
    minimap2 \
        -R '@RG\\tID:$sample\\tSM:$sample' \
        --MD \
        -ax asm5 \
        -t ${mm_cpus} \
        ${ref_fa} \
        ${assembly} \
    | samtools sort \
        -O BAM \
        -o ${sample}.bam \
        -T ${sample}.sort \
        --threads ${mm_cpus} -
    """
}