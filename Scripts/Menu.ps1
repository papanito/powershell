function Show-Menu
{
     param (
           [string]$Title = 'My Menu'
     )
     cls
     Write-Host "================ $Title ================"
     
     foreach($element in $software.GetEnumerator())
     {
        Write-Host "$($element.Key)"
     }

    Write-Host "all (install all software)"
    Write-Host "quit"
}


do
{
     Show-Menu
     $input = Read-Host "Please make a selection"
     switch ($input)
     {
        'all' {
            cls
            foreach($element in $software.GetEnumerator())
            {
                InstallSW $element.Value
            }
            return
        } 
        'quit'
        {
            return
        } 
        default 
        {
            cls
            if ($software.$input) 
            {
                InstallSW $software.$input
            }
            else 
            {
                Write-Host "Selection '$input' invalid"
            }
        }
    }
    pause
}
until ($input -eq 'q')