#' Sensitivity plots for a two-mediator parallel model.
#' 
#' @param x output from from \code{\link{sensitivity_2m_par}} function
#' @param rho1_facet facet (panel) values for the confounder correlation between Mediator 1 and the outcome variable
#' @param rho2_facet facet (panel) confounder correlation between Mediator 2 and the outcome variable
#' @param xlim1 x-axis limits for the plot of indirect effect through  Mediator 1
#' @param xlim2 x-axis limits for the plot of indirect effect through  Mediator 2
#' @param ylim1 y-axis limits for the plot of indirect effect through  Mediator 1
#' @param ylim2 y-axis limits for the plot of indirect effect through  Mediator 2
#' @param nrow the number of rows for matrix of plots
#' @param ncol the number of columns for the matrix of plots
#' @param device type of file to save the plot: 'pdf', 'png', etc
#' @return 
#' @seealso \code{\link{sensitivity_2m_par}}
#' @export





plot_2m_par <-
  function(x,
           rho1_facet = c(-.5,-.3,-.1, .1, .3, .5),
           rho2_facet = c(-.5,-.3,-.1, .1, .3, .5),
           xlim1 = c(0, .5),
           xlim2 = c(0, .5),
           ylim1 = NULL,
           ylim2 = NULL,
           nrow = NULL,
           ncol = 2,
           device = NULL) {
    if (is.null(device))
      device <- "pdf"
    
    
    ## Sensitivity plots
    med1_res <- x$ind1
    med2_res <- x$ind2
    
    sens_plot1 <-
      med1_res %>% filter(rho2 %in% rho2_facet) %>% ggplot(aes(rho1, ind)) +
      geom_hline(aes(yintercept = 0)) +
      geom_ribbon(aes(
        ymin = LL,
        ymax = UL,
        fill = rho2,
        alpha = rho2
      )) + theme_bw() +
      facet_wrap(
        ~ rho2,
        nrow = nrow,
        ncol = ncol,
        labeller = label_bquote(rho[2] == .(rho2))
      ) +
      scale_color_brewer(palette = "Blues") +
      labs(x = bquote(rho[1]), y = "Adjusted Indirect Effect") +
      guides(fill = "none", alpha = "none") +
      scale_x_continuous(limits = xlim1) +
      scale_y_continuous(limits = ylim1)
    
    sens_plot2 <-
      med2_res %>% filter(rho1 %in% rho1_facet) %>% ggplot(aes(rho2, ind)) +
      geom_hline(aes(yintercept = 0)) +
      geom_ribbon(aes(
        ymin = LL,
        ymax = UL,
        fill = rho1,
        alpha = rho1
      )) + theme_bw() +
      facet_wrap(
        ~ rho1,
        nrow = nrow,
        ncol = ncol,
        labeller = label_bquote(rho[1] == .(rho1))
      ) +
      scale_color_brewer(palette = "Blues") +
      labs(x = bquote(rho[2]), y = "Adjusted Indirect Effect") +
      guides(fill = "none", alpha = "none") +
      scale_x_continuous(limits = xlim2) +
      scale_y_continuous(limits = ylim2)
    
    print(sens_plot1) # show the plot
    print(sens_plot2) # show the plot
    
    ggsave(
      paste0("sensitivity_plot", lab$m1, ".", device),
      sens_plot1,
      width = 5,
      height = 5
    )
    
    ggsave(
      paste0("sensitivity_plot", lab$m2, ".", device),
      sens_plot2,
      width = 5,
      height = 5
    )
    
  }