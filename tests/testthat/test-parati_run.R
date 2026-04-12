test_that("parati_run returns expected object structure", {

  vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
  fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")

  res <- parati::parati_run(vcf = vcf_file, fam = fam_file, chr = 1)

  # --- 基础结构 ---
  expect_true(is.list(res))
  expect_named(res, c("vcf_trans", "vcf_nontrans", "sim_perc_summary"))

  # --- 类型 ---
  expect_true(data.table::is.data.table(res$vcf_trans))
  expect_true(data.table::is.data.table(res$vcf_nontrans))
  expect_true(data.table::is.data.table(res$sim_perc_summary))

  # --- 不为空 ---
  expect_true(nrow(res$vcf_trans) > 0)
  expect_true(nrow(res$vcf_nontrans) > 0)

  # --- 核心列存在 ---
  expect_true(all(c("#CHROM","POS","ID","REF","ALT","QUAL","FILTER","INFO","FORMAT") %in% names(res$vcf_trans)))

})
