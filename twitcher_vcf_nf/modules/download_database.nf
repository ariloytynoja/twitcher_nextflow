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
    def regex  = /(?<=twitcher )\d+\.\d+/
    """
    str=\$(twitcher --version)
    version=\$(echo "\$str" | grep -oP '${regex}')
    url=${params.db_url}/tsm_db_\${version}.tgz
    outfile="tsm_db.tgz"

    if curl --silent --fail -L -o "\$outfile" "\$url" && [ -s "\$outfile" ]; then
        echo "Using DB from \$url"
        tar xzf \$outfile
    else
        echo "Download from \$url failed"
        exit 1
    fi
    #rm -f "\$outfile"
    """
}