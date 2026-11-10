process MINIMAP2_ALIGN {
    tag "${assembly.simpleName}"
    label 'winnowmap'

    publishDir "${params.outdir}/alignments", mode: 'copy'

    input:
    path assembly
    path ref_fa
 
    output:
    path "${assembly.simpleName}.bam", emit: bam

    script:
    def sample  = assembly.simpleName
    def mm_cpus = Math.max(1, Math.floor(task.cpus / 2).toInteger())
    """
    minimap2 \
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