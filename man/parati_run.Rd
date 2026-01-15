\name{parati_run}
\alias{parati_run}
\title{Run PARATI inference workflow}
\description{
Main function to run the haplotype inference workflow on a set of VCF and family files.
}
\usage{
parati_run(
  geno_file,
  fam_file,
  out_dir,
  chr,
  hap_length = 500000,
  plink_path = NULL,
  write_files = TRUE
)
}
\arguments{
  \item{geno_file}{Path to phased VCF file (`.vcf` or `.vcf.gz`).}
  \item{fam_file}{Path to family index table (Excel `.xlsx` file).}
  \item{out_dir}{Output directory where results will be saved.}
  \item{chr}{Integer, chromosome number to process.}
  \item{hap_length}{Integer, haplotype window length (default 500000).}
  \item{plink_path}{Optional string. Path to PLINK executable for generating BED files.}
  \item{write_files}{Logical, whether to write output VCFs to disk (default TRUE).}
}
\value{
A list containing:
\describe{
  \item{vcf_trans}{VCF with transmitted alleles annotated.}
  \item{vcf_nontrans}{VCF with non-transmitted alleles annotated.}
  \item{sim_perc_summary}{Summary of simulation results for all families.}
}
}
\examples{
\dontrun{
parati_run(
  geno_file = "Toy_TrioGenotype.vcf.gz",
  fam_file = "Toy_FamilyIndexTable.xlsx",
  out_dir = "output",
  chr = 1
)
}
}
\seealso{
\code{\link{haplotype_infer}}
}
