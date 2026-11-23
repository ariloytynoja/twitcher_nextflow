/*
 * Get the version number so that TSM-database download can be done wthout container. 
 */

process TWITCHER_VERSION {
    label 'low_mem'

    output:
    env version, emit: version

    script:
    def regex = /(?<=twitcher )\d+\.\d+/
    """
    str=\$(twitcher --version)
    version=\$(echo "\$str" | grep -oP '${regex}')
    """
}