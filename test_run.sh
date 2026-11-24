########

mkdir twitcher_asm_nf/data
cd twitcher_asm_nf/data/

wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/dipcall_output/GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap1.bam
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/dipcall_output/GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap1.bam.bai
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/dipcall_output/GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap2.bam
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/dipcall_output/GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap2.bam.bai

samtools merge -o GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.haps.bam GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap1.bam GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.hap2.bam -Obam
samtools index GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.haps.bam  

cd ../

bam=data/GRCh38_HG2-T2TQ100-V1.1_dipcall-z2k.haps.bam

nextflow run main.nf --bam $bam --prefix HG002.asm_bam

cd ../

########

mkdir twitcher_vcf_nf/data
cd twitcher_vcf_nf/data/

wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/GRCh38_HG2-T2TQ100-V1.1_smvar.vcf.gz 
wget https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/NIST_HG002_DraftBenchmark_defrabbV0.020-20250117/GRCh38_HG2-T2TQ100-V1.1_smvar.vcf.gz.tbi

samtools view -h https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG002_NA24385_son/PacBio_HiFi-Revio_20231031/HG002_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam chr1 -Obam -o data/HG002_PacBio-HiFi-Revio_chr1.bam
samtools index data/HG002_PacBio-HiFi-Revio_chr1.bam

bcftools view -r chr1 https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/analysis/PacBio_HiFi-Revio_20231031/pacbio-wgs-wdl_germline_20231031/HG002.GRCh38.deepvariant.phased.vcf.gz -Oz -o data/HG002.GRCh38.deepvariant.phased.chr1.vcf.gz
bcftools index data/HG002.GRCh38.deepvariant.phased.chr1.vcf.gz

cd ../

vcf=data/GRCh38_HG2-T2TQ100-V1.1_smvar.vcf.gz

nextflow run main.nf  --vcf $vcf --prefix HG002.benchmark_vcf

vcf=data/HG002.GRCh38.deepvariant.phased.chr1.vcf.gz
bam=data/HG002_PacBio-HiFi-Revio_chr1.bam

nextflow run main.nf  --vcf $vcf --bam $bam --prefix HG002.hifi_vcf

cd ../

########

mkdir twitcher_hifi_nf/data
cd twitcher_hifi_nf/data/

samtools view -h https://ftp-trace.ncbi.nlm.nih.gov/ReferenceSamples/giab/data/AshkenazimTrio/HG002_NA24385_son/PacBio_HiFi-Revio_20231031/HG002_PacBio-HiFi-Revio_20231031_48x_GRCh38-GIABv3.bam chr1 -Obam -o data/HG002_PacBio-HiFi-Revio_chr1.bam
samtools index data/HG002_PacBio-HiFi-Revio_chr1.bam

cd ../

bam=data/HG002_PacBio-HiFi-Revio_chr1.bam

nextflow run main.nf --bam $bam --prefix HG002.hifi_bam

cd ../

########

