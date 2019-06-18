read_mplus <- function(rho1 = c(-.5,.5),
                       rho2 = c(-.5,.5),
                       path = tempdir(),
                       lab = list(
                         x = "ntx",
                         m1 = "I",
                         m2 = "S",
                         y = "T4PPDD10",
                         ind1 = "ind1",
                         ind2 = "ind2"
                       )) {
### AUX functions ################
    parEst <- function(x) {
    x$parameters$unstandardized
  }
  ### Extract model fit information
  modelEst <- function(x) {
    x$summaries
  }
### End of AUX functions ###############
  rho1 <- seq(rho1[1],rho1[2],length.out = 20)
  rho2 <- seq(rho1[1],rho1[2],length.out = 20)
  
  lab <- lapply(lab, toupper) # change all to upper case
  
  # Prepare Temp Directory
  tmp <- path                                                   # temp directory
  ls_file1 <- list.files(tmp, pattern = ".inp", full.names = TRUE)      # list of files in .tmp directory
  ls_file2 <- list.files(tmp, pattern = ".out", full.names = TRUE)      # list of files in .tmp directory
  ls_file3 <- list.files(tmp, pattern = ".log", full.names = TRUE)      # list of files in .tmp directory
  
  ls_file <- c(ls_file1,ls_file2,ls_file3)
  if (length(ls_file) > 0) file.remove(ls_file)                        # delete pre-existing inp file
  
  # Load Mplus Template 
  inp <- readLines("LGC craving mediation naltrexone predict PDDm4_sensitivity_template.inp")                                # Read text file and places in character string
  inp_comp <- str_trim(inp)                              # Remove excess lines from file
  inp_len <- length(inp_comp)                                          # Length of the new file
  
  # Create .inp files for all (default 400) combinations of the confounder correlations
  rhos <- expand.grid(rho1,rho2) ## cartesian product of all values
  # for (i in 1:nrow(rhos)) {
  #   p1 <- paste0("rho1=",rhos[i,1],";")
  #   p2 <- paste0("rho2=",rhos[i,2],";")
  #   cat(c(inp_comp,p1,p2),                                          # Add Rho to end of each .inp file
  #       file = tempfile(pattern = "", fileext = ".inp") ,sep = "\n")
  # }
  
  foreach(x=iter(rhos, by="row"))%do%{
    const_str <- paste0(c("rho1=", "rho2="),x,";")
    cat(c(inp_comp,const_str), file = tempfile(pattern = paste0(c("rho1", "rho2"),x), fileext = ".inp") ,sep = "\n")
  }
  
  resAll <-
    MplusAutomation::readModels(path)              # Load all the models
  
  res1 <-
    lapply(resAll, parEst)          # Extract unstanderdized parameter estimates
  
  res2 <-
    bind_rows(res1, .id = "model")  # Combine all models unstanderdized estimates into a single data frame

  ###### RMediation Code
  # Extract Parameter Estiamtes for RMediation
 
  ## Mediator1 (I) on X
  a1_tbl <-
    res2 %>% dplyr::filter(paramHeader ==  paste0(lab$m1,".ON") & param == lab$x  ) %>% dplyr::select(model, est, se) %>% rename(a1_est = est, a1_se = se)
 ## Mediator2 (S) on X
   a2_tbl <-
    res2 %>% dplyr::filter(paramHeader ==  paste0(lab$m2,".ON") & param == lab$x ) %>% dplyr::select(model, est, se) %>% rename(a2_est = est, a2_se = se)
  
  # Y= T4PPDD10.ON
  b1_tbl <-
    res2 %>% dplyr::filter(paramHeader == paste0(lab$y,".ON") &
                             param == lab$m1 ) %>% dplyr::select(model, est, se) %>% rename(b1_est = est, b1_se = se)
  b2_tbl <-
    res2 %>% dplyr::filter(paramHeader == paste0(lab$y,".ON")  &
                             param == lab$m2) %>% dplyr::select(model, est, se) %>% rename(b2_est = est, b2_se = se)
  
  rho1_tbl <-
    res2 %>% dplyr::filter(param %in% c("RHO1")) %>% dplyr::select(model, est) %>% rename(rho1 =
                                                                                            est)
  rho2_tbl <-
    res2 %>% dplyr::filter(param %in% c("RHO2")) %>% dplyr::select(model, est) %>% rename(rho2 = est)
  
  med_tbl <-
    inner_join(a1_tbl, b1_tbl, by = "model") %>% inner_join(a2_tbl, by = "model") %>%  inner_join(b2_tbl, by = "model") %>% inner_join(rho1_tbl, by = "model") %>% inner_join(rho2_tbl, by = "model")
  
  med1_tbl <- med_tbl %>% dplyr::select(matches("(a|b)1|rho"))
  med1_ci_tbl <- apply(med1_tbl, 1, med_vec)
  med1_ci_tbl <- do.call(rbind, med1_ci_tbl)
  med1_res <- cbind(med1_tbl, med1_ci_tbl)
  
  med2_tbl <- med_tbl %>% dplyr::select(matches("(a|b)2|rho"))
  med2_ci_tbl <- apply(med2_tbl, 1, med_vec)
  med2_ci_tbl <- do.call(rbind, med2_ci_tbl)
  med2_res <- cbind(med2_tbl, med2_ci_tbl)
  
  lattice::contourplot(
    ind ~ rho1 * rho2,
    data = na.omit(med1_res),
    cuts = 10,
    region = TRUE,
    col.regions = heat.colors,
    panel = latticeExtra::panel.2dsmoother
  )
  
  med1_res %>% filter(rho2 %in% c(-.5,-.1, .1, .5)) %>% ggplot(aes(rho1, ind)) + geom_hline(aes(yintercept = 0)) + geom_ribbon(aes(
    ymin = LL,
    ymax = UL,
    fill = rho2,
    alpha = rho2
  )) + theme_bw() + facet_wrap( ~ rho2, labeller = label_bquote(rho[2] == .(rho2))) + labs(x =
                                                                                             "") + scale_color_brewer(palette = "Blues") + labs(x = bquote(rho[1]), y =
                                                                                                                                                  "Adjusted Indirect Effect")
  
  med2_res %>% filter(rho2 %in% c(-.5,-.3,-.1, .1, .3, .5)) %>% ggplot(aes(rho1, ind)) + geom_hline(aes(yintercept = 0)) + geom_ribbon(aes(
    ymin = LL,
    ymax = UL,
    fill = rho2,
    alpha = rho2
  )) + theme_bw() + facet_wrap( ~ rho2, labeller = label_bquote(rho[2] == .(rho2))) + labs(x =
                                                                                             "") + scale_color_brewer(palette = "Blues") + labs(x = bquote(rho[1]), y =
                                                                                                                                                  "Adjusted Indirect Effect")
  
  
  #med1_res %>% group_by(rho1,rho2) %>% summarise(ind=mean(ind)) %>%  ggplot(aes(x = rho1, y = rho2, z = ind)) + stat_contour(na.rm=TRUE) + theme_bw()
  
#  library(plotly)
  # #plot_ly(x = ~rho1, y = ~rho2, z = ~ind, data=med1_res) %>% add_histogram2dcontour()
  #med1_res %>% group_by(rho1,rho2) %>% summarise(ind=mean(ind))  %>% filter(rho2==0) %>% plot_ly(x = ~rho1, y = ~rho2, z = ~ind) %>% add_contour()
  # plot_ly(
  #   x = ~ rho1,
  #   y = ~ rho2,
  #   z = ~ ind,
  #   data = med1_res
  # ) %>% add_mesh()
  #
  # med1_res %>% plot_ly(x = ~rho1, y = ~rho2, z = ~ind) %>% add_heatmap()
  #
  # p1 <- med1_res %>% filter(rho2==0) %>% plot_ly(x = ~rho1,  y = ~ind) %>% add_lines() %>% add_ribbons(ymin = ~LL, ymax = ~UL)
  #
  # p2 <- med1_res %>% filter(rho2==0.5) %>% plot_ly(x = ~rho1,  y = ~ind) %>% add_lines() %>% add_ribbons(ymin = ~LL, ymax = ~UL)
  #
  # med1_res_sub <- med1_res %>% filter(rho2 %in% c(-.5,-.1, .1, .5))
  # d1 <- group_by(med1_res_sub, rho2)
  # plots1 <-
  #   do(
  #     d1,
  #     p = plot_ly(
  #       .,
  #       x = ~ rho1,
  #       y =  ~ ind,
  #       name = ~ rho2
  #     ) %>% add_lines() %>% add_ribbons(ymin = ~ LL, ymax = ~ UL)
  #   )
  # subplot(plots1[["p"]], nrows = 4, shareX = TRUE)
  # 
  # 
}
