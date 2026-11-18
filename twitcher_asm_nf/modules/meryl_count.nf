/*
 * Build a meryl kmer database from the reference genome.
 * meryl is bundled inside the winnowmap container.
 */

process MERYL_COUNT {
    label 'high_mem'

    storeDir "${projectDir}/ref/meryl"

    input:
    path ref_fa
    val  kmer_size

    output:
    path "merylDB", emit: merylDB

    script:
    """
    meryl count k=${kmer_size} output merylDB ${ref_fa}
    """
}
