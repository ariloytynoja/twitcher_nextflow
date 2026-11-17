#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
params.assembly  = null          // path to local fa.gz assembly; required unless --bam is set
params.bam       = null          // path to pre-aligned BAM; skips alignment if provided
params.bai       = null          // path to BAM index; inferred from bam if null
params.outdir    = "results"
params.ref_url   = "https://twitcher.it.helsinki.fi/data/hg38/hg38.no_alt.fa.gz"
params.ref_fai   = "${params.ref_url}.fai"
params.ref_gzi   = "${params.ref_url}.gzi"
params.kmer_size = 15
params.kmer_distinct_threshold = 0.9998

// ---------------------------------------------------------------------------
// Validate required inputs
// ---------------------------------------------------------------------------
if (!params.assembly && !params.bam) {
    error "ERROR: Please supply either --assembly <path/to/assembly.fa.gz> or --bam <path/to/file.bam>"
}

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------
include { DOWNLOAD_REFERENCE      } from './modules/download_reference'
include { DOWNLOAD_STRATIFICATION } from './modules/download_stratification'
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

    // Download reference + index files
    DOWNLOAD_REFERENCE(
        params.ref_url,
        params.ref_fai,
        params.ref_gzi
    )

    // Download genome stratification mask
    DOWNLOAD_STRATIFICATION()

    if (params.bam) {
        // Use pre-aligned BAM — skip assembly alignment entirely
        bam_ch = Channel.fromPath(params.bam, checkIfExists: true)
        if (params.bai) {
            bai_ch = Channel.fromPath(params.bai, checkIfExists: true)
        } else {
            SAMTOOLS_INDEX(bam_ch)
            bai_ch = SAMTOOLS_INDEX.out.bai
        }

    } else {
        // Align assembly to reference
        assembly_ch = Channel.fromPath(params.assembly, checkIfExists: true)

        if (params.aligner == 'winnowmap') {
            MERYL_COUNT(DOWNLOAD_REFERENCE.out.ref_fa, params.kmer_size)
            MERYL_REPETITIVE(MERYL_COUNT.out.merylDB, params.kmer_distinct_threshold)
            WINNOWMAP_ALIGN(
                assembly_ch,
                DOWNLOAD_REFERENCE.out.ref_fa,
                MERYL_REPETITIVE.out.repetitive_kmers
            )
            bam_ch = WINNOWMAP_ALIGN.out.bam

        } else if (params.aligner == 'minimap2') {
            MINIMAP2_ALIGN(
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

    // Analyse only the full chromosomes
    chromosomes_ch = Channel.of(
        'chr1',  'chr2',  'chr3',  'chr4',  'chr5',  'chr6',
        'chr7',  'chr8',  'chr9',  'chr10', 'chr11', 'chr12',
        'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18',
        'chr19', 'chr20', 'chr21', 'chr22', 'chrX'
    )

    // Build twitcher input channel from bam + bai (however they were obtained)
    twitcher_input_ch = bam_ch
        .combine(bai_ch)
        .map { bam, bai -> tuple(bam.getBaseName(1), bam, bai) }
        .combine(DOWNLOAD_REFERENCE.out.ref_fa)
        .combine(DOWNLOAD_REFERENCE.out.ref_fai)
        .combine(DOWNLOAD_REFERENCE.out.ref_gzi)
        .combine(DOWNLOAD_STRATIFICATION.out.bed)
        .combine(DOWNLOAD_STRATIFICATION.out.bed_tbi)
        .combine(chromosomes_ch)

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