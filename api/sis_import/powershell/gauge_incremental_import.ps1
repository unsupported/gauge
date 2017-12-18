#  Gauge SIS Import Sample Script
#   This is a very basic sample script using the Gauge SIS import API.
#   This script is provided AS-IS without warranty or guarantee of any kind
#   and is not supported by Instructure.
#
# Working as of 2017-12-18
#
#  Requirements:
#     * PowerShell version 5 or higher

$version = "20171218-3"

$source_path = "c:\gauge\import\in\" # Full path to input CSV files.  (must end in in \)
$output_path = "c:\gauge\import\out\" # Full path to archive sent .zip file. Also used for temp space during upload. (must end in in \)
$api_token = "" # Gauge API Token
$gauge_url = "school.gauge-iad-prod.instructure.com" # Gauge URL without any path and do NOT include https://
$output_zip = "gauge_import.zip" # Name of the zip file to create. You can leave this alone.
$sleep_time = 60 # Number of seconds to wait between starting import and pulling one sample status.

#################################################
###### Don't edit anything after this line ######
#################################################
$api_url = "https://$gauge_url/api/sis_imports"

# Just in case $source_path or $output_path doesn't end with a \, add it.
if(!($source_path.EndsWith('\'))){
    $source_path += "\"
    Write-Host "Your source_path didn't end with a \ so I added one.  It really is important"
}
if(!($output_path.EndsWith('\'))){
    $output_path += "\"
    Write-Host "Your output_path didn't end with a \ so I added one.  It really is important"
}
# Make sure $output_zip does not include a \
if($output_zip.Contains('\')){
    Write-Host "The output_zip should not contain backslashes.  Script terminated."
    exit
}
# See if there are any CSV files in $source_path
$csv_path = $source_path+"*.csv"
$csv_dir = dir $csv_path
if($csv_dir.count -eq 0){
    Write-Host "The source_path does not contain any CSV files. Terminating script."
    exit
}
$upload_file = $output_path+$output_zip
Write-Host "Compressing .csv files in $source_path to $upload_file"
Compress-Archive -Path $csv_path -DestinationPath $upload_file -Force

# Encoding file for multipart form.
Write-Host "Getting $upload_file encoded and ready to upload"
$encoding = [System.Text.Encoding]::GetEncoding("iso-8859-1")
$endcoded_upload_file = $encoding.GetString([IO.File]::ReadAllBytes($upload_file))

# Building Multipart form body.
$boundry = "FB"+[guid]::NewGuid()
$content_type = "multipart/form-data; boundary=$boundry"
$lb = "`r`n"
$form_array=("--$boundry",
    "Content-Disposition: form-data; name=`"sis_import[archive]`"; filename=`"$output_zip`"",
    "Content-Type: application/octet-stream$lb",
    "$endcoded_upload_file",
    "--$boundry",
    "Content-Disposition: form-data; name=`"sis_import[incremental]`"$lb",
    "true",
    "--$boundry--$lb")
$form_body = [string]::Join($lb,$form_array)
$form_info = $form_body | Measure-Object -Character
$form_length = $form_info.Characters

Write-Host "Sending imporing file to $api_url"
$headers = @{'Accept'='*/*';"Authorization"="Token $api_token";"Content-Length"=$form_length}
$results1 = (Invoke-WebRequest -Headers $headers -Method POST -ContentType $content_type -Uri $api_url -Body $form_body) 

# Logging results
$t = get-date -format M_d_y_h
$status_log_path = $output_path+$t+"-status.log"
$results1.Content | Out-File $status_log_path
$results = ($results1.Content | ConvertFrom-Json)
Write-Host "Here is what happened: `n" $results

# Sleeping for a bit
Write-Host "Pausing for " $sleep_time " seconds."
Start-Sleep -s $sleep_time

# Checking status of import
$status_url = "$api_url/"+$results.id
Write-Host "Checking for results from " $status_url
$results2 = (Invoke-WebRequest -Headers $headers -Method GET -Uri $status_url) #-PassThru -OutFile $output_path$t"-status.log"

# Logging status update
$results2.Content | Out-File -Append $status_log_path
$sresults = ($results2.Content | ConvertFrom-Json)
Write-Host "Here is an update on the import: `n" $sresults

# Renaming uploaded .zip file
Move-Item -Force $output_path$output_zip $output_path$t-$output_zip
# Clearing source_path of CSV files
Remove-Item $source_path*.csv
