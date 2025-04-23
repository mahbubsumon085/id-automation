# Reproducible data for ID related flaky test

This repository primarily contains Bash scripts for generating data artifacts for reproducible flaky tests. It takes as input ID-related flaky tests that have fixed versions from [IDoFT](https://github.com/TestingResearchIllinois/idoft) and produces zip files for [flaky-test-parser-tools](https://github.com/mahbubsumon085/flaky-test-parser-tools).  

## Prerequisites
- **Maven, Java, and libxml2-utils**: These tools are required to be installed on the system.  
- **Linux (Tested on Version 22)**: The bash script repository has been tested on Linux 22 and is recommended for optimal performance.  
- **Mac Compatibility**: The setup should be compatible with macOS as well. If you encounter any issues on macOS, please let us know.

### `Run the Rcript`

To execute the tool, run the `runner.sh script`. It will invoke process_id_test.sh, which reads from `id_accepted_uiuc.csv` and uses various scripts to generate ZIP files, storing them in the data folder.


## `Input`

The input to the scrpts is `id_accepted_uiuc.csv` which contains pull request for id-related flaky test from [IDoFT](https://github.com/TestingResearchIllinois/idoft)


## Output
The Output is the zip data which will be used by [flaky-test-parser-tools](https://github.com/mahbubsumon085/flaky-test-parser-tools), the zipped data file contains:

- **`Flaky`**:  
  Contains the source code that includes the flaky test. 

- **`Fixed.patch`**:  
  A patch file used to generate the fixed version of the source code from the `Flaky` folder.

- **`Flakym2`**:  
  A directory used to store the `.m2` repository for maven dependencies during test execution. This ensures that the containerized environment can access required dependencies efficiently without re-downloading them for each run.

- **`Fixedm2`**:  
  A directory used to store the `.m2` repository for maven dependencies specific to the fixed version. If the dependencies for the fixed version are the same as those in `Flakym2`, this directory will not be present in the data directory, as `Flakym2` can handle Maven execution requirements.


## Important Folders and Files

The following are the key files for ID related flaky data set preparation:

- **`clone_if_needed.sh`**:  
   A Bash script that ensures the specified Git repository is cloned only if it hasn't been downloaded already. Given a Git URL as input, it checks if the repository exists under the `code/` directory. If the repository is not present, it clones it into that directory; otherwise, it skips the operation to avoid redundant downloads.

- **`create_data_folders.sh`**:  
   A Bash script that sets up the standard directory structure required for flaky test analysis. When provided with a folder name, it creates a base directory under `data/` and initializes the subdirectories `Fixed`, `Flaky`, `Flakym2`, and `Fixedm2`. These folders are used to store the source code versions and Maven dependency caches for test execution..
`

- **`copy_to_flaky_fixed.sh`**:  
  A Bash script that prepares the `Flaky` and `Fixed` directories for test analysis by copying source code and checking out specific Git SHAs. It performs the following steps:
  - Copies a cloned Git repository into both `Flaky` and `Fixed` folders inside the target data directory.
  - Checks out the specified SHA in the `Flaky` folder.
  - Uses the pull request link(found from input data) to retrieve the merged commit sha and check out the merged commit SHA in the `Fixed` folder.
  - The script updates the merged commit sha in the`id_accepted_uiuc.csv` if found, else markes it as not-found .
  This script ensures both versions of the source code are correctly prepared for reproducible test analysis.

 
- **`id_jdk8_statistics_generator.sh`**:  
  A Bash script designed to detect and analyze implementation-dependent flaky tests using the [NonDex](https://github.com/TestingResearchIllinois/NonDex) plugin with JDK 8. This script runs the specified test method multiple times under randomized execution orders to identify inconsistencies. It performs the following operations:
  - Builds the specified Maven module with tests skipped.
  - Executes the test method using NonDex for the configured number of iterations.
  - Extracts execution IDs and random seeds from the NonDex output.
  - Parses each generated Surefire XML report using `xmllint` to determine test outcomes.
  - Logs all relevant data into a structured CSV file (`rounds-test-results.csv`) and outputs a summary (`summary.txt`) including pass, failure, and error counts.
  - Stores individual test logs and result files under the `flaky-result/` directory for further inspection.

- **`run_test_on_flaky_directory.sh`**:  

   A Bash script that automates the execution of an implementation-dependent (ID) flaky test using the NonDex plugin within the `Flaky` code directory. It performs the following operations:
  - Copies `id_jdk8_statistics_generator.sh` into the provided `Flaky` directory and executes it with the given module and test method for a specified number of iterations.
  - Extracts the total number of test rounds completed from the output.
  - Moves the `.m2` Maven repository directory (if it exists) to a `Flakym2` directory one level above the `Flaky` folder, preserving Maven dependencies for reuse.
  - Outputs the total number of test rounds for further automation or logging.

- **`run_test_on_fixed_directory.sh`**:  

   A Bash script that automates the execution of an implementation-dependent (ID) flaky test using the NonDex plugin within the `Fixed` code directory. It performs the following operations:
  - Copies `id_jdk8_statistics_generator.sh` into the provided `Fixed` directory and executes it with the given module and test method for a specified number of iterations.
  - Extracts the total number of test rounds completed from the output.
  - Moves the `.m2` Maven repository directory (if it exists) to a `Fixedm2` directory one level above the `Fixed` folder, preserving Maven dependencies for reuse.
  - Outputs the total number of test rounds for further automation or logging.

- **`get_merged_commit.sh`**:  

  A Bash script that retrieves the merged commit SHA of a given GitHub pull request using the GitHub REST API. It performs the following:
  - Parses the GitHub PR URL to extract the repository owner, name, and pull request number.
  - Sends an authenticated API request to retrieve PR metadata.
  - Extracts and returns the `merge_commit_sha` if the pull request has been merged.
  - Handles common API errors, such as rate limits, invalid tokens, or nonexistent PRs.

- **`create_zip_and_patch.sh`**:  

  A Bash script that generates a reproducible dataset for flaky test analysis by creating a patch and zipped archive from two Git commits. It performs the following:
  - Clones the specified source project into two separate directories: one for the flaky commit and one for the fixed commit.
  - Checks out the flaky and fixed versions based on the provided commit SHAs.
  - Creates a unified diff (`Fixed.patch`) between the flaky and fixed versions.
  - Removes the `.git` folders to avoid unnecessary data.
  - Deletes the fixed directory after generating the patch.
  - Packages the entire folder (`Flaky/` and `Fixed.patch`) into a ZIP file under the `data/` directory.
  
  This script is essential for preparing reproducible flaky test cases that can later be consumed by analysis tools like `flaky_analysis_tool_id.sh` in [flaky-test-parser-tools](https://github.com/mahbubsumon085/flaky-test-parser-tools). Recreating the source code is necessary at this stage because the previous NonDex-based test execution may have generated temporary or unnecessary files. 

- **`id_accepted_uiuc.csv`**:  

  - **`id_accepted_uiuc.csv`**:  
  A curated CSV dataset containing metadata for accepted implementation-dependent (ID) flaky tests sourced from the [IDoFT](https://github.com/TestingResearchIllinois/idoft) dataset. Each row includes:
  - Project URL and commit SHA where the flaky behavior was observed.
  - Maven module path and the fully-qualified test method name.
  - Category and status (e.g., ID, Accepted).
  - Associated pull request link(s) and notes.
  - New columns will be created for tracking merge commit SHAs or fixed version references.

  This file is used by automation scripts such as `process_id_test.sh` and `copy_to_flaky_fixed.sh` to guide the creation and testing of reproducible flaky test artifacts.

- **`process_id_test.sh`**:  
  A comprehensive Bash automation script that processes each row in the `id_accepted_uiuc.csv` dataset to prepare and execute implementation-dependent (ID) flaky test analysis. For each test entry, the script:
  - Clones the associated GitHub repository (if not already cloned).
  - Creates a standardized directory structure under `data/`.
  - Copies the source code to both `Flaky` and `Fixed` directories.
  - Uses the PR link to determine the merged commit SHA and checks out the flaky and fixed versions.
  - Runs NonDex-based test executions on both versions and evaluates the results.
  - If both runs are successful and the test is reproducibly flaky, it creates a `Fixed.patch` and compresses the dataset into a ZIP archive.
  - Appends a new entry to `test_config.csv` to register the flaky test for further analysis using `runner.sh` in for [flaky-test-parser-tools](https://github.com/mahbubsumon085/flaky-test-parser-tools).

  This script is the backbone of batch dataset generation and automates the end-to-end pipeline from raw metadata to fully prepared test artifacts.


