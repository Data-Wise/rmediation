#' Sensitivity analysis for a two-mediator parallel model.
#' 
#' @param input_file name and path to Mplus input file. This file needs to follow specific instruction. See below for more detail.
#' @param rho1 confounder correlation between Mediator 1 and the outcome variable
#' @param rho2 confounder correlation between Mediator 2 and the outcome variable
#' @param path directory and its path to save all the files generated when condcuting sensitivity analysis. Default is \code{\link{tempdir}}, in which the output files will be saved and deleted the R session ends.
#' @param alpha signficance level
#' @param lab lables used in the imput files to describe variables and indirect effect in the mplus file specfied in \code{input_file}.
#' @return 
#' @seealso 
#' @export



sensitivity_2m_par <- function(input_file = "",
                               rho1 = c(-.5, .5),
                               rho2 = c(-.5, .5),
                               path = tempdir(),
                               alpha =.05,
                               lab = list(
                                 x = "X",
                                 m1 = "I",
                                 m2 = "S",
                                 y = "Y",
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
  rho1 <- seq(rho1[1],rho1[2], by=.05)
  rho2 <- seq(rho2[1],rho2[2], by=.05)
  
  lab <- lapply(lab, toupper) # change all to upper case
  
  # Prepare Temp Directory
  tmp <- path                                                   # temp directory
  ls_file1 <- list.files(tmp, pattern = ".inp", full.names = TRUE)      # list of files in .tmp directory
  ls_file2 <- list.files(tmp, pattern = ".out", full.names = TRUE)      # list of files in .tmp directory
  ls_file3 <- list.files(tmp, pattern = ".log", full.names = TRUE)      # list of files in .tmp directory
  
  ls_file <- c(ls_file1,ls_file2,ls_file3)
  if (length(ls_file) > 0) file.remove(ls_file)                        # delete pre-existing inp file
  
  # Load Mplus Template 
  inp <- readLines(input_file)                                # Read text file and places in character string
  inp_comp <- str_trim(inp)                              # Remove excess lines from file
  inp_len <- length(inp_comp)                                          # Length of the new file
  
  # Create .inp files for all (default 400) combinations of the confounder correlations
  rhos <- expand.grid(rho1,rho2) ## cartesian product of all values
  foreach(x=iter(rhos, by="row"))%do%{
    const_str <- paste0(c("rho1=", "rho2="),x,";")
    cat(c(inp_comp,const_str), file = tempfile(pattern ="", fileext = ".inp") ,sep = "\n")
  }
  
  # Run Models in Parallel  
  runmplus(path = tmp)   

####### Read all the Mplus output files and combine the results
  
  resAll <-
    MplusAutomation::readModels(path)              # Load all the models
  
  res1 <-
    lapply(resAll, parEst)          # Extract unstanderdized parameter estimates
  
  res2 <-
    bind_rows(res1, .id = "model")  # Combine all models unstanderdized estimates into a single data frame
  
  ####### Calculate CIs RMediation
  # Extract Parameter Estiamtes for RMediation
  
  ## Mediator1 (I) on X
  a1_tbl <-
    res2 %>% dplyr::filter(paramHeader ==  paste0(lab$m1, ".ON") &
                             param == lab$x) %>% dplyr::select(model, est, se) %>% rename(a1_est = est, a1_se = se)
  ## Mediator2 (S) on X
  a2_tbl <-
    res2 %>% dplyr::filter(paramHeader ==  paste0(lab$m2, ".ON") &
                             param == lab$x) %>% dplyr::select(model, est, se) %>% rename(a2_est = est, a2_se = se)
  
  # Y= T4PPDD10.ON
  b1_tbl <-
    res2 %>% dplyr::filter(paramHeader == paste0(lab$y, ".ON") &
                             param == lab$m1) %>% dplyr::select(model, est, se) %>% rename(b1_est = est, b1_se = se)
  b2_tbl <-
    res2 %>% dplyr::filter(paramHeader == paste0(lab$y, ".ON")  &
                             param == lab$m2) %>% dplyr::select(model, est, se) %>% rename(b2_est = est, b2_se = se)
  
  rho1_tbl <-
    res2 %>% dplyr::filter(param %in% c("RHO1")) %>% dplyr::select(model, est) %>% rename(rho1 =
                                                                                            est)
  rho2_tbl <-
    res2 %>% dplyr::filter(param %in% c("RHO2")) %>% dplyr::select(model, est) %>% rename(rho2 = est)
  
  med_tbl <-
    inner_join(a1_tbl, b1_tbl, by = "model") %>% inner_join(a2_tbl, by = "model") %>%  inner_join(b2_tbl, by = "model") %>% inner_join(rho1_tbl, by = "model") %>% inner_join(rho2_tbl, by = "model")
  
  med1_tbl <- med_tbl %>% dplyr::select(matches("(a|b)1|rho"))
  med2_tbl <- med_tbl %>% dplyr::select(matches("(a|b)2|rho"))
  
### Compute CIs with RMediation using med_vec function  
  
  med1_ci_tbl <- med_vec(med1_tbl) %>% tbl_df()
  med2_ci_tbl <- med_vec(med2_tbl) %>% tbl_df()
  
  # med1_ci_tbl <- apply(med1_tbl, 1, med_vec, alpha=alpha/2)
  # med2_ci_tbl <- apply(med2_tbl, 1, med_vec, alpha=alpha/2)
  # 
  # 
  # med1_ci_tbl <- tbl_df(t(med1_ci_tbl))#do.call(rbind, med1_ci_tbl)
  med1_res <- inner_join(med1_tbl, med1_ci_tbl, by=c("rho1","rho2"))
  med2_res <- inner_join(med2_tbl, med2_ci_tbl, by=c("rho1","rho2"))
  

  
  ## Saving Sensitivity Data
  
  write_csv(med1_res, paste0("sensitivity_res_",lab$m1,".csv") )
  write_csv(med2_res, paste0("sensitivity_res_",lab$m2,".csv") )
  
  
  return(list(ind1=med1_res, ind2=med2_res) )
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
