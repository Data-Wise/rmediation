#' Function to check if lavaan model syntax is valid
#'
#' This function checks if the lavaan model syntax is valid. It does so by
#' attempting to parse and fit the model in a safe environment. If the model
#' syntax is invalid, the function will return an error message.
#' @param model A character string representing the lavaan model to be fitted.
#' @param data A data frame containing the observed variables.
#' @return A logical value indicating whether the model syntax is valid.
#' @name is_valid_lav_syntax
#' @aliases valid_lav_syntax is_valid_lav_syntax
#' @rdname is_valid_lav_syntax
#' @author Davood Tofighi \email{dtofighi@@gmail.com}
#' @importFrom OpenMx mxModel mxData mxRun omxLapply imxVerifyModel
#' @importFrom mice mice complete
#' @importFrom lavaan lavaan
#' @export
#' @examples
#' bad_model <- "y ~ x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9"
#' data(HolzingerSwineford1939, package = "lavaan")
#' is_valid_lav_syntax(bad_model, HolzingerSwineford1939)
#' good_model <- "visual =~ x1 + x2 + x3
#' textual =~ x4 + x5 + x6
#' speed =~ x7 + x8 + x9
#' visual ~ speed
#' textual ~ speed"
#' is_valid_lav_syntax(good_model, HolzingerSwineford1939)
# Function to check if model syntax is valid
is_valid_lav_syntax <- function(model, data = NULL) {
  # Ensure data is a data frame and is not NULL
  if (!is.null(data) && !is.data.frame(data)) {
    stop("'data' must be a data frame.")
  }

  tryCatch(
    {
      # Attempt to parse and fit the model in a safe environment
      # Note: Using a minimal dataset or dummy data as needed
      lavaan(
        model = model,
        data = data,
        auto.var = TRUE,
        auto.fix.first = TRUE,
        auto.cov.lv.x = TRUE,
        do.fit = FALSE
      )
      TRUE # Return TRUE if parsing and fitting succeed
    },
    error = function(e) {
      FALSE # Return FALSE if an error occurs
    }
  )
}
