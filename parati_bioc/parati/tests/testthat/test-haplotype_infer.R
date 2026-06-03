test_that("haplotype_infer returns expected columns", {

  vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")

  vcf_dt <- parati:::.parati_read_vcf(vcf_file, chr = 1)

  # 构造一个 trio
  vcf_sub <- vcf_dt[, c(names(vcf_dt)[seq_len(9)], "1-M", "1-P", "1-B"), with = FALSE]
  data.table::setnames(vcf_sub, c("1-M","1-P","1-B"), c("M","P","B"))

  res <- parati::haplotype_infer(vcf_sub)

  # --- 返回结构 ---
  expect_true(is.list(res))
  expect_named(res, c("vcf_trans","vcf_nontrans","sim_perc_summary"))

  # --- 核心列 ---
  expect_true(all(c("M_transmitted","P_transmitted") %in% names(res$vcf_trans)))
  expect_true(all(c("M_nontransmitted","P_nontransmitted") %in% names(res$vcf_nontrans)))

})
