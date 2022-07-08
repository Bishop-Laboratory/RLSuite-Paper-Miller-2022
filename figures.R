library(RLSeq)
library(dplyr)
library(ggplot2)

dir.create("results", showWarnings = F)

## Preliminary

# Retrieve datasets from RLBase
list(
  "shCTR" = RLSeq::RLRangesFromRLBase("SRX2187024"),
  "shSMN" = RLSeq::RLRangesFromRLBase("SRX2187025")
) -> rlrs

# Rename with proper experimental names
rlrs$shCTR@metadata$sampleName <- "SHS5Y5 shCTR (DRIP-Seq)"
rlrs$shSMN@metadata$sampleName <- "SHS5Y5 shSMN (DRIP-Seq)"

## Figure 2: Plot RLFS analysis

rlr <- rlrs$shCTR # Extract the control sample

# Make plot
plt <- plotRLFSRes(rlr)
ggsave(plt, filename = "results/figure_2.png", height = 6, width = 9)

## Figure 3: Noise analysis plots

# Fingerprint plot
plt <- plotFingerprint(rlr) +
  ggtitle(
    label = "Fingerprint plot",
    subtitle = rlr@metadata$sampleName
  ) +
    theme_bw(base_size = 18)
ggsave(plt, filename = "results/figure_3A.png", height = 6, width = 7.5)

# Noise plot + extra highlight for figure readability
topltfinal <- noiseComparisonPlot(rlr, returnData = TRUE) %>% 
    filter(prediction == label)
plt <- noiseComparisonPlot(rlr) +
    ggplot2::geom_point(
        alpha = ifelse(
            topltfinal$group == "User-supplied", 1, 0
        ), 
        size = 5, 
        color = "black", 
        fill="yellow", 
        shape = 23,
        stroke = 1.5
    ) +
    theme_bw(base_size = 18) +
    ggplot2::theme(
        legend.position = "none",
        plot.caption = element_text(
            size = 16
        )
    ) +
    ggplot2::labs(title = title, subtitle = paste0(rlr@metadata$sampleName, " highlighted"), caption = paste0("◇ - User-supplied sample")) 

ggsave(plt, filename = "results/figure_3B.png", height = 6, width = 7.5)

## Figure 4: Plot enrichment & txfeature overlap

# Plot enrichment, highlight user-supplied samples
lapply(
  rlrs, function(rlr) {
      dats <- plotEnrichment(rlr, returnData = TRUE) %>% purrr::pluck("Transcript_Features")
      plotEnrichment(rlr) %>% 
          purrr::pluck("Transcript_Features") +
          ggplot2::geom_point(
              alpha = ifelse(
                  dats$selected == rlr@metadata$sampleName, 1, 0
              ), 
              size = 5, 
              color = "black", 
              fill="yellow", 
              shape = 23,
              stroke = 1.5
          ) +
          theme_bw(base_size = 18) +
          ggplot2::theme(
              legend.position = "none",
              plot.caption = element_text(
                  size = 16
              )
          ) 
  }
) -> plts
plts$shSMN <- plts$shSMN +
    labs(
        title = NULL,
        subtitle = "SHS5Y5 shSMN"
    )
plts$shCTR <- plts$shCTR +
    labs(
        caption = NULL, 
        title = "Transcript feature enrichment",
        subtitle = "SHS5Y5 shCTR"
    )
plt <- ggpubr::ggarrange(
  plts$shCTR,
  plts$shSMN,
  nrow = 2
)
ggsave(plt, filename = "results/figure_4A.png", height = 8, width = 12)


# Tx Feature Overlap
rlrs$shCTR@metadata$sampleName <- "SHS5Y5 shCTR"
rlrs$shSMN@metadata$sampleName <- "SHS5Y5 shSMN"
lapply(
  rlrs, function(rlr) {
      plotTxFeatureOverlap(rlr) +
          labs(
              subtitle = rlr@metadata$sampleName
          )
  }
) -> plts
plts$shCTR <- plts$shCTR +
    ggpubr::rremove("legend")
plts$shSMN <- plts$shSMN +
    ggtitle(label = "   ")
plt <- ggpubr::ggarrange(
    plotlist = plts, common.legend = T, legend = "right"
)
ggsave(plt, filename = "results/figure_4B.png", height = 4, width = 12)


## Figure 5: Correlation heatmap

# Harmonize sample name
rlr <- rlrs$shCTR
rlr@metadata$sampleName <- "SHS5Y5 shCTR"
rownames(rlr@metadata$results@correlationMat)[
    rownames(rlr@metadata$results@correlationMat) == 'SRX2187024'
] <- rlr@metadata$sampleName
colnames(rlr@metadata$results@correlationMat)[
    colnames(rlr@metadata$results@correlationMat) == 'SRX2187024'
] <- rlr@metadata$sampleName

# Plot heatmap
png(filename = "results/figure_5.png", height = 6, width = 8, units = "in", res = 300)
corrHeatmap(rlr)
dev.off()


## Figure 6: RL Region venn diagram
rlr@metadata$sampleName <- "SHS5Y5_shCTR"
png(filename = "results/figure_6.png", height = 6, width = 8, units = "in", res = 300)
plotRLRegionOverlap(
    object,
    fill = c("goldenrod", "skyblue"),
    main.cex = 2,
    cat.cex=1.2,
    cat.pos = c(-60, 60),
    cat.dist=.06,
    margin = .15
)
dev.off()

## Figure 7: RLSeq report
rlr@metadata$sampleName <- "SHS5Y5 shCTR"
report(rlr, reportPath = "results/report.html")



