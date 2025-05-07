<# ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DISCLAIMER...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LEGAL NOTICE...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Herein forward Software, App, Code, Agent, Source, Template, all mean the same thing as "Software" and are under the MIT License and solely the responsibility thereof the consumer and/or user of said Software.

This Software is provided under the MIT License terms (See below). In addition to these terms, by using this Software you agree to the following:

You are responsible for complying with all applicable privacy and security regulations related to use, collection, and handling of any personal data by your Software. 
This includes complying with all internal privacy and security policies of your organization.

Where applicable, you may be responsible for data related incidents or data subject requests for data collected through your Software.

Any trademarks or registered trademarks of Microsoft (Or other 3rd party companies e.g. ServiceNow, Workday, Salesforce, etc.) in the United States and/or other countries and logos included in this repository are the property of Microsoft (And other said companies) and the license for this project does not grant you rights to use any Microsoft (Or other companies) names, logos or trademarks outside of this repository. Microsoft's general trademark guidelines can be found on their website.


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LICENSING NOTICE...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

MIT License
Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DISCLAIMER...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 #>

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

<# ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DISCLAIMER...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LEGAL NOTICE...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Herein forward Software, App, Code, Agent, Source, Template, all mean the same thing as "Software" and are under the MIT License and solely the responsibility thereof the consumer and/or user of said Software.

This Software is provided under the MIT License terms (See below). In addition to these terms, by using this Software you agree to the following:

You are responsible for complying with all applicable privacy and security regulations related to use, collection, and handling of any personal data by your Software. 
This includes complying with all internal privacy and security policies of your organization.

Where applicable, you may be responsible for data related incidents or data subject requests for data collected through your Software.

Any trademarks or registered trademarks of Microsoft (Or other 3rd party companies e.g. ServiceNow, Workday, Salesforce, etc.) in the United States and/or other countries and logos included in this repository are the property of Microsoft (And other said companies) and the license for this project does not grant you rights to use any Microsoft (Or other companies) names, logos or trademarks outside of this repository. Microsoft's general trademark guidelines can be found on their website.


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LICENSING NOTICE...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

MIT License
Copyright (c) 2025

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DISCLAIMER...
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 #>
