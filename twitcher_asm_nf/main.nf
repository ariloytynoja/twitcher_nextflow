#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------
include { DOWNLOAD_REFERENCE      } from './modules/download_reference'
include { DOWNLOAD_STRATIFICATION } from './modules/download_stratification'
include { TWITCHER_VERSION        } from './modules/twitcher_version'
include { DOWNLOAD_DATABASE       } from './modules/download_database'
include { MERYL_COUNT             } from './modules/meryl_count'
include { MERYL_REPETITIVE        } from './modules/meryl_repetitive'
include { WINNOWMAP_ALIGN         } from './modules/winnowmap_align'
include { MINIMAP2_ALIGN          } from './modules/minimap2_align'
include { SAMTOOLS_INDEX          } from './modules/samtools_index'
include { TWITCHER_BAM            } from './modules/twitcher_bam'
include { DOWNLOAD_ANNOTATION     } from './modules/download_annotation'
include { DOWNLOAD_REPEATMASK     } from './modules/download_repeatmask'
include { TWB_PROCESS             } from './modules/twb_process'
include { TWB_FILTER              } from './modules/twb_filter'

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------
workflow {

    // ---------------------------------------------------------------------------
    // Validate required inputs
    // ---------------------------------------------------------------------------
    if (!params.assembly && !params.bam) {
        error "ERROR: Please supply either --assembly <path/to/assembly.fa.gz> or --bam <path/to/file.bam>"
    }

    // Download reference + index files
    DOWNLOAD_REFERENCE(
        params.ref_url,
        params.ref_fai,
        params.ref_gzi
    )

    // Download genome stratification mask
    DOWNLOAD_STRATIFICATION()

    // Get Twithcer version to get the right database
    TWITCHER_VERSION()

    // Download precomputed db-files for faster analysis
    if (params.download_db) {
        DOWNLOAD_DATABASE(TWITCHER_VERSION.out.version)
    }

    if (params.bam) {
        // Use pre-aligned BAM — skip assembly alignment entirely
        bam_ch = Channel.fromPath(params.bam, checkIfExists: true)
        if (params.bai) {
            bai_ch = Channel.fromPath(params.bai, checkIfExists: true)
        } else {
            SAMTOOLS_INDEX(bam_ch)
            bai_ch = SAMTOOLS_INDEX.out.bai
        }

        samplename_ch = bam_ch.map { bam ->
           params.prefix != "latest" ? params.prefix : bam.getBaseName(1)
        }
    } else {
        // Align assembly to reference
        assembly_ch = Channel.fromPath(params.assembly, checkIfExists: true)

        samplename_ch = assembly_ch.map { assembly ->
            params.prefix != "latest" ? params.prefix :
                assembly.name.replaceAll(/\.(fasta|fas|fa)(\.gz)?$/, '')
        }

        if (params.aligner == 'winnowmap') {
            MERYL_COUNT(DOWNLOAD_REFERENCE.out.ref_fa, params.kmer_size)
            MERYL_REPETITIVE(MERYL_COUNT.out.merylDB, params.kmer_distinct_threshold)
            WINNOWMAP_ALIGN(
                samplename_ch,
                assembly_ch,
                DOWNLOAD_REFERENCE.out.ref_fa,
                MERYL_REPETITIVE.out.repetitive_kmers
            )
            bam_ch = WINNOWMAP_ALIGN.out.bam

        } else if (params.aligner == 'minimap2') {
            MINIMAP2_ALIGN(
                samplename_ch,
                assembly_ch,    
                DOWNLOAD_REFERENCE.out.ref_fa
            )
            bam_ch = MINIMAP2_ALIGN.out.bam

        } else {
            error "Unknown aligner '${params.aligner}'. Choose 'winnowmap' or 'minimap2'."
        }

        SAMTOOLS_INDEX(bam_ch)
        bai_ch = SAMTOOLS_INDEX.out.bai
    }

    // Analyse only the chromosome defined or the set of full chromosomes
    chromosomes_ch = params.chrom ?
        Channel.of(params.chrom) :
        (params.chroms_file && new File(params.chroms_file).exists()) ?
        Channel.fromPath(params.chroms_file)
            .splitText()
            .map { it.trim() }
            .filter { it } :
        Channel.of(
            'chr1',  'chr2',  'chr3',  'chr4',  'chr5',  'chr6',
            'chr7',  'chr8',  'chr9',  'chr10', 'chr11', 'chr12',
            'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18',
            'chr19', 'chr20', 'chr21', 'chr22', 'chrX'
        )

    // Build twitcher input channel from bam + bai (however they were obtained)
    twitcher_input_ch = samplename_ch
        .combine(bam_ch)
        .combine(bai_ch)
        .combine(DOWNLOAD_REFERENCE.out.ref_fa)
        .combine(DOWNLOAD_REFERENCE.out.ref_fai)
        .combine(DOWNLOAD_REFERENCE.out.ref_gzi)
        .combine(DOWNLOAD_STRATIFICATION.out.bed)
        .combine(DOWNLOAD_STRATIFICATION.out.bed_tbi)
        .combine(chromosomes_ch)
        .combine(DOWNLOAD_DATABASE.out.done)

    TWITCHER_BAM(twitcher_input_ch)

    // Download annotation files
    DOWNLOAD_ANNOTATION()
    DOWNLOAD_REPEATMASK()

    // Split per-chromosome CSVs into individual tuples
    twitcher_csv_ch = TWITCHER_BAM.out.csv
        .transpose()

    // Post-process twitcher output one CSV at a time
    TWB_PROCESS(
        twitcher_csv_ch,
        DOWNLOAD_REFERENCE.out.ref_fa,
        DOWNLOAD_REFERENCE.out.ref_fai,
        DOWNLOAD_REFERENCE.out.ref_gzi,
        DOWNLOAD_ANNOTATION.out.gff,
        DOWNLOAD_ANNOTATION.out.gff_tbi,
        DOWNLOAD_REPEATMASK.out.masking,
        DOWNLOAD_REPEATMASK.out.masking_tbi
    )

    // Filter and concatenate processed CSVs
    TWB_FILTER(
        TWB_PROCESS.out.csv.groupTuple()
    )
}
