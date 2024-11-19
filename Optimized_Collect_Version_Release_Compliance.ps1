# Define the base URL
$baseUrl = "https://www.microsoft.com/en-us/wdsi/definitions/antimalware-definition-release-notes?requestVersion="

# Define regular expression to match version numbers.
$versionRegex = '\b\d+\.\d+\.\d+\.\d+\b'

# Define regular expression to match release dates.
$dateRegex = '\b(\d{1,2}/\d{1,2}/\d{4}) \d{1,2}:\d{2}:\d{2} [AP]M\b'

# Array to store unique versions
$uniqueVersions = @()

# Get HTML content from the main page
$response = Invoke-WebRequest -Uri $baseUrl
$htmlContent = $response.Content

# Get unique versions
foreach ($match in [regex]::Matches($htmlContent, $versionRegex)) {
    $version = $match.Value
    if ($version -notin $uniqueVersions) {
        $uniqueVersions += $version
    }
}

# Array to store updates
$updates = @()

# Define a function to fetch release date for a given version
function GetReleaseDate {
    param (
        [string]$version
    )
    $url = $baseUrl + $version
    $global:requestCounter++
    $response = Invoke-WebRequest -Uri $url
    $dateString = [regex]::Match($response.Content, $dateRegex).Groups[1].Value

    # Parse the date string with the expected format
    $releaseDate = [DateTime]::ParseExact($dateString, "M/d/yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
    return $releaseDate
}

# Initialize request counter
$global:requestCounter = 0

# Get current date
$currentDate = Get-Date

# Loop through unique versions and fetch release date
foreach ($version in $uniqueVersions) {
    # Exclude specific versions
    if ($version -notin @("2.2.2.6", "2.2.3.6", "1.0.0.0")) {
        $date = GetReleaseDate $version
        if ($date -ne $null) {
            # Calculate compliance
            $compliance = ($currentDate - $date).Days
            $complianceText = "N"
            if ($compliance -gt 0) {
                $complianceText = "N-$compliance"
            }

            # Create a custom object for each update
            $update = [PSCustomObject]@{
                Version = $version
                ReleasedDate = $date.ToString("MM-dd-yyyy")
                Compliance = $complianceText
            }

            # Add the update to the array
            $updates += $update
        }
    }
}

# Output the updates
Write-Output $updates

# Output the number of requests generated
Write-Output "Total requests generated: $global:requestCounter"
