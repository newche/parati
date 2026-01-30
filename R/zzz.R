utils::globalVariables(
  c(":=")
)

if (getRversion() >= "2.15.1") {
  utils::globalVariables(c(
    "..info_cols", "..cols_to_merge", "..cols_to_merge_nontrans",
    "M", "P", "B", "CHROM", "FamilyIndex", "Role_BMP", "vcf_to_plink"
  ))
}
