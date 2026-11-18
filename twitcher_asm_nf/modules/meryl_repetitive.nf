/*
 * Extract repetitive kmers (those above the distinct frequency threshold)
 * from the meryl database. The output text file is passed to winnowmap.
 */

process MERYL_REPETITIVE {
    label 'low_mem'

    storeDir "${projectDir}/ref/meryl"

    input:
    path merylDB
    val  distinct_threshold

    output:
    path "repetitive_k15.txt", emit: repetitive_kmers

    script:
    """
    meryl print greater-than distinct=${distinct_threshold} ${merylDB} > repetitive_k15.txt
    """
}
