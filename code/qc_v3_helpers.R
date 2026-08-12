# Shared helpers for the v3-pipeline QC docs (analysis/QC_round*_v3.Rmd).
#
# The v3 pipeline's own report_sites/joined/{genes,genome}.arrow already has
# per-sample Uncon_/Depth_/motif columns joined at the same sites, and
# report_sites/qc_sweep/ (built by /project/xinhe/xsun/camseq/2.qc/) holds the
# output of running the pipeline's own filter_sites.py across a grid of
# (min_pval, min_ratio) cutoffs -- once on the full per-sample joined table
# ("persample" -- kept if ANY sample passes) and once on a pooled table where
# Uncon_/Depth_ are summed across all samples first ("pooled" -- the "ALL"
# sample, analogous to the old QC docs' "replicates merged" view).
#
# These helpers just read those pre-computed sweep files and summarize them;
# no statistics are recomputed here.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(forcats)
})

#' Read and row-bind report_reads/read_counts_summary.tsv from one or more
#' round directories (round 5 needs two, since it ran as two separate jobs).
qc_read_counts <- function(dirs) {
  files <- file.path(dirs, "report_reads", "read_counts_summary.tsv")
  files <- files[file.exists(files)]
  rbindlist(lapply(files, fread))
}

#' Read one sweep output file for a given reftype/view/cutoff combo.
qc_read_sweep <- function(base_dir, reftype, view, p, r) {
  f <- file.path(
    base_dir, "report_sites", "qc_sweep",
    sprintf("%s.%s.p%s.r%s.tsv.gz", reftype, view, p, r)
  )
  fread(f)
}

#' Sample names present in a joined/sweep table, from its Depth_ columns.
qc_sample_names <- function(dt) {
  sub("^Depth_", "", grep("^Depth_", names(dt), value = TRUE))
}

#' Rows of a "persample" sweep table where `sample` itself (not just "any
#' sample") meets the cutoffs used to generate that file. The sweep file
#' already restricts to the union across samples, so this is a subset.
qc_sample_passing <- function(dt, sample, r, p, u = 1, d = 10) {
  dt[
    dt[[paste0("Depth_", sample)]] >= d &
      dt[[paste0("Uncon_", sample)]] >= u &
      dt[[paste0("Ratio_", sample)]] >= r &
      dt[[paste0("pval_", sample)]] <= p,
  ]
}

#' Per-sample motif percentage table from a "persample" sweep file, in the
#' shape the old QC docs' create_motif_plot() expects (sample_label, motif,
#' percentage columns; one panel per sample).
qc_motif_table <- function(dt, samples, r, p, u = 1, d = 10) {
  rows <- lapply(samples, function(s) {
    sub <- qc_sample_passing(dt, s, r, p, u, d)
    n <- nrow(sub)
    if (n == 0) {
      return(NULL)
    }
    tab <- sub[, .N, by = motif][, percentage := N / n * 100]
    tab[, `:=`(sample = s, total_n = n)]
    tab
  })
  out <- rbindlist(rows, fill = TRUE)
  if (nrow(out) == 0) {
    return(out)
  }
  out[, sample_label := paste0(sample, " (n=", format(total_n, big.mark = ","), ")")]
  out[, sample_label := fct_reorder(sample_label, total_n)]
  out
}

#' Motif percentage table from a "pooled" sweep file -- already just the
#' passing rows for the single pooled ("ALL") sample.
qc_motif_table_pooled <- function(dt) {
  n <- nrow(dt)
  if (n == 0) {
    return(dt[, .(motif = character(), percentage = numeric())])
  }
  tab <- dt[, .N, by = motif][, percentage := N / n * 100]
  tab[, sample_label := paste0("all samples pooled (n=", format(n, big.mark = ","), ")")]
  tab
}

#' Dot plot of motif percentages, one row per sample_label (reused for both
#' persample and pooled tables -- a pooled table is just the 1-row case).
qc_motif_plot <- function(motif_dt, title) {
  if (nrow(motif_dt) == 0) {
    return(
      ggplot() +
        annotate("text", x = 0, y = 0, label = "no sites passing this cutoff") +
        theme_void()
    )
  }
  ggplot(motif_dt, aes(x = percentage, y = sample_label)) +
    geom_point(
      aes(color = motif),
      size = 3,
      position = position_jitterdodge(
        jitter.width = 0.15, jitter.height = 0.08, dodge.width = 0.6
      )
    ) +
    labs(title = title, x = "Percentage (%)", y = NULL, color = "motif") +
    theme_minimal()
}

#' All-way and pairwise overlap of passing sites among samples, computed
#' directly from one "persample" sweep table (which already has every
#' sample's columns, so no need to read multiple files).
qc_overlap <- function(dt, samples, r, p, u = 1, d = 10) {
  site_sets <- lapply(samples, function(s) {
    sub <- qc_sample_passing(dt, s, r, p, u, d)
    paste(sub$chrom, sub$pos, sub$strand, sep = "_")
  })
  names(site_sets) <- samples

  all_way <- length(Reduce(intersect, site_sets))

  pm <- matrix(NA_integer_, length(samples), length(samples),
    dimnames = list(samples, samples)
  )
  for (i in seq_along(samples)) {
    for (j in seq_along(samples)) {
      pm[i, j] <- length(intersect(site_sets[[i]], site_sets[[j]]))
    }
  }
  list(all_way = all_way, pairwise = pm, n_sites = lengths(site_sets))
}
