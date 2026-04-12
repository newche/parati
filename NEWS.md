parati 0.99.8 (2026-04-12)
-------------------------
* Restored core parental transmission inference behavior in `haplotype_infer()`:
  - reinstated deterministic Mendelian inference for non-triple-heterozygote patterns
  - reinstated local haplotype-based inference for triple-heterozygote sites
  - restored explicit handling of ambiguous and low-similarity haplotype matches

* Clarified output structure:
  - retained `parati_run()` as an R-object-returning interface
  - formalized separation of outputs into transmitted alleles, non-transmitted alleles,
    and haplotype-matching summary diagnostics
  - documented the relationship between the updated transmitted output and the
    original single-file VCF result

* Improved internal helper behavior:
  - cleaned duplicated internal helper definitions in `io_helpers.R`
  - added minimal compatibility handling for genotype fields containing additional
    FORMAT subfields
  - improved chromosome alias handling for inputs such as `1` and `chr1`

* Improved VCF export support:
  - fixed conversion of internal `data.table` outputs to `vcfR` objects
  - improved examples and vignette guidance for exporting standard VCF outputs

* Improved package build compatibility:
  - added package-level `data.table` awareness handling
  - added explicit namespace import for `data.table:::=`
  - adjusted code patterns that previously triggered avoidable BiocCheck notes

* Improved validation:
  - verified toy-data transmitted output against the original implementation
  - added and updated tests to better reflect expected trio inference behavior

* Improved vignette documentation:
  - added explicit guidance for exporting transmitted, non-transmitted, and
    summary outputs
  - documented the meaning of `sim_perc_summary` columns for downstream users

parati 0.99.6 (2026-03-16)
-------------------------
* Revised the package interface to better align with Bioconductor standards.
* Updated `parati_run()`:
  - now accepts either a VCF file path or a `VariantAnnotation::VCF` object
  - now returns R objects by default instead of writing files to disk
  - reduced repeated merging inside loops by collecting intermediate results first
* Added internal helpers for:
  - reading family tables from file paths, `data.frame`, or `data.table`
  - converting `VariantAnnotation::VCF` objects into internal `data.table` representation
* Improved Bioconductor integration:
  - added support for `VariantAnnotation`, `SummarizedExperiment`,
    `BiocGenerics`, and `GenomeInfoDb`
  - updated vignette to demonstrate integration with Bioconductor VCF workflows
* Removed incomplete placeholder functionality:
  - removed `vcf_to_plink()`
* Improved documentation:
  - updated function documentation and return value sections
  - cleaned up roxygen2-generated man pages
* Improved tests:
  - replaced minimal structural tests with unit tests covering expected
    transmission inference behavior on toy data
  - ensured core tests are suitable for Bioconductor build checking
* Updated vignette:
  - added abstract and motivation for inclusion in Bioconductor
  - replaced static code blocks with executable R code chunks
  - provided runnable examples using the included toy data
* Minor code cleanup:
  - removed redundant `requireNamespace()` calls for imported packages
  - updated package metadata and `biocViews`

