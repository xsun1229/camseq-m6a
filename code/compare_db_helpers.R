# Helpers for comparing our called m6A sites against published databases,
# following the same methodology as analysis/compare_round3_sample234_otherm6adb.Rmd
# but written so each reference dataset is parsed once and reused across
# every sample x cutoff combination, instead of being re-read from disk in
# every block.

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(eulerr)
  library(GenomicRanges)
  library(IRanges)
})

## ---- Our sites --------------------------------------------------------

#' A single sample's own passing sites at a given p/methylation-ratio
#' cutoff, from a "persample" qc_sweep table (see code/qc_v3_helpers.R:
#' qc_read_sweep, qc_sample_passing) -- chrom/pos/strand/motif plus a
#' 0-100-scale methylation_pct column matching the reference datasets' scale.
qc_our_sites <- function(base_dir, reftype, sample, r, p, u = 1, d = 10) {
  dt <- qc_read_sweep(base_dir, reftype, "persample", p, r)
  sub <- qc_sample_passing(dt, sample, as.numeric(r), as.numeric(p), u, d)
  sub[, .(chrom, pos, strand, motif, methylation_pct = 100 * get(paste0("Ratio_", sample)))]
}

## ---- Reference dataset loaders (call once, reuse the result) -------------

#' PMID 35288668 Supplementary Data 1, single-nucleotide resolution.
#' sheet 6/7/8 = HSPC ribo d3/d6/d9. Site key is chrom-pos (no strand),
#' matching the original comparison doc's convention.
load_paper1_sheet <- function(path, sheet) {
  df <- as.data.table(readxl::read_excel(path, sheet = sheet))
  df[, chrom := gsub("^chr", "", Chrom)]
  df[, site := paste0(chrom, "-", Position)]
  setnames(df, "m6A fracrion (%)", "m6a_pct")
  df[, .(site, m6a_pct)]
}

#' d3+d6+d9 combined and deduplicated by site (a site reported at any stage
#' counts once), same as the original doc's "d3, d6, d9" comparison.
load_paper1_combined <- function(path) {
  parts <- lapply(6:8, function(s) load_paper1_sheet(path, s))
  out <- rbindlist(parts)
  out[!duplicated(site)]
}

#' REPIC MONO-MAC-6 peaks: pos column is "chrN:start-end[strand]".
load_repic_peaks <- function(path) {
  df <- fread(path)
  strand <- sub(".*\\[(.)\\]$", "\\1", df$pos)
  coord <- sub("\\[.*\\]$", "", df$pos)
  GRanges(
    seqnames = sub(":.*", "", coord),
    ranges = IRanges(
      start = as.integer(sub(".*:(\\d+)-.*", "\\1", coord)),
      end = as.integer(sub(".*-(\\d+)", "\\1", coord))
    ),
    strand = strand
  )
}

#' m6A-Atlas2 MONO-MAC-6 peaks: explicit seqnames/start/end/strand columns.
load_atlas2_peaks <- function(path) {
  df <- fread(path)
  GRanges(seqnames = df$seqnames, ranges = IRanges(df$start, df$end), strand = df$strand)
}

## ---- Comparisons -----------------------------------------------------

#' Site-level comparison (our sites vs. a single-nucleotide-resolution
#' reference): overlap count/pct, a methylation-level scatter for the sites
#' both call, and a Euler diagram. `our_dt` needs columns chrom, pos,
#' methylation_pct (0-100 scale, matching the reference's m6a_pct).
compare_site_level <- function(our_dt, paper_dt, label, title_suffix) {
  our_dt <- copy(our_dt)
  our_dt[, site := paste0(chrom, "-", pos)]
  inter <- intersect(our_dt$site, paper_dt$site)

  df_merge <- merge(our_dt, paper_dt, by = "site")
  scatter <- ggplot(df_merge, aes(x = m6a_pct, y = methylation_pct)) +
    geom_point(alpha = 0.6, size = 2) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey40") +
    labs(x = paste0(label, " methylation level (%)"), y = "Our methylation level (%)", title = title_suffix) +
    theme_classic(base_size = 14)

  fit <- euler(c(
    setNames(nrow(paper_dt) - length(inter), label),
    Ours = nrow(our_dt) - length(inter),
    setNames(length(inter), paste0(label, "&Ours"))
  ))
  venn <- plot(fit, fills = c("#0072B2", "#D55E00"), alpha = 0.6, labels = TRUE, quantities = TRUE)

  list(
    n_ref = nrow(paper_dt), n_ours = nrow(our_dt), n_overlap = length(inter),
    pct_ours_covered = 100 * length(inter) / nrow(our_dt),
    scatter = scatter, venn = venn
  )
}

#' Peak-level comparison (our sites vs. a peak-level reference): what
#' fraction of our strand-aware sites fall inside a reference peak.
compare_peak_level <- function(our_dt, gr_paper, label) {
  gr_ours <- GRanges(
    seqnames = paste0("chr", our_dt$chrom),
    ranges = IRanges(start = our_dt$pos, end = our_dt$pos),
    strand = our_dt$strand
  )
  hits <- suppressWarnings(findOverlaps(gr_ours, gr_paper, ignore.strand = FALSE))
  n_covered <- length(unique(queryHits(hits)))
  n_total <- length(gr_ours)

  df_bar <- data.table(
    status = c(paste0("Covered by ", label), "Not covered"),
    count = c(n_covered, n_total - n_covered)
  )
  df_bar[, percent := 100 * count / n_total]
  df_bar[, status := factor(status, levels = status)]

  bar <- ggplot(df_bar, aes(x = status, y = count, fill = status)) +
    geom_col(width = 0.6, alpha = 0.85) +
    geom_text(aes(label = sprintf("%s\n(%.1f%%)", format(count, big.mark = ","), percent)), vjust = -0.4, size = 4) +
    scale_fill_manual(values = c("#0072B2", "grey70")) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.25))) +
    labs(x = NULL, y = "Number of sites", title = paste("Coverage of our sites by", label)) +
    theme_classic(base_size = 14) +
    theme(legend.position = "none", plot.title = element_text(hjust = 0.5))

  list(n_ref = length(gr_paper), n_covered = n_covered, n_total = n_total, pct_covered = 100 * n_covered / n_total, bar = bar)
}
