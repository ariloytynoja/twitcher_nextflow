/*
 * Download GFF3 masking file with its TBI index.
 */

process DOWNLOAD_REPEATMASK {
    label 'download'

    storeDir "${projectDir}/ref/masks/${params.ref_version}"

    output:
    path "masking.gff3.gz",     emit: masking
    path "masking.gff3.gz.tbi", emit: masking_tbi

    script:
    def src      = params.masking_url
    def is_local = !src.startsWith("http://") && !src.startsWith("https://")
    """
    if ${is_local}; then
        cp ${src}     masking.gff3.gz
        cp ${src}.tbi masking.gff3.gz.tbi
    else
        curl -fsSL -o masking.gff3.gz     ${src}
        curl -fsSL -o masking.gff3.gz.tbi ${src}.tbi
    fi
    """
}