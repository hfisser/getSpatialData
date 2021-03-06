# ---------------------------------------------------------------------
# name: out_communication
# These are functions used for console communication.
# The core of gsd console communication is out(). 
# ---------------------------------------------------------------------

# -------------------------------------------------------------
# GENERAL
# -------------------------------------------------------------

#' Outputs errors, warnings and messages
#'
#' @param input character
#' @param type numeric, 1 = message/cat, 2 = warning, 3 = error and stop
#' @param msg logical. If \code{TRUE}, \code{message} is used instead of \code{cat}. Default is \code{FALSE}.
#' @param sign character. Defines the prefix string.
#'
#' @importFrom utils flush.console
#' @keywords internal
#' @noRd

out <- function(input, type = 1, ll = NULL, msg = FALSE, sign = "", flush = FALSE, verbose = getOption("gSD.verbose")){
  if (inherits(input, DATAFRAME()) && verbose) {
    print(input, row.names = FALSE, right = FALSE)
  } else {
    if(!is.na(type) && !type %in% c(1, 2, 3)) type <- 1
    if(isTRUE(flush)) flush.console()
    if(is.null(ll)) if(isTRUE(verbose)) ll <- 1 else ll <- 2
    if(type == 2 & ll <= 2){warning(paste0(sign,input), call. = FALSE, immediate. = TRUE)}
    else{if(type == 3){stop(input, call. = FALSE)}else{if(ll == 1){
      if(msg == FALSE){ cat(paste0(sign,input), sep = ifelse(isTRUE(flush), " ", "\n"))
      } else{message(paste0(sign,input))}}}}
  }
}

#' prints character vectors in console combined into one message in out()
#' @param x list of character vectors.
#' @param type numeric as in out().
#' @param msg logical as in out().
#' @return nothing. Console print
#' @keywords internal
#' @noRd
.out_vector <- function(x, type=1, msg=FALSE) {
  shout_out <- sapply(x,function(vec) {
    print_out <- sapply(vec,function(v) out(v,type=type,msg=msg))
  })
  rm(shout_out)
}

#' seperator for console communication
#' @return character
#' @keywords internal
#' @noRd
sep <- function() {
  sep <- "\n---------------------------------------------------------------------------------"
  return(sep)
}

#' run silent
#' @param expr an expression
#' @return nothing. runs expression
#' @keywords internal
#' @noRd
quiet <- function(expr){
  return(suppressWarnings(suppressMessages(expr)))
}

# -------------------------------------------------------------
# select_*
# -------------------------------------------------------------

#' communicates a selection process start info
#' @param mode character selection mode.
#' @param sep character aesthetic element for console output.
#' @return nothing. Console output.
#' @keywords internal
#' @noRd
.select_start_info <- function(mode,sep) {
  out(paste0("Starting ", mode," Selection"), msg=T)
}

#' Throws error because temporal arguments disable a consistent selection
#' @param min_distance numeric
#' @param max_sub_period numeric
#' @return nothing. Throws error
#' @keywords internal
#' @noRd
.select_temporally_incosistent_error <- function(min_distance, max_sub_period) {
  msg <- paste0("Argument 'min_distance' between acquisitions used for dinstinguished timestamps is: ",
min_distance," days. The 'max_sub_period' of covered acquisitions for one timestamp is: ",max_sub_period,". 
With the given 'n_timestamps' these values disable creating a temporally consistent selection.", arg_help_msg(1))
  out(msg, 3)
}

#' creates a selection summary per timestamp as a table
#' @param timestamps_seq integer vector
#' @param coverage_vector numeric vector
#' @param n_records_vector numeric vector
#' @param sep character separator to be printed before and after table
#' @keywords internal
#' @noRd
.select_final_info_table <- function(timestamps_seq, coverage_vector, n_records_vector, sep) {
  coverage_vector <- sapply(coverage_vector, function(x) {return(ifelse(x > 100, 100, x))})
  cov_bars <- .create_numeric_bars(coverage_vector, n = 5, bar_symbol = "/")
  table_sep <- "| "
  summary_df <- data.frame("| Timestamp" = paste0(table_sep, timestamps_seq),
                           "| Selected records" = paste0(table_sep, n_records_vector),
                           "|    Cloud-free pixels" = paste0("| ", cov_bars, " ", round(coverage_vector, 2), " %"), 
                           check.names = FALSE)
  out(summary_df)
}

#' constructs a summary of the console info of \code{.select_final_info}.
#' In addition: if the minimum coverage amongst the timestamps is below 60 \% return a warning message. 
#' In addition: if the mean coverage amongst the timestamps is below 80 \% return a warning message.
#' These warning messages are returned as NULL if the respective condition is not TRUE.
#' @param selected list of lists 'selected' each holding for a timestamp: 'ids', 'cMask_paths', 'valid_pixels', 'timestamp'
#' @return \code{console_summary_warning} list of character vectors holding the messages:
#' [[1]] Summary info
#' [[2]] Warning if minimum coverage is below 60 \% else character "NULL".
#' [[3]] Warning if mean coverage is below 80 \% else character "NULL".
#' The second [[2]] character vector holds the optional warning(s). 
#' @keywords internal
#' @noRd
.select_overall_summary <- function(selected) {
  
  sep <- sep()
  num_timestamps <- length(selected)
  coverages <- sapply(selected, function(x) {x$valid_pixels})
  mean_cov <- round(mean(coverages))
  max_cov <- round(max(coverages))
  min_cov <- round(min(coverages))
  mean_cov <- ifelse(mean_cov > 100, 100, mean_cov)
  max_cov <- ifelse(max_cov > 100, 100, max_cov)
  min_cov <- ifelse(min_cov > 100, 100, min_cov)
  cov_metrics <- c(mean_cov, max_cov, min_cov)
  bars <- .create_numeric_bars(cov_metrics, n = 5, bar_symbol = "/")
  empty <- ""
  some_spaces <- "       "
  one_space <- " "
  table_sep <- "| "
  placeholder <- paste0(table_sep, empty)
  
  summary_df <- data.frame("| Number timestamps" = c(paste0(table_sep, num_timestamps), placeholder, placeholder),
                           "| " = c("| Mean", "| Max", "| Min"),
                           "     Overall cloud-free pixels" = paste0(some_spaces, bars, one_space, cov_metrics, " %"),
                           check.names = FALSE)
  out(summary_df)
  out(sep)
  
  # optionally thrown warnings
  cov_pixels <- "overage of valid pixels "
  percent <- " %"
  min_thresh <- 70
  mean_thresh <- 70
  check_min <- min_cov < min_thresh # return warning below this
  check_mean <- mean_cov < mean_thresh # return warning below this 
  in_ts <- "in selection "
  warn_str <- "This warning is thrown when "
  if (length(selected) > 2) {
    warn_help <- paste0("\nIf you aim at a selection with consistent low cloud cover: ", arg_help_msg(1))
  } else {
    warn_help <- paste0("\nIf you aim at a selection with consistent low cloud cover: ", arg_help_msg(2))
  }
  warn_min <- ifelse(check_min, paste0("The lowest c", cov_pixels, in_ts, "is ", min_cov, percent, "\n", warn_help,
                                      "\n",warn_str,"the lowest coverage amongst all timestamps is below: ", min_thresh, percent,"."), "NULL")
  warn_mean <- ifelse(check_mean, paste0("The mean c", cov_pixels, in_ts, "is ", mean_cov, percent, "\n", warn_help,
                                        "\n",warn_str,"the mean coverage is below: ", mean_thresh, percent,"."), "NULL")
  warnings <- list(warn_min, warn_mean)
  return(warnings)
  
}

#' creates a static bar visualizing percentages as characters
#' @param x numeric vector
#' @param n integer specifies the number of chars that represents 100
#' @param bracket_symbols character vector
#' @keywords internal
#' @noRd
.create_numeric_bars <- function(x, n = 5, bar_symbol = "/", bracket_symbols = c("[", "]")) {
  bars <- paste0(bracket_symbols[1], .visual_numeric(x, symbol = bar_symbol, by = n))
  brackets <- sapply(bars, function(bar) {
    max_nbars <- as.integer(100 / n)
    nchar_bar <- nchar(bar) - 1 # due to bracket - 1
    gap <- (max_nbars) - nchar_bar
    gap <- ifelse(nchar_bar == max_nbars, 0, gap)
    space <- paste(rep(" ", gap), collapse="")
    offset <- max_nbars - (nchar(space) + nchar_bar)
    space <- ifelse(offset > 0, paste0(space, paste(rep(" ", offset), collapse="")), space)
    space <- ifelse(offset < 0, substr(space, 1, max_nbars), space)
    paste0(space, bracket_symbols[2])
  })
  bars <- paste0(bars, brackets)
  return(bars)
}

#' creates a character representation of a numeric with number of signs according to the numeric
#' @param x numeric vector
#' @param symbol character. Default is '/'
#' @param by integer specifies the value represented by a single symbol
#' @return visualx character vector
#' @keywords internal
#' @noRd
.visual_numeric <- function(x, symbol = "/", by = 20) {
  visualx <- sapply(x, function(value) {
    return(paste(rep(symbol, as.integer(value / by)), collapse = ""))
  })
  return(visualx)
}

#' creates a selection summary for a SAR selection
#' @param SAR_selected list of [[ids]] character vector of selected ids per timestamp, [[period]] character vector
#' of two dates and [[sub-period]] numeric the sub-period number.
#' @param records data.frame.
#' @param params list holding everything inserted into this parameter list in the calling select function.
#' @return \code{console_summary_warning} list of two character vectors holding the messages:
#' [[1]] Summary info
#' [[2]] Warning if minimum coverage of tiles does not reach number of tiles.
#' @keywords internal
#' @noRd
.select_SAR_summary <- function(records, selected_SAR, num_timestamps, params) {
  
  sep <- sep()
  covered_tiles_ts_wise <- sapply(selected_SAR,function(s) {
    num_tiles <- length(unique(records[match(s[["ids"]],records[[params$identifier]]),params$tileid_col]))
  })
  info <- c()
  for (i in 1:length(covered_tiles_ts_wise)) {
    num_tiles <- covered_tiles_ts_wise[i]
    info[i] <- paste0("Timestamp ",i," covers: ", num_tiles, ifelse(num_tiles > 1 || num_tiles == 0, " Sentinel-1 tiles", " Sentinel-1 tile"))
  }
  # check if for all timestamps all tiles are covered
  check_tile_cov <- which(covered_tiles_ts_wise != length(params$tileids))
  # return warning if check_tile_cov has length > 0
  le <- length(check_tile_cov)
  char <- c()
  for (x in check_tile_cov) char <- ifelse(le == 1,x,paste0(char,x,", "))
  if (num_timestamps > 2) {
    warn_msg <- paste0("\nFor timestamps: \n   ",char,
                       "\nnot all tiles could be covered with the given parameters.", arg_help_msg(1))
  } else {
    warn_msg <- paste0("\nFor timestamps: \n   ",char,
                       "\nnot all tiles could be covered with the given parameters.", arg_help_msg(2))
  }
  warning <- ifelse(le == 0, NA, warn_msg)
  console_summary_warning <- list(info, warning)
  return(console_summary_warning)
}

#' communicates the current coverage of valid pixels in select to user through .out()
#' @param base_coverage numeric.
#' @param i integer.
#' @param le_collection integer length of the records queue to look at.
#' @param sensor character sensor name.
#' @return nothing. Console communication
#' @keywords internal
#' @noRd
.select_out_cov <- function(base_coverage, i, le_collection, sensor) {
  cov <- round(base_coverage, 2)
  cov <- ifelse(cov > 100, 100, cov)
  i <- ifelse(i == 0, 1, i)
  checked_records <- paste0("[",i,"/", le_collection,"] ", sensor)
  bar <- .create_numeric_bars(cov)
  distance <- 34 - nchar(checked_records)
  distance <- ifelse(distance < 0, 1, distance)
  space <- " "
  space_after_product <- paste(rep(" ", times=distance), collapse="")
  out(paste0("\r", checked_records, space_after_product, bar, space, as.character(cov)," %"), flush = T)
}

#' catches and communicates the case where the records data.frame of a sub-period is empty.
#' @param records data.frame.
#' @param ts numeric which timestamp.
#' @param sensor character name of sensors
#' @return nothing. Optionally console warning.
#' @keywords internal
#' @noRd
.select_catch_empty_records <- function(records, ts, sensor = "unspecified") {
  if (NROW(records) == 0) {
    is_product_group <- sensor %in% c(name_product_group_modis(), name_product_group_landsat(), name_product_group_sentinel())
    out(paste0("No records of ", ifelse(is_product_group, "product group ", "product "), sensor, " at timestamp ", ts), msg=T)
  }
}

#' prints the timestamp selection completed character info
#' @param timestamp integer/numeric
#' @return nothing, print to console
#' @keywords internal
#' @noRd
.select_completed_statement <- function(timestamp) {out(paste0("Completed selection of timestamp: ", 
                                                               timestamp, "\n", sep()), msg=F)}

#' prints to console that selection proceeds to next product
#' @return nothing, print to console
#' @keywords internal
#' @noRd
.select_next_product <- function() {out("Selecting records of next product", msg=T)}

#' returns a character that can be used as help message for adjusting arguments
#' @param mode integer if 1 n_timestamps is included in the msg, otherwise not
#' @return arg_help_msg character
#' @keywords internal
#' @noRd
arg_help_msg <- function(mode = 1) {
  if (mode == 1) {
    return("\n
              - decrease 'n_timestamps',
              - decrease 'min_distance',
              - increase 'max_sub_period',
              - add another product\n")
  } else {
    return("\n
           - decrease 'min_distance',
           - increase 'max_sub_period',
           - add another product\n")
  }
}

.select_SAR_start <- function() {
  spaces <- paste(rep(" ", 6), collapse="")
  header <- paste0("Timestamp", spaces, "Available records", spaces, "Selected records")
  out(header, msg=F)
}

#' prints status of SAR selection at a timestamp
#' @param timestamp integer/numeric
#' @param selected_SAR_timestamp list of selected items at timestamp
#' @param n_available_records integer/numeric number of records that were available at this timestamp
#' @return nothing, prints to console
#' @keywords internal
#' @noRd
.select_SAR_timestamp_status <- function(timestamp, selected_SAR_timestamp, n_available_records) {
  space <- " "
  spaces <- paste(rep(space, 6), collapse="")
  n_selected <- as.character(length(selected_SAR_timestamp$ids))
  info <- paste0(timestamp, spaces, paste(rep(space, nchar("Timestamp") - nchar(as.character(timestamp))),
                                                 collapse=""), n_selected, spaces,
                 paste(rep(space, nchar("Available records") - nchar(n_selected)), collapse=""),
                 n_available_records)
  out(info)
}

#' finishs a SAR selection where only SAR records were given. Fills the records data.frame
#' return columns and creates final console summary + optional warning.
#' @param records data.frame.
#' @param selected_SAR list of [[ids]] character vector of selected ids per timestamp, [[period]] character vector
#' of two dates and [[sub-period]] numeric the sub-period number
#' @param params list holding everything inserted into this parameter list in the calling select function.
#' @return records data.frame with two added columns, ready for return to user.
#' @keywords internal
#' @noRd
.select_finish_SAR <- function(records, selected_SAR, num_timestamps, params) {
  sep <- sep()
  csw_SAR <- .select_SAR_summary(records, selected_SAR, num_timestamps, params)
  out(paste0(sep,"\nOverall Summary", sep))
  out(paste0("Number of timestamps: ", num_timestamps,"\n"))
  summary <- .out_vector(csw_SAR[[1]]) # SAR selection summary
  out(sep)
  rm(summary)
  w <- csw_SAR[[2]]
  if (!is.na(w)) out(w,type=2) # warning
  ids <- lapply(selected_SAR,function(x) {return(x[["ids"]])})
  # add columns to records
  cols <- c(params$selected_col,params$timestamp_col)
  records <- .select_prep_cols(records,cols,params$selected_col)
  for (ts in 1:length(ids)) {
    ids_match <- match(ids[[ts]],records[[params$identifier]])
    records[ids_match, params$selected_col] <- TRUE # is record selected at all
    records[ids_match, params$timestamp_col] <- ts # timestamp for which record is selected
  }
  return(records)
}

