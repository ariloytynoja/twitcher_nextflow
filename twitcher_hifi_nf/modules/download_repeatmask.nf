/*
 * Download GFF3 masking file with its TBI index.
 */

process DOWNLOAD_REPEATMASK {
    label 'download'

    storeDir "${projectDir}/ref/masks/${params.ref_version}"

    output:
    path "masking.gff3.gz",         emit: masking
    path "masking.gff3.gz.tbi",     emit: masking_tbi

    script:
    def masking_url = "https://twitcher.it.helsinki.fi/data/hg38/hg38.no_alt.masking.sorted.gff3.gz"
    """
    curl -fsSL -o masking.gff3.gz         ${masking_url}
    curl -fsSL -o masking.gff3.gz.tbi     ${masking_url}.tbi
    """
}