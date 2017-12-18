# Gauge SIS Imports PowerShell Example

This directory contains an example of how to use the sis_imports Gauge API to import a collection of Gauge (similar to Canvas) formatted CSVs.

## Pre-reqs to run this script:

* PowerShell 5 or higher

## You will need to alter the following variables during the setup process:

* $source_path:  Source path containing the CSV files to import. (Must end in a \\)
* $output_path: Output path for the zip file that will be imported into Canvas. (Must end in a \\)
* $api_token: Gauge API access token.
* $gauge_url: Full URL to your Gauge instance (without https://). Should look something like "school.gauge-iad-prod.instructure.com"
* $output_zip: Name of the .zip file to create. For example "gauge_import.zip". (You do not need to change the default)
* $sleep_time: The number of seconds to wait between starting the import and checking on the import status.
