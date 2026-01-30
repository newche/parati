library(testthat)
library(parati)

test_that("minimal parati run works", {
  fam <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")
  vcf <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")

  res <- parati_run(geno_file = vcf, fam_file = fam, out_dir = tempdir(), chr = 1)
  expect_true("vcf_trans" %in% names(res))
  expect_true("vcf_nontrans" %in% names(res))
  expect_true("sim_perc_summary" %in% names(res))
})
