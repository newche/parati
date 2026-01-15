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
\dontrun{
haplotype_infer(vcf_dt, chr = 1)
}
}
\seealso{
\code{\link{parati_run}}
}

