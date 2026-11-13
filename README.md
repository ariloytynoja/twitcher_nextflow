# Nextflow pipelines for Twitcher analyses

Twitcher and Twitcher Workbench are tools for identification and annotation of mutation clusters created by short-range template switching.
Find more information about the tools at [https://twitcher.it.helsinki.fi](https://twitcher.it.helsinki.fi). 

This repository contains Nextlow pipelines for typical analyses.

## Analysis of de novo genome assemblies 

The pipeline `twitcher_asm_nf` aligns a genome assembly against a reference using `minimap2` and then runs `twitcher` on the resulting BAM files. The CSV output files are processed and filtered with `twb cli`.

The pipeline is designed for human data and GRCh38. Analyses with any other reference require building the matching annotation files for `twb cli` (explained on the website) or disabling the gene and repeat annotation. `winnowmap` is provided as an alternative aligner but it appears to require lots more RAM.

Note that the pipeline defines `--db` as a shared resource. This speeds up subsequent analyses as mutation clusters segregating among individuals are resolved without re-alignment. Twitcher should allow *some* multiple parallel instances to read and write the database, but starting too many parallel runs (e.g., for tens of individuals) may cause errors.

An example command:
```
nextflow run main.nf --assembly data/NA12878.verkko_asm.fa.gz --prefix NA12878.verkko_asm
```

The default settings (in `nextflow.config`) were used on a SLURM system with options:

```
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=20
#SBATCH --mem=80G
```

This (and possibly less) was sufficient for an analysis of a human sample using `minimap2` as the aligner, but run out of memory with `winnowmap`. Providing 4GB per Twitcher thread (e.g., 20 CPUs and 80GB, or 10 CPUs and 40GB) will fail with OOM on low-complexity regions but should succeed in typical genic regions. 

By default, the analysis is performed for the [GIAB "easy regions"](https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/genome-stratifications/v2.0/GRCh38/union/GRCh38_notinalldifficultregions.bed.gz) that make 74.4% of the genome. See the [README file](https://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/genome-stratifications/v2.0/GRCh38/union/v2.0-GRCh38-Union-README.txt) for the description.

The expected timeline of an analysis may look like this:
![Nextflow timeline](twitcher_asm_nf/misc/twitcher_bam_timeline_NA12877.png)
and the Twitcher part is expected to get increasingly fast as an ever greater proportion of the segregating mutations are stored in the DB. 
