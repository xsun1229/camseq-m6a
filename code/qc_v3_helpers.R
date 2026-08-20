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

#' Derive a shorter k-mer from the pipeline's 5-mer motif column (annotated
#' with motif_flanking=2, i.e. +-2nt around the called base at the center).
#' width=3 takes the +-1nt window (the middle 3 characters); width=5 is a
#' no-op. Every motif is confirmed 5 characters with an "A" center (the
#' called base), so substr(motif, 2, 4) is always well-defined.
qc_motif_kmer <- function(motif5, width = 5) {
  if (width == 5) {
    return(motif5)
  }
  if (width == 3) {
    return(substr(motif5, 2, 4))
  }
  stop("qc_motif_kmer: unsupported width ", width, " (use 3 or 5)")
}

#' Per-sample motif percentage table from a "persample" sweep file, in the
#' shape the old QC docs' create_motif_plot() expects (sample_label, motif,
#' percentage columns; one panel per sample). Restricted to the `top_n`
#' motifs by total count summed across samples, so every sample's panel
#' shows the same motif categories (comparable dodge positions) instead of
#' each other's independent top-N, which for a 5-mer can otherwise clutter
#' the plot with dozens of near-zero categories.
qc_motif_table <- function(dt, samples, r, p, u = 1, d = 10, width = 5, top_n = 10) {
  rows <- lapply(samples, function(s) {
    sub <- qc_sample_passing(dt, s, r, p, u, d)
    n <- nrow(sub)
    if (n == 0) {
      return(NULL)
    }
    tab <- data.table(motif = qc_motif_kmer(sub$motif, width))[, .N, by = motif][, percentage := N / n * 100]
    tab[, `:=`(sample = s, total_n = n)]
    tab
  })
  out <- rbindlist(rows, fill = TRUE)
  if (nrow(out) == 0) {
    return(out)
  }
  keep <- out[, .(total_N = sum(N)), by = motif][order(-total_N)][seq_len(min(top_n, .N)), motif]
  out <- out[motif %in% keep]
  out[, sample_label := paste0(sample, " (n=", format(total_n, big.mark = ","), ")")]
  out[, sample_label := fct_reorder(sample_label, total_n)]
  out
}

#' Motif percentage table from a "pooled" sweep file -- already just the
#' passing rows for the single pooled ("ALL") sample. Restricted to the
#' top_n motifs by count.
qc_motif_table_pooled <- function(dt, width = 5, top_n = 10) {
  n <- nrow(dt)
  if (n == 0) {
    return(dt[, .(motif = character(), percentage = numeric())])
  }
  tab <- data.table(motif = qc_motif_kmer(dt$motif, width))[, .N, by = motif][, percentage := N / n * 100]
  tab <- tab[order(-N)][seq_len(min(top_n, .N))]
  tab[, sample_label := paste0("all samples pooled (n=", format(n, big.mark = ","), ")")]
  tab
}

#' All possible motifs of a given width (3 or 5) that the pipeline's
#' annotate_motif.py can produce: A/C/G/T at every flanking position, "A" (the
#' called base) fixed at the center. 16 for width=3, 256 for width=5.
qc_motif_universe <- function(width) {
  bases <- c("A", "C", "G", "T")
  if (width == 3) {
    g <- expand.grid(x1 = bases, x2 = bases, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    return(sort(paste0(g$x1, "A", g$x2)))
  }
  if (width == 5) {
    g <- expand.grid(x1 = bases, x2 = bases, x3 = bases, x4 = bases, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    return(sort(paste0(g$x1, g$x2, "A", g$x3, g$x4)))
  }
  stop("qc_motif_universe: unsupported width ", width, " (use 3 or 5)")
}

#' Deterministic color for a motif string: same motif -> same color on every
#' call, in every plot, round, and cutoff -- unlike ggplot's default
#' discrete scale, which reassigns hues per plot based on whichever motifs
#' happen to appear in that particular top-N subset, making colors
#' meaningless to compare across plots. Hues are evenly spaced across the
#' full universe of possible motifs at this width (indexed alphabetically),
#' not hashed -- a hash can (and, on a 16-motif 3-mer universe, did) collide
#' two different motifs onto the same hue. Lightness alternates between two
#' bands by index parity so alphabetically-adjacent motifs (nearby hues)
#' stay visually separable too.
qc_motif_color <- function(motif) {
  width <- unique(nchar(motif))
  stopifnot("qc_motif_color: motif strings of mixed width" = length(width) == 1)
  universe <- qc_motif_universe(width)
  idx0 <- match(motif, universe) - 1L
  stopifnot("qc_motif_color: motif outside the expected A/C/G/T universe" = !anyNA(idx0))
  hue <- idx0 / length(universe) * 360
  lightness <- ifelse(idx0 %% 2 == 0, 45, 65)
  hcl(h = hue, c = 100, l = lightness)
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
  motifs <- sort(unique(motif_dt$motif))
  pal <- setNames(qc_motif_color(motifs), motifs)
  ggplot(motif_dt, aes(x = percentage, y = sample_label)) +
    geom_point(
      aes(color = motif),
      size = 3,
      position = position_jitterdodge(
        jitter.width = 0.15, jitter.height = 0.08, dodge.width = 0.6
      )
    ) +
    scale_color_manual(values = pal) +
    labs(title = title, x = "Percentage (%)", y = NULL, color = "motif") +
    theme_minimal()
}

#' Number of called sites for every sample across the full (p, r) cutoff
#' grid, in long format (one row per sample x cutoff) -- the input to
#' qc_heatmap_plot(). Set include_pooled=TRUE to add a "pooled" row (the
#' replicates-merged view); off by default -- for now the QC docs focus on
#' per-sample results only.
qc_sweep_counts <- function(base_dir, reftype, samples, pvals, ratios, u = 1, d = 10, include_pooled = FALSE) {
  grid <- expand.grid(p = pvals, r = ratios, stringsAsFactors = FALSE)
  rows <- lapply(seq_len(nrow(grid)), function(i) {
    p <- grid$p[i]
    r <- grid$r[i]
    dt_persample <- qc_read_sweep(base_dir, reftype, "persample", p, r)
    ns <- sapply(samples, function(s) nrow(qc_sample_passing(dt_persample, s, as.numeric(r), as.numeric(p), u, d)))
    sample <- samples
    n_sites <- ns
    if (include_pooled) {
      dt_pooled <- qc_read_sweep(base_dir, reftype, "pooled", p, r)
      sample <- c(sample, "pooled")
      n_sites <- c(n_sites, nrow(dt_pooled))
    }
    data.table(sample = sample, n_sites = n_sites, p = p, r = r)
  })
  out <- rbindlist(rows)
  out[, cutoff := sprintf("p<%s\nr>=%s%%", p, as.numeric(r) * 100)]
  out[, cutoff := factor(cutoff, levels = unique(cutoff[order(-as.numeric(p), as.numeric(r))]))]
  sample_levels <- setdiff(unique(out$sample), "pooled")
  if (include_pooled) sample_levels <- c(sample_levels, "pooled")
  out[, sample := factor(sample, levels = sample_levels)]
  out
}

#' Heatmap of qc_sweep_counts() output: sample (+ pooled) x cutoff grid,
#' tile color and label = number of sites called. Low end of the fill scale
#' is a pale blue, not pure white -- a low-value tile with a white fill is
#' indistinguishable from the page background (this bit us in an earlier
#' draft: the single lowest-count tile visually vanished).
qc_heatmap_plot <- function(dt, title) {
  ggplot(dt, aes(x = cutoff, y = sample, fill = n_sites)) +
    geom_tile(color = "white") +
    geom_text(aes(label = format(n_sites, big.mark = ",")), size = 3) +
    scale_fill_gradient(low = "#cde2fb", high = "#0d366b") +
    labs(title = title, x = NULL, y = NULL, fill = "n sites") +
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

#' Sites where BOTH sample_a and sample_b individually pass the cutoff (a
#' pairwise special case of qc_overlap's site sets), with each sample's own
#' methylation level (Ratio*100) at those sites -- the input to
#' qc_methylation_scatter(). Computed with boolean masks directly (not by
#' intersecting two qc_sample_passing() subsets) since we need each sample's
#' own Ratio value at the shared rows, not just the shared row count.
qc_common_sites <- function(dt, sample_a, sample_b, r, p, u = 1, d = 10) {
  r <- as.numeric(r)
  p <- as.numeric(p)
  passes <- function(s) {
    dt[[paste0("Depth_", s)]] >= d &
      dt[[paste0("Uncon_", s)]] >= u &
      dt[[paste0("Ratio_", s)]] >= r &
      dt[[paste0("pval_", s)]] <= p
  }
  keep <- passes(sample_a) & passes(sample_b)
  data.table(
    chrom = dt$chrom[keep], pos = dt$pos[keep], strand = dt$strand[keep], motif = dt$motif[keep],
    methylation_a = dt[[paste0("Ratio_", sample_a)]][keep] * 100,
    methylation_b = dt[[paste0("Ratio_", sample_b)]][keep] * 100
  )
}

#' Every position BOTH samples cover at usable depth, with no significance
#' filter at all (unlike qc_common_sites, which restricts to sites each
#' sample individually calls significant). This is the unbiased genome-wide
#' comparison: qc_common_sites only shows the two samples' agreement on the
#' high-confidence subset they both flag as real; this shows the full
#' relationship, dominated by low/background-level agreement everywhere
#' else. Depth is the only restriction, so this doesn't depend on any (p, r)
#' cutoff -- compute once per sample pair, not per cutoff block.
#'
#' Reads a pre-computed file (report_sites/all_covered_<a>_<b>.tsv.gz)
#' rather than filtering the joined arrow table in R directly: the R
#' `arrow` package can't read this project's polars-written IPC files
#' ("Unrecognized type" error -- a version/encoding mismatch), so the
#' filtering is done once in Python/polars (see
#' 2.qc/precompute_all_covered_sites.py) and this just reads the result.
qc_all_covered_sites <- function(base_dir, sample_a, sample_b) {
  f <- file.path(base_dir, "report_sites", sprintf("all_covered_%s_%s.tsv.gz", sample_a, sample_b))
  fread(f)
}

#' 2D-density plot of methylation level at sites both samples call, with a
#' Pearson correlation annotated in the title -- do sites confidently called
#' in both samples actually agree on how methylated they are, not just on
#' whether they clear the cutoff. Tens of thousands of common sites is
#' typical here, so this bins into a 2D histogram (geom_bin2d) rather than
#' plotting individual points -- a plain scatter at this n is just an
#' overplotted blob and the density pattern is the actually useful signal.
qc_methylation_scatter <- function(common_dt, label_a, label_b, title) {
  if (nrow(common_dt) == 0) {
    return(
      ggplot() +
        annotate("text", x = 0, y = 0, label = "no common sites") +
        theme_void()
    )
  }
  r <- cor(common_dt$methylation_a, common_dt$methylation_b, method = "pearson")
  ggplot(common_dt, aes(x = methylation_a, y = methylation_b)) +
    geom_bin2d(bins = 60) +
    scale_fill_gradient(low = "#cde2fb", high = "#0d366b", trans = "log10", name = "n sites") +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey40") +
    labs(
      x = paste0(label_a, " methylation (%)"), y = paste0(label_b, " methylation (%)"),
      title = sprintf("%s\nn=%s common sites, Pearson r=%.2f", title, format(nrow(common_dt), big.mark = ","), r)
    ) +
    theme_classic(base_size = 13)
}

#' Site positions along the 45S precursor rRNA (18S/5.8S/28S, in biological
#' order), for the shaded gene-background rects in qc_rrna_lollipop_plot().
#' Lengths from data/reference/gene/Human_rRNA_5S_250123.fa.fai. Our "genes"
#' reference also has 17 copies of 5S rRNA, excluded here since 5S is
#' Pol III-transcribed and not part of the 45S precursor.
qc_rrna_gene_positions <- function() {
  genes <- data.table(
    chrom = c("NR_003286.4", "NR_003285.3", "NR_003287.4"),
    name = c("18S", "5.8S", "28S"),
    length = c(1869, 157, 5070)
  )
  genes[, xmax := cumsum(length)]
  genes[, xmin := xmax - length]
  genes
}

#' Lollipop plot of methylation fraction (%) along the 45S precursor rRNA,
#' one panel per sample, points colored by whether that sample individually
#' calls the site significant vs background -- the same idea as
#' ~/xsun.xin3/pumseq/percl_pipeline/bin/R0_Sites_on_Ribosome_250125.R (a
#' different project's pseudouridine/m1A-on-rRNA plot), adapted for m6A:
#' color is our own pipeline's significance call instead of an external
#' known-site annotation, since there's no independent m6A-on-rRNA
#' reference to color against.
qc_rrna_lollipop_plot <- function(dt, title = "rRNA sites, 45S precursor") {
  gene_pos <- qc_rrna_gene_positions()
  offset <- setNames(gene_pos$xmin, gene_pos$chrom)
  dt <- copy(dt)
  dt[, x := pos + offset[chrom]]
  dt[, called_label := factor(ifelse(called, "called", "background"), levels = c("called", "background"))]

  mean_frac <- dt[, .(mean = mean(Fraction)), by = .(sample, called_label)]
  mean_frac <- mean_frac[CJ(sample = unique(dt$sample), called_label = levels(dt$called_label), unique = TRUE), on = c("sample", "called_label")]
  mean_frac[is.na(mean), mean := 0]
  # CJ()'s join drops the factor class (called_label becomes plain character),
  # so index by name explicitly rather than relying on factor-integer coercion
  mean_frac[, text_x := ifelse(called_label == "called", -Inf, Inf)]
  mean_frac[, text_hjust := ifelse(called_label == "called", -0.1, 1.1)]

  ggplot(dt, aes(x = x, y = Fraction, color = called_label)) +
    geom_rect(
      data = gene_pos, aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = 100),
      fill = "grey", alpha = 0.1, inherit.aes = FALSE
    ) +
    geom_segment(aes(xend = x, yend = 0), alpha = 0.4) +
    geom_point() +
    geom_text(
      data = mean_frac, aes(x = text_x, y = Inf, label = sprintf("%s=%.2f%%", called_label, mean), color = called_label, hjust = text_hjust),
      vjust = 1.3, inherit.aes = FALSE, size = 3.2, show.legend = FALSE
    ) +
    scale_color_manual(values = c(called = "#31a354", background = "grey60"), breaks = c("called", "background")) +
    scale_x_continuous(breaks = gene_pos$xmin + gene_pos$length / 2, labels = gene_pos$name) +
    scale_y_continuous(breaks = seq(0, 100, 20), limits = c(0, 108)) +
    facet_wrap(~sample, ncol = 1) +
    labs(x = "45S precursor rRNA (18S / 5.8S / 28S)", y = "Methylation fraction (%)", color = NULL, title = title) +
    theme_minimal(base_size = 12) +
    theme(legend.position = "top")
}
