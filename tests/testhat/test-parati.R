library(testthat)
library(parati)

test_that("parati_run runs without error", {
  fam <- system.file("extdata","Toy_FamilyIndexTable.xlsx",package="parati")
  vcf <- system.file("extdata","Toy_TrioGenotype.vcf.gz",package="parati")

  res <- parati_run(geno_file=vcf, fam_file=fam, out_dir=tempdir(), chr=1)
  expect_true("M_transmitted" %in% names(res$vcf_trans))
  expect_true("P_transmitted" %in% names(res$vcf_trans))
})
