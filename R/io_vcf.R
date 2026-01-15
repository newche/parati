#' Read VCF by chromosome
#' @param vcf_file character VCF file path
#' @param chr character/integer Chromosome
#' @return data.table
read_vcf_by_chr <- function(vcf_file, chr) {
  requireNamespace("data.table")
  message("Reading VCF: ", vcf_file)
  vcf_all <- data.table::fread(vcf_file)
  data.table::setnames(vcf_all, "#CHROM", "CHROM")
  vcf_chr <- vcf_all[CHROM == chr]
  data.table::setnames(vcf_chr, "CHROM", "#CHROM")
  return(vcf_chr)
}

#' Write data.table to VCF
#' @param df data.table
#' @param file output file path
write_vcf_dt <- function(df, file) {
  requireNamespace("data.table")
  if (grepl("\\.gz$", file)) {
    data.table::fwrite(df, file=gzfile(file), sep="\t", quote=FALSE)
  } else {
    data.table::fwrite(df, file=file, sep="\t", quote=FALSE)
  }
}

#' Convert data.table to vcfR object
vcf_dt_to_vcfR <- function(df, meta) {
  requireNamespace("vcfR")
  fix_mat <- as.matrix(df[, 1:8])
  gt_mat <- as.matrix(df[, 9:ncol(df)])
  methods::new("vcfR", meta=meta, fix=fix_mat, gt=gt_mat)
}

#' Write vcfR object to file
write_vcf_obj <- function(vcf_obj, file) {
  requireNamespace("vcfR")
  vcfR::write.vcf(vcf_obj, file=file)
}
