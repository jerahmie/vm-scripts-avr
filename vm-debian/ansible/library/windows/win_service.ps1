#!powershell
# This file is part of Ansible
#
# Copyright 2014, Chris Hoffman <choffman@chathamfinancial.com>
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

$params = Parse-Args $args;

$result = New-Object PSObject;
Set-Attr $result "changed" $false;

If (-not $params.name.GetType)
{
    Fail-Json $result "missing required arguments: name"
}

If ($params.state) {
    $state = $params.state.ToString().ToLower()
    If (($state -ne 'started') -and ($state -ne 'stopped') -and ($state -ne 'restarted')) {
        Fail-Json $result "state is '$state'; must be 'started', 'stopped', or 'restarted'"
    }
}

If ($params.start_mode) {
    $startMode = $params.start_mode.ToString().ToLower()
    If (($startMode -ne 'auto') -and ($startMode -ne 'manual') -and ($startMode -ne 'disabled')) {
        Fail-Json $result "start mode is '$startMode'; must be 'auto', 'manual', or 'disabled'"
    }
}

$svcName = $params.name
$svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
If (-not $svc) {
    Fail-Json $result "Service not installed"
}

If ($startMode) {
    $svcMode = Get-WmiObject -Class Win32_Service -Property StartMode -Filter "Name='$svcName'"

    If ($svcMode.StartMode.ToLower() -ne $startMode) {
        Set-Service -Name $svcName -StartupType $startMode
        Set-Attr $result "changed" $true
    }
}

If ($state) {
    If ($state -eq "started" -and $svc.Status -ne "Running") {
        Start-Service -Name $svcName
        Set-Attr $result "changed" $true;
    }
    ElseIf ($state -eq "stopped" -and $svcName -ne "Stopped") {
        Stop-Service -Name $svcName
        Set-Attr $result "changed" $true;
    }
    ElseIf ($state -eq "restarted") {
        Restart-Service -Name $svcName
        Set-Attr $result "changed" $true;
    }
}

Exit-Json $result;
