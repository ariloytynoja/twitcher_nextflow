/*
 * Download the hg38 no-ALT reference genome and its index files.
 */

process DOWNLOAD_REFERENCE {
    label 'download'

    storeDir "${projectDir}/ref/genomes/${params.ref_version}"

    input:
    val ref_url
    val ref_fai_url
    val ref_gzi_url

    output:
    path "ref.fa.gz",     emit: ref_fa
    path "ref.fa.gz.fai", emit: ref_fai
    path "ref.fa.gz.gzi", emit: ref_gzi

    script:
    def is_local = !ref_url.startsWith("http://") && !ref_url.startsWith("https://")
    """
    if ${is_local}; then
        cp ${ref_url}     ref.fa.gz
        cp ${ref_fai_url} ref.fa.gz.fai
        cp ${ref_gzi_url} ref.fa.gz.gzi
    else
        curl -fsSL -o ref.fa.gz     ${ref_url}
        curl -fsSL -o ref.fa.gz.fai ${ref_fai_url}
        curl -fsSL -o ref.fa.gz.gzi ${ref_gzi_url}
    fi
    """
}