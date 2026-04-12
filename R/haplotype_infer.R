#' Infer parental transmitted and non-transmitted alleles
#'
#' Given trio genotype data for a single family, infer maternal and paternal
#' transmitted and non-transmitted alleles.
#'
#' This function preserves the original PARATI inference semantics:
#' - deterministic Mendelian inference for non-triple-heterozygote patterns
#' - local haplotype matching for triple-heterozygote sites
#' - low-similarity / ambiguous sites are left as missing (".|.")
#'
#' @param vcf_dt A `data.table` containing fixed VCF columns and genotype
#'   columns named `M`, `P`, and `B`.
#' @param hap_length Integer, haplotype window length.
#'
#' @return A named list containing:
#' \describe{
#'   \item{vcf_trans}{A `data.table` with transmitted alleles.}
#'   \item{vcf_nontrans}{A `data.table` with non-transmitted alleles.}
#'   \item{sim_perc_summary}{A `data.table` summarizing inference statistics.}
#' }
#'
#' @export
haplotype_infer <- function(vcf_dt, hap_length = 500000) {
  if (!data.table::is.data.table(vcf_dt)) {
    stop("vcf_dt must be a data.table")
  }

  required_cols <- c("M", "P", "B")
  if (!all(required_cols %in% names(vcf_dt))) {
    stop("vcf_dt must contain genotype columns: M, P, B")
  }

  if (!is.numeric(hap_length) || length(hap_length) != 1L || is.na(hap_length) || hap_length <= 0) {
    stop("hap_length must be a positive numeric scalar")
  }

  info_cols <- names(vcf_dt)[seq_len(9)]
  vcf_working <- data.table::copy(vcf_dt)

  .gt_only <- function(x) {
    x <- as.character(x)
    x[is.na(x)] <- "."
    sub(":.*$", "", x)
  }

  .normalize_gt <- function(x) {
    x <- .gt_only(x)
    x <- gsub("/", "|", x, fixed = TRUE)
    x[x %in% c(".", "./.", ".|.", ".|", "|.", "")] <- ".|."
    x
  }

  .is_het <- function(x) {
    x %in% c("0|1", "1|0")
  }

  .is_hom0 <- function(x) {
    x == "0|0"
  }

  .is_hom1 <- function(x) {
    x == "1|1"
  }

  .safe_mean_eq <- function(a, b) {
    if (length(a) == 0L || length(b) == 0L) {
      return(NA_real_)
    }
    mean(a == b)
  }

  .empty_sim_summary <- function() {
    data.table::data.table(
      `#CHROM` = character(),
      POS = integer(),
      ID = character(),
      pair = character(),
      B_hap = character(),
      PM_hap = character(),
      bpwindow = integer(),
      nSNP_haplotype = integer(),
      sim_perc = numeric(),
      order = integer(),
      status = character()
    )
  }

  if (nrow(vcf_working) == 0L) {
    vcf_trans <- vcf_working[, info_cols, with = FALSE]
    vcf_nontrans <- vcf_working[, info_cols, with = FALSE]

    vcf_trans[, `:=`(
      M_transmitted = character(),
      P_transmitted = character()
    )]

    vcf_nontrans[, `:=`(
      M_nontransmitted = character(),
      P_nontransmitted = character()
    )]

    return(list(
      vcf_trans = vcf_trans,
      vcf_nontrans = vcf_nontrans,
      sim_perc_summary = .empty_sim_summary()
    ))
  }

  # Normalize trio GT strings
  data.table::set(vcf_working, j = "M", value = .normalize_gt(vcf_working[["M"]]))
  data.table::set(vcf_working, j = "P", value = .normalize_gt(vcf_working[["P"]]))
  data.table::set(vcf_working, j = "B", value = .normalize_gt(vcf_working[["B"]]))

  # Split haplotypes
  m_split <- data.table::tstrsplit(vcf_working[["M"]], "|", fixed = TRUE, keep = seq_len(2))
  p_split <- data.table::tstrsplit(vcf_working[["P"]], "|", fixed = TRUE, keep = seq_len(2))
  b_split <- data.table::tstrsplit(vcf_working[["B"]], "|", fixed = TRUE, keep = seq_len(2))

  data.table::set(vcf_working, j = "M_hap1", value = m_split[[1]])
  data.table::set(vcf_working, j = "M_hap2", value = m_split[[2]])
  data.table::set(vcf_working, j = "P_hap1", value = p_split[[1]])
  data.table::set(vcf_working, j = "P_hap2", value = p_split[[2]])
  data.table::set(vcf_working, j = "B_hap1", value = b_split[[1]])
  data.table::set(vcf_working, j = "B_hap2", value = b_split[[2]])

  hap_cols <- c("M_hap1", "M_hap2", "P_hap1", "P_hap2", "B_hap1", "B_hap2")
  for (cc in hap_cols) {
    x <- vcf_working[[cc]]
    x[is.na(x)] <- "."
    data.table::set(vcf_working, j = cc, value = x)
  }

  # Initialize inferred allele columns
  data.table::set(vcf_working, j = "M_transmitted", value = rep(NA_character_, nrow(vcf_working)))
  data.table::set(vcf_working, j = "M_nontransmitted", value = rep(NA_character_, nrow(vcf_working)))
  data.table::set(vcf_working, j = "P_transmitted", value = rep(NA_character_, nrow(vcf_working)))
  data.table::set(vcf_working, j = "P_nontransmitted", value = rep(NA_character_, nrow(vcf_working)))

  # Deterministic Mendelian inference
  m_vals <- vcf_working[["M"]]
  p_vals <- vcf_working[["P"]]
  b_vals <- vcf_working[["B"]]

  m_hom1 <- .is_hom1(m_vals)
  m_hom0 <- .is_hom0(m_vals)
  p_hom1 <- .is_hom1(p_vals)
  p_hom0 <- .is_hom0(p_vals)
  m_het  <- .is_het(m_vals)
  p_het  <- .is_het(p_vals)
  b_het  <- .is_het(b_vals)
  b_hom1 <- .is_hom1(b_vals)
  b_hom0 <- .is_hom0(b_vals)

  vcf_working[m_hom1, c("M_transmitted", "M_nontransmitted") := list("1", "1")]
  vcf_working[m_hom0, c("M_transmitted", "M_nontransmitted") := list("0", "0")]
  vcf_working[p_hom1, c("P_transmitted", "P_nontransmitted") := list("1", "1")]
  vcf_working[p_hom0, c("P_transmitted", "P_nontransmitted") := list("0", "0")]

  # Mother homozygote, father heterozygote
  vcf_working[m_hom1 & p_het & b_het, c("P_transmitted", "P_nontransmitted") := list("0", "1")]
  vcf_working[m_hom1 & p_het & b_hom1, c("P_transmitted", "P_nontransmitted") := list("1", "0")]

  vcf_working[m_hom0 & p_het & b_het, c("P_transmitted", "P_nontransmitted") := list("1", "0")]
  vcf_working[m_hom0 & p_het & b_hom0, c("P_transmitted", "P_nontransmitted") := list("0", "1")]

  # Father homozygote, mother heterozygote
  vcf_working[m_het & p_hom1 & b_het, c("M_transmitted", "M_nontransmitted") := list("0", "1")]
  vcf_working[m_het & p_hom1 & b_hom1, c("M_transmitted", "M_nontransmitted") := list("1", "0")]

  vcf_working[m_het & p_hom0 & b_het, c("M_transmitted", "M_nontransmitted") := list("1", "0")]
  vcf_working[m_het & p_hom0 & b_hom0, c("M_transmitted", "M_nontransmitted") := list("0", "1")]

  # Both parents heterozygous, child homozygous
  vcf_working[m_het & p_het & b_hom1,
              c("M_transmitted", "M_nontransmitted", "P_transmitted", "P_nontransmitted") :=
                list("1", "0", "1", "0")]

  vcf_working[m_het & p_het & b_hom0,
              c("M_transmitted", "M_nontransmitted", "P_transmitted", "P_nontransmitted") :=
                list("0", "1", "0", "1")]

  # Triple heterozygote inference by local haplotype matching
  triple_het_idx <- which(m_het & p_het & b_het)
  sim_perc_summary <- .empty_sim_summary()

  if (length(triple_het_idx) > 0L) {
    pos_vec <- as.integer(vcf_working[["POS"]])

    complete_hap_mask <-
      vcf_working[["B_hap1"]] %in% c("0", "1") &
      vcf_working[["B_hap2"]] %in% c("0", "1") &
      vcf_working[["M_hap1"]] %in% c("0", "1") &
      vcf_working[["M_hap2"]] %in% c("0", "1") &
      vcf_working[["P_hap1"]] %in% c("0", "1") &
      vcf_working[["P_hap2"]] %in% c("0", "1")

    pair_names <- c(
      "B_hap1_vs_M_hap1", "B_hap1_vs_M_hap2", "B_hap1_vs_P_hap1", "B_hap1_vs_P_hap2",
      "B_hap2_vs_M_hap1", "B_hap2_vs_M_hap2", "B_hap2_vs_P_hap1", "B_hap2_vs_P_hap2"
    )

    sim_list <- vector("list", length(triple_het_idx))

    for (k in seq_along(triple_het_idx)) {
      i <- triple_het_idx[[k]]
      pos_i <- pos_vec[[i]]

      if (is.na(pos_i)) {
        window_idx <- integer()
      } else {
        window_idx <- which(
          complete_hap_mask &
            !is.na(pos_vec) &
            pos_vec > (pos_i - hap_length) &
            pos_vec < (pos_i + hap_length)
        )
      }

      n_snp_hap <- length(window_idx)

      sim_vec <- stats::setNames(rep(NA_real_, 8L), pair_names)

      if (n_snp_hap > 0L) {
        sim_vec["B_hap1_vs_M_hap1"] <- .safe_mean_eq(vcf_working[["B_hap1"]][window_idx], vcf_working[["M_hap1"]][window_idx])
        sim_vec["B_hap1_vs_M_hap2"] <- .safe_mean_eq(vcf_working[["B_hap1"]][window_idx], vcf_working[["M_hap2"]][window_idx])
        sim_vec["B_hap1_vs_P_hap1"] <- .safe_mean_eq(vcf_working[["B_hap1"]][window_idx], vcf_working[["P_hap1"]][window_idx])
        sim_vec["B_hap1_vs_P_hap2"] <- .safe_mean_eq(vcf_working[["B_hap1"]][window_idx], vcf_working[["P_hap2"]][window_idx])

        sim_vec["B_hap2_vs_M_hap1"] <- .safe_mean_eq(vcf_working[["B_hap2"]][window_idx], vcf_working[["M_hap1"]][window_idx])
        sim_vec["B_hap2_vs_M_hap2"] <- .safe_mean_eq(vcf_working[["B_hap2"]][window_idx], vcf_working[["M_hap2"]][window_idx])
        sim_vec["B_hap2_vs_P_hap1"] <- .safe_mean_eq(vcf_working[["B_hap2"]][window_idx], vcf_working[["P_hap1"]][window_idx])
        sim_vec["B_hap2_vs_P_hap2"] <- .safe_mean_eq(vcf_working[["B_hap2"]][window_idx], vcf_working[["P_hap2"]][window_idx])
      }

      best_val <- if (all(is.na(sim_vec))) {
        NA_real_
      } else {
        max(sim_vec, na.rm = TRUE)
      }


      if (n_snp_hap == 0L || is.na(best_val) || best_val < 0.7) {
        status_i <- "Low similarity"
      } else {
        best_pair <- names(sim_vec)[which(sim_vec == best_val)]

        if (length(best_pair) != 1L) {
          status_i <- "Ambiguous"
        } else {
          status_i <- "Inferred based on haplotype"
          pm_hap_temp <- sub(".*_vs_", "", best_pair)

          if (pm_hap_temp == "P_hap1") {
            p_tr <- vcf_working[["P_hap1"]][i]
            p_non <- vcf_working[["P_hap2"]][i]

            vcf_working[i, c("P_transmitted", "P_nontransmitted", "M_transmitted", "M_nontransmitted") :=
                          list(p_tr, p_non, p_non, p_tr)]

          } else if (pm_hap_temp == "P_hap2") {
            p_tr <- vcf_working[["P_hap2"]][i]
            p_non <- vcf_working[["P_hap1"]][i]

            vcf_working[i, c("P_transmitted", "P_nontransmitted", "M_transmitted", "M_nontransmitted") :=
                          list(p_tr, p_non, p_non, p_tr)]

          } else if (pm_hap_temp == "M_hap1") {
            m_tr <- vcf_working[["M_hap1"]][i]
            m_non <- vcf_working[["M_hap2"]][i]

            vcf_working[i, c("M_transmitted", "M_nontransmitted", "P_transmitted", "P_nontransmitted") :=
                          list(m_tr, m_non, m_non, m_tr)]

          } else if (pm_hap_temp == "M_hap2") {
            m_tr <- vcf_working[["M_hap2"]][i]
            m_non <- vcf_working[["M_hap1"]][i]

            vcf_working[i, c("M_transmitted", "M_nontransmitted", "P_transmitted", "P_nontransmitted") :=
                          list(m_tr, m_non, m_non, m_tr)]
          }
        }
      }

      sim_list[[k]] <- data.table::data.table(
        `#CHROM` = rep(vcf_working[["#CHROM"]][i], 8L),
        POS = rep(as.integer(vcf_working[["POS"]][i]), 8L),
        ID = rep(vcf_working[["ID"]][i], 8L),
        pair = pair_names,
        B_hap = sub("_vs_.*$", "", pair_names),
        PM_hap = sub("^.*_vs_", "", pair_names),
        bpwindow = rep(as.integer(hap_length), 8L),
        nSNP_haplotype = rep(as.integer(n_snp_hap), 8L),
        sim_perc = as.numeric(sim_vec),
        order = seq_len(8L),
        status = rep(status_i, 8L)
      )
    }

    sim_perc_summary <- data.table::rbindlist(sim_list, fill = TRUE)
  }

  # Final formatting
  mt <- vcf_working[["M_transmitted"]]
  mnt <- vcf_working[["M_nontransmitted"]]
  pt <- vcf_working[["P_transmitted"]]
  pnt <- vcf_working[["P_nontransmitted"]]

  mt[is.na(mt)] <- "."
  mnt[is.na(mnt)] <- "."
  pt[is.na(pt)] <- "."
  pnt[is.na(pnt)] <- "."

  data.table::set(vcf_working, j = "M_transmitted", value = mt)
  data.table::set(vcf_working, j = "M_nontransmitted", value = mnt)
  data.table::set(vcf_working, j = "P_transmitted", value = pt)
  data.table::set(vcf_working, j = "P_nontransmitted", value = pnt)

  vcf_trans <- vcf_working[, info_cols, with = FALSE]
  vcf_trans[, `:=`(
    M_transmitted = paste0(vcf_working[["M_transmitted"]], "|."),
    P_transmitted = paste0(vcf_working[["P_transmitted"]], "|.")
  )]

  vcf_nontrans <- vcf_working[, info_cols, with = FALSE]
  vcf_nontrans[, `:=`(
    M_nontransmitted = paste0(vcf_working[["M_nontransmitted"]], "|."),
    P_nontransmitted = paste0(vcf_working[["P_nontransmitted"]], "|.")
  )]

  list(
    vcf_trans = vcf_trans,
    vcf_nontrans = vcf_nontrans,
    sim_perc_summary = sim_perc_summary
  )
}
