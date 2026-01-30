# parati/R/parati_run.R
#' Run PARATI inference workflow
#'
#' Main function to run the haplotype inference workflow on a set of VCF and family files.
#'
#' @param geno_file Path to phased VCF file (`.vcf` or `.vcf.gz`).
#' @param fam_file Path to family index table (Excel `.xlsx` file).
#' @param out_dir Output directory where results will be saved.
#' @param chr Integer, chromosome number to process.
#' @param hap_length Integer, haplotype window length (default 500000).
#' @param plink_path Optional string. Path to PLINK executable for generating BED files.
#' @param write_files Logical, whether to write output VCFs to disk (default TRUE).
#' @importFrom data.table :=
#' @param df data.table containing VCF rows
#' @param meta list of meta information for VCF
#' @return A list containing:
#' \describe{
#'   \item{vcf_trans}{VCF with transmitted alleles annotated}
#'   \item{vcf_nontrans}{VCF with non-transmitted alleles annotated}
#'   \item{sim_perc_summary}{Summary of simulation results for all families}
#' }
#' @examples
#' \dontrun{
#' parati_run(
#'   geno_file = "Toy_TrioGenotype.vcf.gz",
#'   fam_file = "Toy_FamilyIndexTable.xlsx",
#'   out_dir = "output",
#'   chr = 1
#' )
#' }
#' @export
parati_run <- function(
  geno_file,
  fam_file,
  out_dir,
  chr,
  hap_length = 500000,
  plink_path = NULL,
  write_files = TRUE
) {
  requireNamespace("data.table")
  requireNamespace("openxlsx")

  # source("./parati/R/haplotype_infer.R")
  # source("./parati/R/io_vcf.R")

  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  fam_dt <- data.table::as.data.table(openxlsx::read.xlsx(fam_file))

  vcf_dt <- data.table::fread(geno_file)

  data.table::setnames(vcf_dt, "#CHROM", "CHROM")
  vcf_dt <- vcf_dt[CHROM == chr]
  data.table::setnames(vcf_dt, "CHROM", "#CHROM")

  info_cols <- names(vcf_dt)[seq_len(9)]

  vcf_trans <- vcf_dt[, ..info_cols]
  vcf_nontrans <- vcf_dt[, ..info_cols]

  sim_summary <- data.table::data.table()


  for (fid in unique(fam_dt$FamilyIndex)) {
    fam_sub <- fam_dt[FamilyIndex == fid]
    fam_sub[, Role_BMP := dplyr::case_when(
      Role == "C" ~ "B",
      Role == "M" ~ "M",
      Role == "F" ~ "P"
    )]

    iid <- fam_sub$IndividualID
    role <- fam_sub$Role_BMP

    vcf_sub <- vcf_dt[, c(info_cols, iid), with = FALSE]
    data.table::setnames(vcf_sub, iid, role)

    res <- haplotype_infer(
      vcf_dt = vcf_sub
    )

    # merge
    cols_to_merge <- c(info_cols, "M_transmitted", "P_transmitted")
    vcf_trans <- data.table::merge.data.table(
      vcf_trans[, ..info_cols],
      res$vcf_trans[, ..cols_to_merge],
      by = info_cols,
      all = TRUE
    )


    cols_to_merge_nontrans <- c(info_cols, "M_nontransmitted", "P_nontransmitted")
    vcf_nontrans <- data.table::merge.data.table(
      vcf_nontrans[, ..info_cols],
      res$vcf_nontrans[, ..cols_to_merge_nontrans],
      by = info_cols,
      all = TRUE
    )

    sim_summary <- data.table::rbindlist(list(sim_summary, res$sim), fill = TRUE)
  }

  if (write_files) {
    data.table::fwrite(vcf_trans, file.path(out_dir, paste0("trans_chr", chr, ".vcf")), sep = "\t")
    data.table::fwrite(vcf_nontrans, file.path(out_dir, paste0("nontrans_chr", chr, ".vcf")), sep = "\t")
  }

  if (!is.null(plink_path)) {
    vcf_to_plink(vcf_trans, vcf_nontrans, out_dir, chr, plink_path)
  }


  invisible(list(
    vcf_trans = vcf_trans,
    vcf_nontrans = vcf_nontrans,
    sim_perc_summary = sim_summary
  ))
}
