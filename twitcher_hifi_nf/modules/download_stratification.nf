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
    //def bed_url     = "https://twitcher.it.helsinki.fi/data/hg38/GRCh38_notinalldifficultregions.bed.gz"
    def bed_url     = "https://twitcher.it.helsinki.fi/data/hg38/GRCh38_notgenenotdifficult.bed.gz"

    """
    curl -fsSL -o notdifficult.bed.gz     ${bed_url}
    curl -fsSL -o notdifficult.bed.gz.tbi ${bed_url}.tbi
    """
}
