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
    def src = params.annotat_url
    def is_local = !src.startsWith("http://") && !src.startsWith("https://")
    """
    if ${is_local}; then
        cp ${src}     annotation.gff3.gz
        cp ${src}.tbi annotation.gff3.gz.tbi
    else
        curl -fsSL -o annotation.gff3.gz     ${src}
        curl -fsSL -o annotation.gff3.gz.tbi ${src}.tbi
    fi
    """
}