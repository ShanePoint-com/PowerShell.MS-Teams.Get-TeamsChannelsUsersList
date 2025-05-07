# ----------------------------------------------------------
# Script: Get-MSFT-Teams-Teams-Channels-Users-List.ps1
# Purpose: Export all Teams and Channels Members with role e.g. owner or member status to a CSV file
# Prerequisites: PowerShell (7.0 or later) and MicrosoftTeams module are installed and properly configured
# ----------------------------------------------------------

# Connect to Microsoft Teams (an interactive login window will appear in your browser)
Connect-MicrosoftTeams

# Create a collection to store the export results
$results = @()

# Retrieve all teams in your tenant
$teams = Get-Team

# Loop through each team
foreach ($team in $teams) {
    Write-Host "Processing Team: $($team.DisplayName)" -ForegroundColor Cyan

    # Attempt to get all channels for this team
    try {
        $channels = Get-TeamChannel -GroupId $team.GroupId -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to retrieve channels for team '$($team.DisplayName)'. Skipping team." -ForegroundColor Red
        continue
    }

    # Retrieve team membership (this returns both owners and members)
    try {
        $teamMembers = Get-TeamUser -GroupId $team.GroupId -ErrorAction Stop
    }
    catch {
        Write-Host "Unable to retrieve members for team '$($team.DisplayName)'. Skipping team." -ForegroundColor Red
        continue
    }

    # Loop through each channel in the team
    foreach ($channel in $channels) {
        Write-Host "   Processing Channel: $($channel.DisplayName)" -ForegroundColor Yellow

        # Check if the channel is a standard channel, private channel, or shared channel
        switch ($channel.MembershipType) {

            "Private" {
                try {
                    $channelMembers = Get-TeamChannelUser -GroupId $team.GroupId -DisplayName $Channel.DisplayName -ErrorAction Stop
                }
                catch {
                    Write-Host "Unable to retrieve private channel members for channel '$($channel.DisplayName)' in team '$($team.DisplayName)'. Using team membership instead." -ForegroundColor Red
                    $channelMembers = $teamMembers
                }
            }

            "Shared" {
                try {
                    $channelMembers = Get-TeamChannelUser -GroupId $team.GroupId -DisplayName $Channel.DisplayName -ErrorAction Stop
                }
                catch {
                    Write-Host "Unable to retrieve shared channel members for '$($channel.DisplayName)' in '$($team.DisplayName)'. Using team membership instead." -ForegroundColor Red
                    $channelMembers = $teamMembers
                }
            }

            "Standard" {
                # Standard channels inherit the team’s membership
                $channelMembers = $teamMembers
            }

            Default {
                # Just in case MS adds other types of channels down the road
                $channelMembers = $teamMembers
            }

        }

        # Loop through each member for this channel
        foreach ($member in $channelMembers) {

            # Determine the member's display name.
            # Some objects might include a "Name" property; if not, we use the "User" (email) property.
            $memberName = if ($member.PSObject.Properties.Name -contains "Name") { $member.Name } else { $member.User }

            # Check if the member's role is Owner. For private channels, the role property should be returned.
            $isOwner = if ($member.Role -eq "Owner") { 'Owner' } else { 'Member' }

            # For basic type is "Team" or it's "Channel".
            $TeamTypeName = if ($channel.DisplayName -eq "General") { "Team" } else { "Channel" }

            # Create a custom object with the gathered information
            $results += [PSCustomObject]@{
                TeamType        = $TeamTypeName
                TeamDisplayName = $team.DisplayName
                TeamGroupId     = $team.GroupId
                ChannelName     = $channel.DisplayName
                ChannelId       = $channel.Id
                MemberName      = $memberName
                MemberEmail     = $member.User
                IsOwner         = $isOwner
                MembershipType  = $channel.MembershipType
            }
        }
    }
}

# Define the export path (this example exports the CSV to your Documents folder)
$exportPath = "$env:USERPROFILE\Documents\Teams-Channels-Users-List.csv"

# Export the results to a CSV file
$results | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8

Write-Host "`n✅ Export complete! CSV file saved at:" -ForegroundColor Green
Write-Host $exportPath -ForegroundColor Green

# Disconnect from Microsoft Teams
Disconnect-MicrosoftTeams
