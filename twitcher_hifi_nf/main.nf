#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
params.bam       = null                 // path to pre-aligned BAM
params.bai       = "${params.bam}.bai"  // path to BAM index; inferred from bam if null
params.outdir    = "results"
params.ref_url   = "https://twitcher.it.helsinki.fi/data/hg38/hg38.no_alt.fa.gz"
params.ref_fai   = "${params.ref_url}.fai"
params.ref_gzi   = "${params.ref_url}.gzi"

// ---------------------------------------------------------------------------
// Validate required inputs
// ---------------------------------------------------------------------------
if (!params.bam) {
    error "ERROR: Please supply --bam <path/to/file.bam>"
}

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------
include { DOWNLOAD_REFERENCE      } from './modules/download_reference'
include { DOWNLOAD_STRATIFICATION } from './modules/download_stratification'
include { DOWNLOAD_DATABASE       } from './modules/download_database'
include { SAMTOOLS_INDEX          } from './modules/samtools_index'
include { TWITCHER_BAM            } from './modules/twitcher_bam'
include { DOWNLOAD_ANNOTATION     } from './modules/download_annotation'
include { DOWNLOAD_REPEATMASK     } from './modules/download_repeatmask'
include { TWB_PROCESS             } from './modules/twb_process'
include { TWB_FILTER              } from './modules/twb_filter'
include { COPY_BAM                } from './modules/copy_bam'

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

    // Download precomputed db-files for faster analysis
    if (params.download_db) {
        DOWNLOAD_DATABASE()
    }

    // Analyse pre-aligned BAM 
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

    // Analyse only the chromosome defined or the set of full chromosomes
    chromosomes_ch = params.chrom ?
        Channel.of(params.chrom) :
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

    // Copy BAMs such that TWB will see them.
    if(params.copy_bam) {
        COPY_BAM(
            samplename_ch
            .combine(bam_bai_ch)
            .map { sample, bam, bai -> tuple(sample, bam, bai) }
        )
    }
}