# Internal helper: read family table
.parati_read_family <- function(fam) {
  if (data.table::is.data.table(fam)) {
    fam_dt <- data.table::copy(fam)
  } else if (is.data.frame(fam)) {
    fam_dt <- data.table::as.data.table(fam)
  } else if (is.character(fam) && length(fam) == 1L) {
    fam_dt <- data.table::as.data.table(openxlsx::read.xlsx(fam))
  } else {
    stop("`fam` must be a file path, data.frame, or data.table.")
  }

  required_cols <- c("FamilyIndex", "IndividualID", "Role")
  if (!all(required_cols %in% names(fam_dt))) {
    stop(
      "Family table must contain columns: ",
      paste(required_cols, collapse = ", ")
    )
  }

  fam_dt
}

# Internal helper: convert a VariantAnnotation::VCF object to data.table
.parati_vcf_to_dt <- function(vcf_obj) {
  rr <- SummarizedExperiment::rowRanges(vcf_obj)
  gt <- VariantAnnotation::geno(vcf_obj)$GT

  if (is.null(gt)) {
    stop("The VCF object does not contain GT genotype data.")
  }

  fixed_df <- as.data.frame(VariantAnnotation::fixed(vcf_obj))
  chrom <- as.character(GenomeInfoDb::seqnames(rr))
  pos <- BiocGenerics::start(rr)
  id <- names(rr)
  id[is.na(id)] <- "."

  ref <- as.character(unname(VariantAnnotation::ref(vcf_obj)))
  alt <- vapply(
    VariantAnnotation::alt(vcf_obj),
    function(x) paste(as.character(x), collapse = ","),
    character(1)
  )

  qual <- if ("QUAL" %in% names(fixed_df)) {
    fixed_df$QUAL
  } else {
    rep(".", length(chrom))
  }

  filt <- if ("FILTER" %in% names(fixed_df)) {
    vapply(
      fixed_df$FILTER,
      function(x) paste(as.character(x), collapse = ";"),
      character(1)
    )
  } else {
    rep(".", length(chrom))
  }

  vcf_dt <- data.table::data.table(
    `#CHROM` = chrom,
    POS = pos,
    ID = id,
    REF = ref,
    ALT = alt,
    QUAL = qual,
    FILTER = filt,
    INFO = ".",
    FORMAT = "GT"
  )

  gt_dt <- data.table::as.data.table(gt)
  cbind(vcf_dt, gt_dt)
}

# Internal helper: fread VCF path
.parati_fread_vcf <- function(path, chr = NULL) {
  if (grepl("\\.gz$", path, ignore.case = TRUE)) {
    tmp <- tempfile(fileext = ".vcf")
    on.exit(unlink(tmp), add = TRUE)
    R.utils::gunzip(path, destname = tmp, remove = FALSE, overwrite = TRUE)
    vcf_dt <- data.table::fread(
      file = tmp,
      skip = "#CHROM",
      sep = "\t",
      header = TRUE,
      data.table = TRUE,
      fill = TRUE
    )
  } else {
    vcf_dt <- data.table::fread(
      file = path,
      skip = "#CHROM",
      sep = "\t",
      header = TRUE,
      data.table = TRUE,
      fill = TRUE
    )
  }

  if (!"#CHROM" %in% names(vcf_dt) && "CHROM" %in% names(vcf_dt)) {
    data.table::setnames(vcf_dt, "CHROM", "#CHROM")
  }

  required_vcf_cols <- c(
    "#CHROM", "POS", "ID", "REF", "ALT",
    "QUAL", "FILTER", "INFO", "FORMAT"
  )

  if (!all(required_vcf_cols %in% names(vcf_dt))) {
    stop(
      "VCF input is missing required columns: ",
      paste(setdiff(required_vcf_cols, names(vcf_dt)), collapse = ", ")
    )
  }

  # Minimal compatibility patch 1:
  # if sample fields look like 0|1:35,12:47, keep only GT
  sample_cols <- setdiff(names(vcf_dt), required_vcf_cols)
  if (length(sample_cols) > 0L) {
    for (cc in sample_cols) {
      x <- as.character(vcf_dt[[cc]])
      if (any(grepl(":", x, fixed = TRUE), na.rm = TRUE)) {
        vcf_dt[[cc]] <- sub(":.*$", "", x)
      }
    }
  }

  # Minimal compatibility patch 2:
  # allow chr = 1 to match both 1 and chr1
  if (!is.null(chr)) {
    chr0 <- as.character(chr)
    chr_core <- sub("^chr", "", chr0, ignore.case = TRUE)
    chr_alias <- unique(c(chr0, chr_core, paste0("chr", chr_core)))
    vcf_dt <- vcf_dt[vcf_dt[["#CHROM"]] %in% chr_alias, ]
  }

  vcf_dt
}

# Internal helper: read VCF path or VariantAnnotation::VCF object
.parati_read_vcf <- function(vcf, chr = NULL) {
  if (inherits(vcf, "VCF")) {
    vcf_dt <- .parati_vcf_to_dt(vcf)
    if (!is.null(chr)) {
      chr0 <- as.character(chr)
      chr_core <- sub("^chr", "", chr0, ignore.case = TRUE)
      chr_alias <- unique(c(chr0, chr_core, paste0("chr", chr_core)))
      vcf_dt <- vcf_dt[vcf_dt[["#CHROM"]] %in% chr_alias, ]
    }
  } else if (is.character(vcf) && length(vcf) == 1L) {
    vcf_dt <- .parati_fread_vcf(vcf, chr = chr)
  } else {
    stop("`vcf` must be a file path or a VariantAnnotation::VCF object.")
  }

  vcf_dt
}
