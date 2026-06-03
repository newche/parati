```
# parati

**parati** is an R package for inferring maternal and paternal transmitted and
non-transmitted alleles from phased trio genotype data.

The package is designed for trio-based SNP-level analyses, including studies of
genetic nurture and transgenerational effects. It integrates with Bioconductor
workflows by supporting both VCF file paths and `VariantAnnotation::VCF`
objects as input.

---

## Features

- Trio-aware inference of transmitted and non-transmitted parental alleles
- Support for phased VCF genotype data
- Input as either:
  - a VCF/VCF.GZ file path
  - a `VariantAnnotation::VCF` object
- Returns R objects for downstream analysis rather than writing files by default
- Includes toy example data for testing and demonstration

---

## Installation

### Bioconductor

```r
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}
BiocManager::install("parati")
```

### Development version

```
# install.packages("remotes")
remotes::install_github("newche/parati")
```

------

## Input data

`parati` requires two inputs:

1. Trio genotype data in VCF format
2. A family index table describing family membership and roles

------

### 1. Trio genotype VCF

Supported input types:

- a path to a phased VCF/VCF.GZ file
- a `VariantAnnotation::VCF` object

Expected content:

- standard VCF fixed columns
- genotype columns whose sample IDs match the family table
- autosomal biallelic SNPs are recommended

Sample IDs in the VCF must exactly match the `IndividualID` column of the
 family table.

---

#### Example VCF input

Below is a partial example from the simulated testing dataset
`Toy_TrioGenotype.vcf.gz`:

```text
#CHROM POS     ID   REF ALT QUAL FILTER INFO FORMAT 1-M  1-P  1-B  2-M  2-P  2-B
1      100000  rs1  G   T   .    PASS   .    GT     0/0  0/1  0/1  0/0  0/1  0/1
1      101000  rs2  A   C   .    PASS   .    GT     0/0  0/1  0/0  0/0  0/0  0/0
1      102000  rs3  A   T   .    PASS   .    GT     0/0  0/0  0/0  1/1  1/1  0/1
1      103000  rs4  A   G   .    PASS   .    GT     0/1  0/1  0/1  0/1  0/0  ./.
1      104000  rs5  A   G   .    PASS   .    GT     0/1  0/0  0/1  0/0  0/1  0/0
1      105000  rs6  T   C   .    PASS   .    GT     0/0  1/1  0/1  1/1  0/1  0/1
1      106000  rs7  T   C   .    PASS   .    GT     0/0  0/0  0/0  0/1  0/0  0/1
1      107000  rs8  A   C   .    PASS   .    GT     0/0  0/0  0/0  ./.  0/1  0/1
...
```

------

### 2. Family index table

The family table must contain the following columns:

| Column name  | Description                                          |
| ------------ | ---------------------------------------------------- |
| FamilyIndex  | Family identifier                                    |
| IndividualID | Sample identifier matching the VCF sample name       |
| Role         | Family role: `F` (father), `M` (mother), `C` (child) |

The family input can be provided as:

- a path to an `.xlsx` file
- a `data.frame`
- a `data.table`

---

#### Example family index

```text
FamilyIndex  IndividualID  Role
1            1-M           M
1            1-P           F
1            1-B           C
2            2-M           M
2            2-P           F
2            2-B           C
3            3-M           M
3            3-P           F
3            3-B           C
...
```

---

------

## Example

```
library(parati)

vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")

res <- parati_run(
  vcf = vcf_file,
  fam = fam_file,
  chr = 1,
  hap_length = 500000
)

names(res)
head(res$vcf_trans, 3)
head(res$vcf_nontrans, 3)
head(res$sim_perc_summary, 3)
```

------

## Integration with Bioconductor workflows

```
library(parati)
library(VariantAnnotation)

vcf_file <- system.file("extdata", "Toy_TrioGenotype.vcf.gz", package = "parati")
fam_file <- system.file("extdata", "Toy_FamilyIndexTable.xlsx", package = "parati")

vcf_obj <- readVcf(vcf_file, genome = "unknown")

res <- parati_run(
  vcf = vcf_obj,
  fam = fam_file,
  chr = 1
)
```

------

## Output

`parati_run()` returns a named list containing:

- `vcf_trans`
- `vcf_nontrans`
- `sim_perc_summary`

These are returned as R objects for further analysis.

------

## Example data

Toy example data are included in:

```
inst/extdata/
```

Files:

- `Toy_TrioGenotype.vcf.gz`
- `Toy_FamilyIndexTable.xlsx`

------

## License

GPL-3 + file LICENSE

------

## Contact

For questions or issues, please open an issue on GitHub.

https://github.com/newche/parati/issues