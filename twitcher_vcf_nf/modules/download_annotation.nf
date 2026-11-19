/*
 * Download GFF3 annotation file with its TBI index.
 */

process DOWNLOAD_ANNOTATION {
    label 'download'

    storeDir "${projectDir}/ref/annotations/${params.ref_version}"

    output:
    path "annotation.gff3.gz",      emit: gff
    path "annotation.gff3.gz.tbi",  emit: gff_tbi

    script:
    def gff_url     = "https://twitcher.it.helsinki.fi/data/hg38/Homo_sapiens.GRCh38.115.ucsc.sorted.gff3.gz"
    """
    curl -fsSL -o annotation.gff3.gz      ${gff_url}
    curl -fsSL -o annotation.gff3.gz.tbi  ${gff_url}.tbi
    """
}