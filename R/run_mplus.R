#' Run Mplus input files within a directory.
#'
#' @param path A path to the mplus files. Default is \code{\link{tempdir}}.
#' @param cores The number of cores. Default is \code{\link{detectCores}-1}
#' @param outPath output path
#' @param logPath log files path
#' @param pattern pattern
#' @return Does not return a value.


run_mplus <- function(path = tempdir(),
                     cores = parallel::detectCores() - 1,
                     outPath = tempdir() ,
                     logPath = tempdir() ,
                     pattern = NULL) {
  #### Mplus function
  mplus <- function(x, out = outfiles, log = logfiles) {
    if (.Platform$OS.type == "unix") {
      if (Sys.info()["sysname"] == "Darwin")
        Mplus_command <- "/Applications/Mplus/mplus"
      else
        Mplus_command <- "mplus" #linux is case sensitive
    } else
      Mplus_command <- "mplus"
    system2(
      Mplus_command,
      args = c(x, out),
      stdout = log ,
      wait = TRUE
    )
  }

  # Create a vector of .inp files
  if (is.null(pattern))
    pattern <-  ".inp"
  inpfiles <- list.files(path = path ,
                         pattern = pattern,
                         full.names = TRUE)

  # Warning Indicator
  if (length(inpfiles) < 1)
    stop("No Mplus input files detected in the target directory: ",
         path)

  # Create directories if they don't exist
  if (!dir.exists(outPath)) dir.create(outPath)
  if (!dir.exists(logPath)) dir.create(logPath)

  # Create vectors of outfiles and logfiles for naming
  outfiles <- stringr::str_replace(inpfiles, pattern = ".inp", ".out")
  logfiles <- stringr::str_replace(inpfiles, pattern = ".inp", ".log")

  # Run Models in Parallel
  cl <- parallel::makeCluster(cores)
  doParallel::registerDoParallel(cores)
  foreach::foreach(i = iterators::iter(inpfiles),
          j = iterators::icount(length(inpfiles)),
          .inorder = FALSE) %dopar% mplus(i, out = outfiles[j], log = logfiles[j])
  parallel::stopCluster(cl)
}
