/*
 * Download GA4GH genome stratification file with its TBI indexes.
 */

process DOWNLOAD_STRATIFICATION {
    label 'download'

    storeDir "${projectDir}/ref/stratifications/${params.ref_version}"

    output:
    path "notdifficult.bed.gz",      emit: bed
    path "notdifficult.bed.gz.tbi",  emit: bed_tbi

    script:

    """
    curl -fsSL -o notdifficult.bed.gz     ${params.stratif_url}
    curl -fsSL -o notdifficult.bed.gz.tbi ${params.stratif_url}.tbi
    """
}
