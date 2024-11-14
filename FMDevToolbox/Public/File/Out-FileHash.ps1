using namespace System.Security.Cryptography
using namespace System.IO
function Out-FileHash {
	param(
		[Parameter(Mandatory,Position=0,ValueFromPipeline)]
        [String[]] $Path,
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateSet('ALL','SHA1','SHA256','SHA384','SHA512','MD5')]
		[string] $Algorithm = 'SHA256',
		[int64] $BufferSize = 1mb,
		[switch] $NoProgress = $false
	)
	begin {
        $AlgorithmObject = [HashAlgorithm]::Create($Algorithm);
		$ErrorOccurred = $false;
	}
	process {

        foreach ($File in $Path) {

            $FullFilepath = [Path]::GetFullPath($File)
            $FileStream = [File]::OpenRead($FullFilepath);
            $CryptoStream = [CryptoStream]::new(([Stream]::Null), $AlgorithmObject, "Write");
            $Buffer = New-Object Byte[] $BufferSize;

            while ($BytesRead = $FileStream.Read($Buffer, 0, $BufferSize)){
                if (!$NoProgress) {
                    $Filename = [System.IO.Path]::GetFileNameWithoutExtension($File)
                    [Decimal] $ProgressRaw = $FileStream.Position / $FileStream.Length
                    [String] $Status = "Progress: {0:P2}" -f $ProgressRaw
                    $PercentComplete = $ProgressRaw * 100
                    $CurrentOperation = "{0} of {1} bytes hashed" -f $FileStream.Position, $FileStream.Length
                    $WriteProgressSplat = @{
                        Id                    = 2
                        Activity              = "Out-FileHash is processing $Filename ($Algorithm)..."
                        Status                = $Status
                        PercentComplete       = $PercentComplete
                        CurrentOperation      = $CurrentOperation
                    }

                    Write-Progress @WriteProgressSplat
                }

                # Write to the Stream from the buffer and then flush the CryptoStream block queue.
                $CryptoStream.Write($Buffer, 0, $BytesRead);
                $CryptoStream.Flush();
            }
            $FileStream.Close(); $FileStream.Dispose();

            # Finalize the CryptoStream, store the result into the table, and then dispose of
            # the CryptoStream and HashAlgorithm provider.
            $CryptoStream.FlushFinalBlock();

            $FinalFileObject = Get-Item -Path $FullFilepath -Force
            $FinalFileHash = ($AlgorithmObject.Hash | ForEach-Object { $_.ToString("X2") }) -join ''
            $FinalFileRelativeName = ($FinalFileObject.FullName).Replace($FullFilepath, ".\")
            $FinalFileTimespanStart = [timezone]::CurrentTimeZone.ToLocalTime([datetime]'1/1/1970')
            $FinalFileTimespan = New-TimeSpan -Start $FinalFileTimespanStart -End $FinalFileObject.LastWriteTime
            $FinalFileLastWriteTime = $FinalFileTimespan.TotalMilliseconds -as [Int64]
            $FinalFileSize = $FinalFileObject.Length
            $FT = [PSCustomObject]@{
                FullName      = ($FinalFileObject.FullName)
                RelativeName  = $FinalFileRelativeName
                Size          = $FinalFileSize
                LastWriteTime = $FinalFileLastWriteTime
                Hash          = $FinalFileHash
            };
            $FileStream.Close()
            $FileStream.Dispose()
            $CryptoStream.Close()
            $CryptoStream.Dispose()
            $AlgorithmObject.Dispose();
        }
	}
	end {
		if (($Combine -And ($ErrorOccurred -Eq $false)) -Or ((-Not $Combine) -And ($ErrorOccurred -Eq $false))) {
			$result = $FT;
		} else {
			$result = $null;
		}
		$result
	}
}