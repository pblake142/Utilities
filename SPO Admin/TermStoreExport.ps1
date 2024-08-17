## Credit to https://pnp.github.io/script-samples/spo-export-termstore-terms-to-csv/README.html ##

###### Declare and Initialize Variables ######  

#site url
$url="Site admin site url"

#term store variables
$groups = @("Group 1","Group 2") # leave empty for exporting all groups

# data will be saved in same directory script was started from
$saveDir = (Resolve-path ".\")  
$currentTime= $(get-date).ToString("yyyyMMddHHmmss")  
$FilePath=".\TermStoreReport-"+$currentTime+".csv"  
Add-Content $FilePath "Term group name, Term group ID, Term set name, Term set ID, Parent Term Name, Parent Term ID, Term name, Term ID"
## Recursive function to export terms regardless of depth ##
function ExportTermsRecursively {
    param(
        [Parameter(Mandatory = $true)]
        $term,
        $termGroupObj,
        $termSetObj,
        $parentTermName = "",
        $parentTermId = ""
    )
    Add-Content $FilePath "$($termGroupObj.Name),$($termGroupObj.Id),$($termSetObj.Name),$($termSetObj.Id),$parentTermName,$parentTermId,$($term.Name),$($term.Id)"
    $childTerms = Get-PnPTerm -TermSet $termSetObj.Id -TermGroup $termGroupObj.Name -Identity $term.Id -Includes Terms
    foreach ($childTerm in $childTerms.Terms) {
        ExportTermsRecursively -term $childTerm -termGroupObj $termGroupObj -termSetObj $termSetObj -parentTermName $term.Name -parentTermId $term.Id
    }
}

## Export List to CSV ##  
function ExportTerms
{  
    try  
    {  
        if($groups.Length -eq 0){
            $groups = @(Get-PnPTermGroup | ForEach-Object{ $_.Name })
        }
        # Loop through the term groups
        foreach ($termGroup in $groups) {
            try {
                $termGroupName = $termGroup
                Write-Host "Exporting terms from $termGroup"
                $termGroupObj = Get-PnPTermGroup -Identity $termGroupName -Includes TermSets
                foreach ($termSet in $termGroupObj.TermSets) {
                    $termSetObj = Get-PnPTermSet -Identity $termSet.Id -TermGroup $termGroupName -Includes Terms
                    foreach ($term in $termSetObj.terms) {
                        ExportTermsRecursively -term $term -termGroupObj $termGroupObj -termSetObj $termSetObj
                    }
                }
            } catch {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
            
        }
     }  
     catch [Exception]  
     {  
        $ErrorMessage = $_.Exception.Message         
        Write-Host "Error: $ErrorMessage" -ForegroundColor Red          
     }  
}  
 
## Connect to SharePoint Online site  
Connect-PnPOnline -Url $Url -Interactive
 
## Call the Function  
ExportTerms
 
## Disconnect the context  
Disconnect-PnPOnline  