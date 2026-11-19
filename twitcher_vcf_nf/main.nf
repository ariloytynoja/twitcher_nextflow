#!/usr/bin/env nextflow
nextflow.enable.dsl=2

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
params.vcf       = null                 // path to local vcf.gz data
params.tbi       = "${params.vcf}.tbi"  // path to index; computed if null
params.bam       = null                 // path to phasing BAM
params.bai       = "${params.bam}.bai"  // path to index; computed if null
params.outdir    = "results"
params.ref_url   = "https://twitcher.it.helsinki.fi/data/hg38/hg38.no_alt.fa.gz"
params.ref_fai   = "${params.ref_url}.fai"
params.ref_gzi   = "${params.ref_url}.gzi"

// ---------------------------------------------------------------------------
// Validate required inputs
// ---------------------------------------------------------------------------
if (!params.vcf) {
    error "ERROR: Please supply --vcf <path/to/calls.vcf.gz>"
}

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------
include { DOWNLOAD_REFERENCE      } from './modules/download_reference'
include { DOWNLOAD_STRATIFICATION } from './modules/download_stratification'
include { DOWNLOAD_DATABASE       } from './modules/download_database'
include { BCFTOOLS_INDEX          } from './modules/bcftools_index'
include { SAMTOOLS_INDEX          } from './modules/samtools_index'
include { TWITCHER_VCF            } from './modules/twitcher_vcf'
include { TWITCHER_VCF_PHASED     } from './modules/twitcher_vcf'
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

    if (params.bam) {
        // Use pre-aligned BAM for phasing
        bam_ch = Channel.fromPath(params.bam, checkIfExists: true)

        def bai_path = params.bai ?
            file(params.bai) :
            file("${params.bam}.bai")

        if (bai_path.exists()) {
            bai_ch = Channel.fromPath(bai_path)
        } else {
            SAMTOOLS_INDEX(bam_ch)
            bai_ch = SAMTOOLS_INDEX.out.bai
        }
    } 
    
    // VCF file for analysis
    vcf_ch = Channel.fromPath(params.vcf)

    // Assuming vcf.gz suffix
    samplename_ch = vcf_ch.map { vcf ->
        params.prefix != "latest" ? params.prefix :
            vcf.name.replaceAll(/\.(vcf\.gz|vcf|bcf\.gz|bcf)$/, '')
    }
 
    def tbi_path = params.tbi ? 
        file(params.tbi) : 
        file("${params.vcf}.tbi")

    if (tbi_path.exists()) {
        tbi_ch = Channel.fromPath(tbi_path)
    } else {
        BCFTOOLS_INDEX(vcf_ch)
        tbi_ch = BCFTOOLS_INDEX.out.tbi
    }
 
     // Build optional BAM channel for unphased data
    if (params.bam) {
        bam_bai_ch = bam_ch.combine(bai_ch)
    } 


    // Analyse only the full chromosomes
    chromosomes_ch = Channel.of(
        'chr1',  'chr2',  'chr3',  'chr4',  'chr5',  'chr6',
        'chr7',  'chr8',  'chr9',  'chr10', 'chr11', 'chr12',
        'chr13', 'chr14', 'chr15', 'chr16', 'chr17', 'chr18',
        'chr19', 'chr20', 'chr21', 'chr22', 'chrX'
    )

    if (params.bam) {

        // Build twitcher input channel from phasing
        twitcher_input_ch = samplename_ch
            .combine(vcf_ch)
            .combine(tbi_ch)
            .combine(DOWNLOAD_REFERENCE.out.ref_fa)
            .combine(DOWNLOAD_REFERENCE.out.ref_fai)
            .combine(DOWNLOAD_REFERENCE.out.ref_gzi)
            .combine(bam_bai_ch)
            .combine(DOWNLOAD_STRATIFICATION.out.bed)
            .combine(DOWNLOAD_STRATIFICATION.out.bed_tbi)
            .combine(chromosomes_ch)
            .combine(DOWNLOAD_DATABASE.out.done)
            
        TWITCHER_VCF(twitcher_input_ch)
        csv_ch = TWITCHER_VCF.out.csv

    } else {

        // Build twitcher input channel from phased data
        twitcher_input_ch = samplename_ch
            .combine(vcf_ch)
            .combine(tbi_ch)
            .combine(DOWNLOAD_REFERENCE.out.ref_fa)
            .combine(DOWNLOAD_REFERENCE.out.ref_fai)
            .combine(DOWNLOAD_REFERENCE.out.ref_gzi)
            .combine(DOWNLOAD_STRATIFICATION.out.bed)
            .combine(DOWNLOAD_STRATIFICATION.out.bed_tbi)
            .combine(chromosomes_ch)
            .combine(DOWNLOAD_DATABASE.out.done)
            
        TWITCHER_VCF_PHASED(twitcher_input_ch)
        csv_ch = TWITCHER_VCF_PHASED.out.csv

    }

    // Download annotation files
    DOWNLOAD_ANNOTATION()
    DOWNLOAD_REPEATMASK()

    // Split per-chromosome CSVs into individual tuples
    twitcher_csv_ch = csv_ch
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
    if(params.bam && params.copy_bam) {
        COPY_BAM(
            samplename_ch
            .combine(bam_bai_ch)
            .map { sample, bam, bai -> tuple(sample, bam, bai) }
        )
    }
}