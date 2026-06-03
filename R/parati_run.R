#' Run PARATI inference workflow
#'
#' Main function to infer parental transmitted and non-transmitted alleles
#' from phased trio genotype data. The function accepts either a VCF file path
#' or a `VCF` object from `VariantAnnotation`, and returns R objects without
#' writing files by default.
#'
#' @param vcf Either a character path to a phased VCF/VCF.GZ file, or a
#'   `VariantAnnotation::VCF` object.
#' @param fam Either a character path to a family index table (`.xlsx`) or
#'   a `data.frame` / `data.table` with columns `FamilyIndex`, `IndividualID`,
#'   and `Role`.
#' @param chr Optional chromosome identifier to subset variants.
#' @param hap_length Integer, haplotype window length.
#'
#' @return A named list containing:
#' \describe{
#'   \item{vcf_trans}{A `data.table` with transmitted alleles.}
#'   \item{vcf_nontrans}{A `data.table` with non-transmitted alleles.}
#'   \item{sim_perc_summary}{A `data.table` summarizing inference statistics.}
#' }
#'
#' @examples
#' vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
#' fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")
#' res <- parati_run(vcf = vcf_file, fam = fam_file, chr = 1)
#' names(res)
#'
#' @export
parati_run <- function(vcf, fam, chr = NULL, hap_length = 500000) {
  fam_dt <- .parati_read_family(fam)
  vcf_dt <- .parati_read_vcf(vcf, chr = chr)

  info_cols <- names(vcf_dt)[seq_len(9)]
  fam_ids <- unique(fam_dt[["FamilyIndex"]])

  trans_list <- vector("list", length(fam_ids))
  nontrans_list <- vector("list", length(fam_ids))
  sim_list <- vector("list", length(fam_ids))

  for (idx in seq_along(fam_ids)) {
    fid <- fam_ids[[idx]]
    fam_sub <- fam_dt[fam_dt[["FamilyIndex"]] == fid, ]

    if (nrow(fam_sub) != 3L) {
      stop("Each FamilyIndex must have exactly 3 rows. Problem family: ", fid)
    }

    if (!setequal(fam_sub[["Role"]], c("F", "M", "C"))) {
      stop(
        "Each FamilyIndex must contain exactly one F, one M, and one C. Problem family: ",
        fid
      )
    }

    fam_sub[["Role_BMP"]] <- NA_character_
    fam_sub[["Role_BMP"]][fam_sub[["Role"]] == "C"] <- "B"
    fam_sub[["Role_BMP"]][fam_sub[["Role"]] == "M"] <- "M"
    fam_sub[["Role_BMP"]][fam_sub[["Role"]] == "F"] <- "P"

    iid <- fam_sub[["IndividualID"]]
    role <- fam_sub[["Role_BMP"]]

    missing_iid <- setdiff(iid, names(vcf_dt))
    if (length(missing_iid) > 0) {
      stop(
        "These IndividualID values are not present in the VCF columns: ",
        paste(missing_iid, collapse = ", ")
      )
    }

    if (anyNA(role)) {
      stop("Role_BMP contains NA for family: ", fid)
    }

    vcf_sub <- vcf_dt[, c(info_cols, iid), with = FALSE]
    data.table::setnames(vcf_sub, iid, role)

    res <- haplotype_infer(vcf_dt = vcf_sub, hap_length = hap_length)

    trans_dt <- data.table::copy(
      res$vcf_trans[, c(info_cols, "M_transmitted", "P_transmitted"), with = FALSE]
    )
    nontrans_dt <- data.table::copy(
      res$vcf_nontrans[, c(info_cols, "M_nontransmitted", "P_nontransmitted"), with = FALSE]
    )

    data.table::setnames(
      trans_dt,
      c("M_transmitted", "P_transmitted"),
      paste0(c("M_transmitted_", "P_transmitted_"), fid)
    )

    data.table::setnames(
      nontrans_dt,
      c("M_nontransmitted", "P_nontransmitted"),
      paste0(c("M_nontransmitted_", "P_nontransmitted_"), fid)
    )

    trans_list[[idx]] <- trans_dt
    nontrans_list[[idx]] <- nontrans_dt

    tmp_sim <- data.table::copy(res$sim_perc_summary)
    tmp_sim[["FamilyIndex"]] <- fid
    sim_list[[idx]] <- tmp_sim
  }

  stopifnot(length(trans_list) > 0L, length(nontrans_list) > 0L)

  vcf_trans <- Reduce(
    function(x, y) merge(x, y, by = info_cols, all = TRUE),
    trans_list
  )

  vcf_nontrans <- Reduce(
    function(x, y) merge(x, y, by = info_cols, all = TRUE),
    nontrans_list
  )

  sim_summary <- data.table::rbindlist(sim_list, fill = TRUE)

  list(
    vcf_trans = vcf_trans,
    vcf_nontrans = vcf_nontrans,
    sim_perc_summary = sim_summary
  )
}
