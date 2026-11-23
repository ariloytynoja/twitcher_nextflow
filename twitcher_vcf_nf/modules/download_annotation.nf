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
    """
    curl -fsSL -o annotation.gff3.gz      ${params.annotat_url}
    curl -fsSL -o annotation.gff3.gz.tbi  ${params.annotat_url}.tbi
    """
}