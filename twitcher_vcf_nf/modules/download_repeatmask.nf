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
    """
    curl -fsSL -o masking.gff3.gz         ${params.masking_url}
    curl -fsSL -o masking.gff3.gz.tbi     ${params.masking_url}.tbi
    """
}