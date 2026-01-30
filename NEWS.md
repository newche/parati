parati 0.99.0 (2026-01-30)
-------------------------
* Initial Bioconductor-ready release.
* Added core functions:
  - parati_run: main function to infer transmitted/non-transmitted alleles.
  - read_vcf_by_chr: read VCF files by chromosome.
  - write_vcf_dt: save VCF as data.table.
  - vcf_dt_to_vcfR: convert data.table to vcfR object for Bioconductor integration.
  - write_vcf_obj: write vcfR objects to VCF files.
  - vcf_to_plink: export transmitted/non-transmitted VCFs to PLINK format.
* Enhanced documentation:
  - Added proper @param, @return sections for all functions.
  - Fixed Rd usage warnings.
* Vignette:
  - Added Bioconductor-compliant workflow vignette (parati-workflow.Rmd).
  - Demonstrates usage with example trio genotype data.
  - Shows conversion to Bioconductor vcfR objects for downstream analysis.
* Examples and tests:
  - Included toy datasets in extdata.
  - Provided fully running examples in vignette.
  - Added testthat framework for core functions.
* Minor bug fixes and code improvements:
  - Cleaned up Roxygen2 documentation.
  - Ensured package passes R CMD check without errors.
