/*
 * Download GA4GH genome stratification file with its TBI indexes.
 */

process DOWNLOAD_GA4GH_MASK {
    label 'download'

    storeDir "${projectDir}/reference/annotation"

    output:
    path "notdifficult.bed.gz",      emit: bed
    path "notdifficult.bed.gz.tbi",  emit: bed_tbi

    script:
    def bed_url     = "https://twitcher.it.helsinki.fi/data/hg38/GRCh38_notinalldifficultregions.bed.gz"
    """
    curl -fsSL -o notdifficult.bed.gz     ${bed_url}
    curl -fsSL -o notdifficult.bed.gz.tbi ${bed_url}.tbi
    """
}