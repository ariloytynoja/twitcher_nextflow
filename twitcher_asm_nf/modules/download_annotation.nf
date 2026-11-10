/*
 * Download GFF3 annotation and masking files with their TBI indexes.
 */

process DOWNLOAD_ANNOTATION {
    label 'download'

    storeDir "${projectDir}/reference/annotation"

    output:
    path "annotation.gff3.gz",      emit: gff
    path "annotation.gff3.gz.tbi",  emit: gff_tbi
    path "masking.gff3.gz",         emit: masking
    path "masking.gff3.gz.tbi",     emit: masking_tbi

    script:
    def gff_url     = "https://twitcher.it.helsinki.fi/data/hg38/Homo_sapiens.GRCh38.115.ucsc.sorted.gff3.gz"
    def masking_url = "https://twitcher.it.helsinki.fi/data/hg38/hg38.no_alt.masking.sorted.gff3.gz"
    """
    curl -fsSL -o annotation.gff3.gz      ${gff_url}
    curl -fsSL -o annotation.gff3.gz.tbi  ${gff_url}.tbi
    curl -fsSL -o masking.gff3.gz         ${masking_url}
    curl -fsSL -o masking.gff3.gz.tbi     ${masking_url}.tbi
    """
}