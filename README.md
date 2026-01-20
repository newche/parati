---

# parati

**parati** is an R package and command-line tool for **parent-of-origin–aware haplotype inference in trio genotype data**.
It infers transmitted and non-transmitted parental haplotypes along autosomes using phased windows and supports downstream export to PLINK formats.

PARATI is designed for large-scale trio datasets and can be run directly from the command line or integrated into R workflows.

---

## Features

* Trio-aware haplotype inference (father / mother → child)
* Sliding-window–based haplotype construction
* Explicit separation of transmitted vs non-transmitted alleles
* Supports large compressed VCF files (`.vcf.gz`)
* Optional export to PLINK (`.bed/.bim/.fam`)
* Designed for reproducible and automated pipelines

---

## Installation

### Requirements

* **R ≥ 4.1**
* Operating system: Linux or macOS
* External software:

  * **PLINK ≥ 1.9** (required)

### Required R packages

* `data.table (>= 1.16.0)`
* `dplyr (>= 1.1.4)`
* `stringr (>= 1.5.1)`
* `optparse (>= 1.7.5)`
* `openxlsx (>= 4.2.7.1)`
* `vcfR (>= 1.15.0)`
* `methods`

---

#### Install from GitHub (development version)

```r
# install.packages("devtools")
devtools::install_github("newche/parati")
```

Or clone manually:

```bash
git clone https://github.com/newche/parati.git
cd parati

#or
R CMD INSTALL parati_0.99.0.tar.gz
```

---

## Input data

PARATI requires **two input files**.

---

### 1. Trio genotype VCF

**Format**

* Compressed VCF: `.vcf.gz`
* Standard VCF columns:

  ```
  CHROM, POS, ID, REF, ALT, QUAL, FILTER, INFO, FORMAT
  ```
* Followed by **sample columns (individual IDs)**

**Content requirements**

* Each family must contain:

  * Biological father
  * Biological mother
  * Biological child
* Autosomes only
* Biallelic SNPs only

**Chromosome handling**

* The VCF **does not need to be chromosome-specific**
* PARATI processes **one chromosome at a time internally**, based on the `--chr` argument

**Sample ID rules (important)**

* Sample IDs in the VCF **must exactly match** the `IndividualID` column in the family index
* Matching is **case-sensitive**
* **Do not use underscores `_` in sample IDs**, to avoid parsing issues

---

#### Recommended quality control (before running PARATI)

Although not enforced, the following QC steps are strongly recommended:

* Filter variants by:

  * Call rate
  * Minor allele frequency (MAF)
* Remove Mendelian inconsistencies within trios
* Restrict to autosomal biallelic SNPs

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

---

### 2. Family index file

**Format**

* Excel file: `.xlsx`
* Must contain **exactly three required columns**

| Column name    | Description                                          |
| -------------- | ---------------------------------------------------- |
| `FamilyIndex`  | Family ID (integer or character, e.g. `1`, `FAM001`) |
| `IndividualID` | Individual ID, must match VCF sample name exactly    |
| `Role`         | Family role: `F` (father), `M` (mother), `C` (child) |

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

## Command-line usage

```bash
Rscript inst/scripts/parati.R [options]
```

### Required arguments

| Option         | Description                        |
| -------------- | ---------------------------------- |
| `--geno`       | Trio genotype VCF file (`.vcf.gz`) |
| `--family`     | Family index Excel file (`.xlsx`)  |
| `--chr`        | Chromosome number                  |
| `--out`        | Output directory                   |
| `--plink_path` | Full path to PLINK executable      |

---

### Optional arguments

| Option       | Default | Description                  |
| ------------ | ------- | ---------------------------- |
| `--haplen`   | 500000  | Haplotype window length (bp) |
| `--savetemp` | FALSE   | Save intermediate files      |
| `--makebed`  | FALSE   | Export PLINK bed/bim/fam     |

---

### Example run

```bash
Rscript inst/scripts/parati.R \
  --geno Toy_TrioGenotype.vcf.gz \
  --family Toy_FamilyIndex.xlsx \
  --chr 1 \
  --out results_chr1 \
  --haplen 500000 \
  --makebed TRUE \
  --plink_path /usr/local/bin/plink
```

---

## Output

parati generates:

* Per-window inferred haplotypes
* Transmitted and non-transmitted parental alleles
* Optional PLINK files:

  * `.bed`
  * `.bim`
  * `.fam`

Output files are organized by chromosome and haplotype window.

---

## License

GPL-3

---

## Citation

If you use parati in your research, please cite:

> *parati: Parent-of-origin aware haplotype inference for trio genotype data.*

---

## Contact

For questions or issues, please open an issue on GitHub.

---
