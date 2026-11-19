/*
 * Index a VCF file with bcftools.
 */
 
 process BCFTOOLS_INDEX {
    tag "${vcf.simpleName}"
    label 'low_mem'

    input:
    path vcf

    output:
    path "${vcf}.tbi", emit: tbi

    script:
    """
    bcftools index --tbi --threads ${task.cpus} ${vcf}
    """
}