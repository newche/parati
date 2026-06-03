## ----eval=FALSE---------------------------------------------------------------
# if (!requireNamespace("BiocManager", quietly = TRUE)) {
#     install.packages("BiocManager")
# }
# BiocManager::install("parati")

## -----------------------------------------------------------------------------
library(parati)
library(VariantAnnotation)

vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")

## -----------------------------------------------------------------------------
res <- parati_run(
  vcf = vcf_file,
  fam = fam_file,
  chr = 1,
  hap_length = 500000
)

names(res)

## -----------------------------------------------------------------------------
head(res$vcf_trans, 3)
head(res$vcf_nontrans, 3)
head(res$sim_perc_summary, 3)


## ----eval=FALSE---------------------------------------------------------------
# library(vcfR)
# 
# # 1. Save tabular outputs
# data.table::fwrite(res$vcf_trans, "transmitted_chr1.csv.gz")
# data.table::fwrite(res$vcf_nontrans, "nontransmitted_chr1.csv.gz")
# data.table::fwrite(res$sim_perc_summary, "sim_perc_summary_chr1.csv.gz")
# 
# # 2. Read original VCF metadata
# orig_vcf <- vcfR::read.vcfR(vcf_file, verbose = FALSE)
# meta_lines <- orig_vcf@meta
# 
# # 3. Convert returned data.tables to standard VCF objects
# trans_obj <- vcf_dt_to_vcfR(res$vcf_trans, meta = meta_lines)
# nontrans_obj <- vcf_dt_to_vcfR(res$vcf_nontrans, meta = meta_lines)
# 
# # 4. Write standard gzipped VCF files
# write_vcf_obj(trans_obj, "transmitted_chr1.vcf.gz")
# write_vcf_obj(nontrans_obj, "nontransmitted_chr1.vcf.gz")

## ----eval=FALSE---------------------------------------------------------------
# vcf_obj <- readVcf(vcf_file, genome = "unknown")
# 
# res_from_vcf <- parati_run(
#   vcf = vcf_obj,
#   fam = fam_file,
#   chr = 1,
#   hap_length = 500000
# )
# 
# names(res_from_vcf)

## -----------------------------------------------------------------------------
sessionInfo()

