/*
 * Download TSM-database files for faster analysis.
 */

process DOWNLOAD_DATABASE {
    label 'download'

    storeDir "${params.db_dir}"

    output:
    path "known.chr*.db",      emit: dbs
    val true,                  emit: done

    script:
    def src      = params.db_url
    def is_local = !src.startsWith("http://") && !src.startsWith("https://")
    def regex    = /(?<=twitcher )\d+\.\d+/
    """
    str=\$(twitcher --version)
    version=\$(echo "\$str" | grep -oP '${regex}')

    if ${is_local}; then
        tarball=\$(ls ${src}/tsm_db_\${version}.tgz 2>/dev/null)
        if [ -n "\$tarball" ] && [ -s "\$tarball" ]; then
            echo "Copying DB from \$tarball"
            tar xzf "\$tarball"
        else
            echo "No DB found at ${src}/tsm_db_\${version}.tgz"
            exit 1
        fi
    else
        url=${src}/tsm_db_\${version}.tgz
        outfile="tsm_db.tgz"
        if curl --silent --fail -L -o "\$outfile" "\$url" && [ -s "\$outfile" ]; then
            echo "Using DB from \$url"
            tar xzf "\$outfile"
        else
            echo "Download from \$url failed"
            exit 1
        fi
    fi
    """
}