\name{haplotype_infer}
\alias{haplotype_infer}
\title{Infer parental transmitted and non-transmitted alleles}
\description{
Given a VCF and family table, infer which alleles are transmitted from parents to offspring.
}
\usage{
haplotype_infer(vcf_dt, hap_length = 500000)
}
\arguments{
  \item{vcf_dt}{A data.table containing the VCF information for a single chromosome. Must include standard VCF columns (`#CHROM`, `POS`, `ID`, `REF`, `ALT`, `QUAL`, `FILTER`, `INFO`, `FORMAT`) and individual genotype columns.}
  \item{hap_length}{Integer, haplotype window length (default 500000).}
}
\value{
A list containing three data.tables:
\describe{
  \item{vcf_trans}{VCF with transmitted alleles annotated.}
  \item{vcf_nontrans}{VCF with non-transmitted alleles annotated.}
  \item{sim}{Simulation summary table across all families (optional).}
}
}
\examples{
# Load required package
library(parati)
library(data.table)

# Load toy data included in the package
#vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")
#vcf_dt <- data.table::fread(vcf_file)

# Construct a minimal toy genotype table
vcf_dt <- data.table(
  CHR    = c(1, 1, 1),
  POS    = c(100, 200, 300),
  ID     = c(".", ".", "."),
  REF    = c("A", "C", "G"),
  ALT    = c("T", "G", "A"),
  QUAL   = c(60, 60, 60),
  FILTER = c("PASS", "PASS", "PASS"),
  INFO   = c(".", ".", "."),
  FORMAT = c("GT", "GT", "GT"),

  # genotype columns expected by haplotype_infer
  M = c("0|1", "1|0", "0|0"),
  P = c("1|0", "0|1", "0|0"),
  B = c("0|1", "1|0", "0|0")
)

# Run parental haplotype inference
hap_result <- haplotype_infer(vcf_dt, hap_length = 200)

# Inspect output
head(hap_result)


# Run parental haplotype inference
#hap_result <- haplotype_infer(vcf_dt, hap_length = 500)

# Explore results
head(hap_result$vcf_trans)
head(hap_result$vcf_nontrans)
head(hap_result$sim)
}
\seealso{
\code{\link{parati_run}}
}
