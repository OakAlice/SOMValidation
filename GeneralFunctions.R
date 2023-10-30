# Now this will be the code that creates the SOM from the training and testing data we created

# find all instances of a file type
find_all_instances <- function(root_dir, pattern) {
  list.files(root_dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
}

# ensure directories
ensure_dir <- function(dir_name) {
  if (!dir.exists(dir_name)) {
    dir.create(dir_name, showWarnings = FALSE)
  }
}

# Function to subset and rename columns to match the general format
subset_and_rename <- function(df, column_map) {
  # Check if all columns in the mapping exist in the dataframe
  if (all(names(column_map) %in% colnames(df))) {
    # Subset the dataframe
    df <- df[, names(column_map)]
    
    # Rename the columns
    colnames(df) <- column_map
    
    return(df)
  } else {
    stop("Some columns from the mapping are missing in the dataframe.")
  }
}
