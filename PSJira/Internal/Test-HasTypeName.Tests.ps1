﻿$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

InModuleScope PSJira {
    Describe "Test-HasTypeName" {

        $customTypeName1 = 'PSJira.Demo'
        $customTypeName2 = 'PSJira.Test'
        $customTypeName3 = 'PSJira.Fail'
        $testObject = New-Object -TypeName PSObject -Property @{hello="world"}
        $testObject.PSObject.TypeNames.Insert(0,$customTypeName1)
        $testObject.PSObject.TypeNames.Add($customTypeName2)

        It "Confirms that TRUE is returned where a typename is in an object's type names" {
            $testObject | Test-HasTypeName $customTypeName1 | Should Be $True
            $testObject | Test-HasTypeName $customTypeName2 | Should Be $True
            $testObject | Test-HasTypeName 'System.Management.Automation.PSCustomObject' | Should Be $True
            $testObject | Test-HasTypeName 'System.Object' | Should Be $True
        }

        It "Confirms that FALSE is returned where a typename is in an object's type names" {
            $testObject | Test-HasTypeName $customTypeName3 | Should Be $False       
        }

    }
}
