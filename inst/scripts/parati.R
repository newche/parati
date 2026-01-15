library(optparse)

option_list <- list(
  make_option(c("-g","--geno"), type="character", help="Genotype VCF file (.vcf.gz) [required]"),
  make_option(c("-f","--family"), type="character", help="Family info XLSX [required]"),
  make_option(c("-o","--out"), type="character", help="Output directory [required]"),
  make_option(c("-c","--chr"), type="integer", help="Chromosome number [required]"),
  make_option(c("-l","--haplen"), type="integer", default=500000, help="Haplotype window length [default:500000]"),
  make_option(c("-s","--savetemp"), type="logical", default=FALSE, help="Save temp directories"),
  make_option(c("-b","--makebed"), type="logical", default=FALSE, help="Export PLINK bed"),
  make_option(c("--plink_path"), type="character", default="plink", help="Full path to plink executable [required]")
)

opt <- parse_args(OptionParser(option_list = option_list))

library(parati)

parati_run(
  geno_file = opt$geno,
  fam_file  = opt$family,
  out_dir   = opt$out,
  chr       = opt$chr,
  hap_length= opt$haplen,
  plink_path= if(opt$makebed) opt$plink_path else NULL,
  write_files=TRUE
)
