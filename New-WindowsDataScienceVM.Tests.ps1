﻿
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')

Import-Module PSScriptAnalyzer
## Added PSAvoidUsingPlainTextForPassword as credential is an object and therefore fails. We can ignore any rules here under special circumstances agreed by admins :-)

## Ignored the credential and the comparison with null error as I do not want to influence the code. Dont think changint he credetial type would be a problem, not sure about the -ne $null


$Rules = Get-ScriptAnalyzerRule
$Name = $sut.Split('.')[0]

    Describe 'Script Analyzer Tests' {
            Context "Testing $Name for Standard Processing" {
                foreach ($rule in $rules) { 
                    $i = $rules.IndexOf($rule)
                    It "passes the PSScriptAnalyzer Rule number $i - $rule  " {
                        (Invoke-ScriptAnalyzer -Path "$PSScriptRoot\$sut" -IncludeRule $rule.RuleName ).Count | Should Be 0 
                    }
                }
            }
        }

    $commandName = $Name
	.$PSScriptRoot\$sut
    $command = Get-Command $CommandName
	# The module-qualified command fails on Microsoft.PowerShell.Archive cmdlets
	$Help = Get-Help $commandName -ErrorAction SilentlyContinue
	
	Describe "Test help for $commandName" {
		
		# If help is not found, synopsis in auto-generated help is the syntax diagram
		It "should not be auto-generated" {
			$Help.Synopsis | Should Not BeLike '*`[`<CommonParameters`>`]*'
		}
		
		# Should be a description for every function
		It "gets description for $commandName" {
			$Help.Description | Should Not BeNullOrEmpty
		}
		
		# Should be at least one example
		It "gets example code from $commandName" {
			($Help.Examples.Example | Select-Object -First 1).Code | Should Not BeNullOrEmpty
		}
		
		# Should be at least one example description
		It "gets example help from $commandName" {
			($Help.Examples.Example.Remarks | Select-Object -First 1).Text | Should Not BeNullOrEmpty
		}
		
		Context "Test parameter help for $commandName" {
			
			$Common = 'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable', 'OutBuffer', 'OutVariable',
			'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable'
			
			$parameters = $command.ParameterSets.Parameters | Sort-Object -Property Name -Unique | Where-Object { $_.Name -notin $common }
			$parameterNames = $parameters.Name
			$HelpParameterNames = $Help.Parameters.Parameter.Name | Sort-Object -Unique
			
			foreach ($parameter in $parameters)
			{
				$parameterName = $parameter.Name
				$parameterHelp = $Help.parameters.parameter | Where-Object Name -EQ $parameterName
				
				# Should be a description for every parameter
				It "gets help for parameter: $parameterName : in $commandName" {
					$parameterHelp.Description.Text | Should Not BeNullOrEmpty
				}
				
				# Required value in Help should match IsMandatory property of parameter
				It "help for $parameterName parameter in $commandName has correct Mandatory value" {
					$codeMandatory = $parameter.IsMandatory.toString()
					$parameterHelp.Required | Should Be $codeMandatory
				}
				
				# Parameter type in Help should match code
				It "help for $commandName has correct parameter type for $parameterName" {
					$codeType = $parameter.ParameterType.Name
					# To avoid calling Trim method on a null object.
					$helpType = if ($parameterHelp.parameterValue) { $parameterHelp.parameterValue.Trim() }
					$helpType | Should be $codeType
				}
			}
			
			foreach ($helpParm in $HelpParameterNames)
			{
				# Shouldn't find extra parameters in help.
				It "finds help parameter in code: $helpParm" {
					$helpParm -in $parameterNames | Should Be $true
				}
			}
		}
	}