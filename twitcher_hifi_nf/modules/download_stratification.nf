/*
 * Download GA4GH genome stratification file with its TBI indexes.
 */

process DOWNLOAD_STRATIFICATION {
    label 'download'

    storeDir "${projectDir}/ref/stratifications/${params.ref_version}"

    output:
    path "notdifficult.bed.gz",     emit: bed
    path "notdifficult.bed.gz.tbi", emit: bed_tbi

    script:
    def src      = params.stratif_url
    def is_local = !src.startsWith("http://") && !src.startsWith("https://")
    """
    if ${is_local}; then
        cp ${src}     notdifficult.bed.gz
        cp ${src}.tbi notdifficult.bed.gz.tbi
    else
        curl -fsSL -o notdifficult.bed.gz     ${src}
        curl -fsSL -o notdifficult.bed.gz.tbi ${src}.tbi
    fi
    """
}