/*
 * Download the hg38 no-ALT reference genome and its index files.
 * Uses curl (available in the winnowmap container) so no extra container
 * is needed. The .fai and .gzi sidecars are downloaded alongside.
 */

process DOWNLOAD_REFERENCE {
    label 'download'

    storeDir "${projectDir}/reference/genome"

    input:
    val ref_url
    val ref_fai_url
    val ref_gzi_url

    output:
    path "*.fa.gz",  emit: ref_fa
    path "*.fa.gz.fai", emit: ref_fai
    path "*.fa.gz.gzi", emit: ref_gzi

    script:
    """
    curl -fsSL -o ref.fa.gz      ${ref_url}
    curl -fsSL -o ref.fa.gz.fai  ${ref_fai_url}
    curl -fsSL -o ref.fa.gz.gzi  ${ref_gzi_url}
    """
}