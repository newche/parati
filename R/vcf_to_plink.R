# R/vcf_to_plink.R
#' Export VCF to PLINK
#'
#' Converts transmitted and non-transmitted VCF objects into PLINK format files.
#'
#' @title Export VCF to PLINK
#' @param vcf_trans vcfR object of transmitted alleles
#' @param vcf_nontrans vcfR object of non-transmitted alleles
#' @param out_dir character, output directory path
#' @param chr chromosome identifier
#' @param plink_path character, path to PLINK executable
#' @return NULL
#' @export
vcf_to_plink <- function(vcf_trans, vcf_nontrans, out_dir, chr, plink_path) {
  message("vcf_to_plink not implemented yet")
  invisible(NULL)
}
