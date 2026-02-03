---
title: "Home"
site: workflowr::wflow_site
output:
  workflowr::wflow_html:
    toc: false
editor_options:
  chunk_output_type: console
---

<p>
<button type="button" class="btn btn-default btn-workflowr btn-workflowr-report"
  data-toggle="collapse" data-target="#workflowr-report">
  <span class="glyphicon glyphicon-list" aria-hidden="true"></span>
  workflowr
  <span class="glyphicon glyphicon-exclamation-sign text-danger" aria-hidden="true"></span>
</button>
</p>

<div id="workflowr-report" class="collapse">
<ul class="nav nav-tabs">
  <li class="active"><a data-toggle="tab" href="#summary">Summary</a></li>
  <li><a data-toggle="tab" href="#checks">
  Checks <span class="glyphicon glyphicon-exclamation-sign text-danger" aria-hidden="true"></span>
  </a></li>
  <li><a data-toggle="tab" href="#versions">Past versions</a></li>
</ul>

<div class="tab-content">
<div id="summary" class="tab-pane fade in active">
  <p><strong>Last updated:</strong> 2026-02-03</p>
  <p><strong>Checks:</strong>
  <span class="glyphicon glyphicon-ok text-success" aria-hidden="true"></span>
  1
  <span class="glyphicon glyphicon-exclamation-sign text-danger" aria-hidden="true"></span>
  1
  </p>
  <p><strong>Knit directory:</strong>
  <code>camseq-m6a/</code>
  <span class="glyphicon glyphicon-question-sign" aria-hidden="true"
  title="This is the local directory in which the code in this file was executed.">
  </span>
  </p>
  <p>
  This reproducible <a href="https://rmarkdown.rstudio.com">R Markdown</a>
  analysis was created with <a
  href="https://github.com/workflowr/workflowr">workflowr</a> (version
  1.7.1). The <em>Checks</em> tab describes the
  reproducibility checks that were applied when the results were created.
  The <em>Past versions</em> tab lists the development history.
  </p>
<hr>
</div>
<div id="checks" class="tab-pane fade">
  <div class="panel-group" id="workflowr-checks">
  <div class="panel panel-default">
<div class="panel-heading">
<p class="panel-title">
<a data-toggle="collapse" data-parent="#workflowr-checks" href="#strongRMarkdownfilestronguncommittedchanges">
  <span class="glyphicon glyphicon-exclamation-sign text-danger" aria-hidden="true"></span>
  <strong>R Markdown file:</strong> uncommitted changes
</a>
</p>
</div>
<div id="strongRMarkdownfilestronguncommittedchanges" class="panel-collapse collapse">
<div class="panel-body">
  The R Markdown file has unstaged changes. 
To know which version of the R Markdown file created these
results, you'll want to first commit it to the Git repo. If
you're still working on the analysis, you can ignore this
warning. When you're finished, you can run
<code>wflow_publish</code> to commit the R Markdown file and
build the HTML.

</div>
</div>
</div>
<div class="panel panel-default">
<div class="panel-heading">
<p class="panel-title">
<a data-toggle="collapse" data-parent="#workflowr-checks" href="#strongRepositoryversionstrongahrefhttpsgithubcomxsun1229camseqm6atree5877b98cdf1d545a0b67881b12d4756a771ef4bbtargetblank5877b98a">
  <span class="glyphicon glyphicon-ok text-success" aria-hidden="true"></span>
  <strong>Repository version:</strong> <a href="https://github.com/xsun1229/camseq-m6a/tree/5877b98cdf1d545a0b67881b12d4756a771ef4bb" target="_blank">5877b98</a>
</a>
</p>
</div>
<div id="strongRepositoryversionstrongahrefhttpsgithubcomxsun1229camseqm6atree5877b98cdf1d545a0b67881b12d4756a771ef4bbtargetblank5877b98a" class="panel-collapse collapse">
<div class="panel-body">
  
<p>
Great! You are using Git for version control. Tracking code development and
connecting the code version to the results is critical for reproducibility.
</p>

<p>
The results in this page were generated with repository version <a href="https://github.com/xsun1229/camseq-m6a/tree/5877b98cdf1d545a0b67881b12d4756a771ef4bb" target="_blank">5877b98</a>.
See the <em>Past versions</em> tab to see a history of the changes made to the
R Markdown and HTML files.
</p>

<p>
Note that you need to be careful to ensure that all relevant files for the
analysis have been committed to Git prior to generating the results (you can
use <code>wflow_publish</code> or <code>wflow_git_commit</code>). workflowr only
checks the R Markdown file, but you know if there are other scripts or data
files that it depends on. Below is the status of the Git repository when the
results were generated:
</p>

<pre><code>
Ignored files:
	Ignored:    .Rhistory

Unstaged changes:
	Modified:   analysis/compare_round3_sample234_otherm6adb.Rmd
	Modified:   analysis/index.Rmd

</code></pre>

<p>
Note that any generated files, e.g. HTML, png, CSS, etc., are not included in
this status report because it is ok for generated content to have uncommitted
changes.
</p>

</div>
</div>
</div>
</div>
<hr>
</div>
<div id="versions" class="tab-pane fade">
  
<p>
These are the previous versions of the repository in which changes were made
to the R Markdown (<code>analysis/index.Rmd</code>) and HTML (<code>docs/index.html</code>)
files. If you've configured a remote Git repository (see
<code>?wflow_git_remote</code>), click on the hyperlinks in the table below to
view the files as they were in that past version.
</p>
<div class="table-responsive">
<table class="table table-condensed table-hover">
<thead>
<tr>
<th>File</th>
<th>Version</th>
<th>Author</th>
<th>Date</th>
<th>Message</th>
</tr>
</thead>
<tbody>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/f0132bdeeb1a5746c183dae8746d94e352678af3/analysis/index.Rmd" target="_blank">f0132bd</a></td>
<td>XSun</td>
<td>2026-02-03</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/f0132bdeeb1a5746c183dae8746d94e352678af3/docs/index.html" target="_blank">f0132bd</a></td>
<td>XSun</td>
<td>2026-02-03</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/47d3d299dce9deb9896d823c9a345d9fa2a8912e/docs/index.html" target="_blank">47d3d29</a></td>
<td>XSun</td>
<td>2026-02-02</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/c6394aeec47e7c94e77bfb35799647ff8df17c97/analysis/index.Rmd" target="_blank">c6394ae</a></td>
<td>XSun</td>
<td>2026-02-01</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/6de715b65eca2aa101922c198b0b3abd958dc8e4/analysis/index.Rmd" target="_blank">6de715b</a></td>
<td>XSun</td>
<td>2026-01-18</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/6de715b65eca2aa101922c198b0b3abd958dc8e4/docs/index.html" target="_blank">6de715b</a></td>
<td>XSun</td>
<td>2026-01-18</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/0f861bd7b8749a48adff0264409c2c249f5c14ec/docs/index.html" target="_blank">0f861bd</a></td>
<td>XSun</td>
<td>2025-06-25</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/da70f31ee3cab13d519350acdfbdc3bffaeaf156/analysis/index.Rmd" target="_blank">da70f31</a></td>
<td>XSun</td>
<td>2025-06-25</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/da70f31ee3cab13d519350acdfbdc3bffaeaf156/docs/index.html" target="_blank">da70f31</a></td>
<td>XSun</td>
<td>2025-06-25</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/93c4576b36e7f8d43ee43229653e78daa5e7778f/analysis/index.Rmd" target="_blank">93c4576</a></td>
<td>XSun</td>
<td>2025-06-20</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/93c4576b36e7f8d43ee43229653e78daa5e7778f/docs/index.html" target="_blank">93c4576</a></td>
<td>XSun</td>
<td>2025-06-20</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/7a703e21b08096c8d34a07a9a47a99b757a52d41/analysis/index.Rmd" target="_blank">7a703e2</a></td>
<td>XSun</td>
<td>2025-03-17</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/7a703e21b08096c8d34a07a9a47a99b757a52d41/docs/index.html" target="_blank">7a703e2</a></td>
<td>XSun</td>
<td>2025-03-17</td>
<td>update</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/8c2aff5cdd256595892f36032d9929c759867aed/analysis/index.Rmd" target="_blank">8c2aff5</a></td>
<td>XSun</td>
<td>2025-02-28</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/8c2aff5cdd256595892f36032d9929c759867aed/docs/index.html" target="_blank">8c2aff5</a></td>
<td>XSun</td>
<td>2025-02-28</td>
<td>update</td>
</tr>
<tr>
<td>html</td>
<td><a href="https://rawcdn.githack.com/xsun1229/camseq-m6a/6d825d0eef385997150fb0999aeb2b3b0005923f/docs/index.html" target="_blank">6d825d0</a></td>
<td>XSun</td>
<td>2025-02-26</td>
<td>Build site.</td>
</tr>
<tr>
<td>Rmd</td>
<td><a href="https://github.com/xsun1229/camseq-m6a/blob/b32e336f3d48e3134f7cfd4f3dd14d3684e874c4/analysis/index.Rmd" target="_blank">b32e336</a></td>
<td>XSun</td>
<td>2025-02-26</td>
<td>Start workflowr project.</td>
</tr>
</tbody>
</table>
</div>

<hr>
</div>
</div>
</div>




# Processing raw data

[QC -- data round 1, from Pingluan](https://xsun1229.github.io/camseq-m6a/QC.html)

[QC -- deeper sequencing, from Pingluan](https://xsun1229.github.io/camseq-m6a/QC_deeper.html)

[QC -- combining 2 rounds above](https://xsun1229.github.io/camseq-m6a/QC_2rounds.html)

[QC -- data round 3, from Jiahao](https://xsun1229.github.io/camseq-m6a/QC_round3.html)

[Comparing m6a sites from sample5 with camseq paper](https://xsun1229.github.io/camseq-m6a/compare_round3_sample5_camseqpaper.html)

[Comparing m6a sites from merged sample2-4 with other data bases](https://xsun1229.github.io/camseq-m6a/compare_round3_sample234_otherm6adb.html)

[QC -- multi cell types, from Kinga, has some quality issues](https://xsun1229.github.io/camseq-m6a/QC_multicelltypes.html)


