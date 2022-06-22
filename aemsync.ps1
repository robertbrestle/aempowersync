### aemsyncps - VSCode extension for easily integrating with your local AEM instance

# Run with PS 6.1+
#   Required for Invoke-RestMethod "-Form" parameter
#   Requires either native tar.exe OR 7z installed + set in PATH environment variable

# localhost:4502/system/console/configMgr
#  Apache Sling Referrer Filter => Enable allow empty, Remove POST
#    http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter
#  Adobe Granite CSRF Filter => remove POST
#    http://localhost:4502/system/console/configMgr/com.adobe.granite.csrf.impl.CSRFFilter
param(
	[Parameter(Mandatory=$True)]
	[String] $ACTION,
	[Parameter(Mandatory=$True)]
	[String] $INPUTFILE,
	[Parameter(Mandatory=$True)]
	[String] $AEMSERVER,
	[Parameter(Mandatory=$True)]
	[String] $AEMCREDS,
	[Parameter(Mandatory=$True)]
	[String] $USE7ZPARAM
)

try {
	$USE7Z = [System.Convert]::ToBoolean($USE7ZPARAM)
}catch [FormatException] {
	echo "Invalid use7z parameter. Defaulting to False."
	$USE7Z = $false
}

# if script is run from the terminal, exit
if($INPUTFILE -eq "undefined") {
	echo "Error: no path specified. Exiting."
	exit
}

# DO NOT RUN THIS AGAINST HIGHER ENVIRONMENTS !!
#$AEMSERVER="http://localhost:4502"
#$AEMCREDS="admin:admin"
# DO NOT RUN THIS AGAINST HIGHER ENVIRONMENTS !!
$AEMPACKMGR="/crx/packmgr/service/.json"
$AEMPACKMGRUPLOAD="/crx/packmgr/service.jsp"
$AEMPACKAGES="/etc/packages/"

$TMPPKG="aemsyncpkg.zip"
$TMPPKGFOLDER="aempowersync"

#############################################################################

# generate AEM headers
$encodedCreds=[System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($AEMCREDS))
$AEMHeaders = @{
    Authorization="Basic ",$encodedCreds -Join ""
}

# replace
$INPUTFILE=($INPUTFILE -replace "file:///", "" -replace "%3A", ":")
$AEMFILE=($INPUTFILE -replace ".*jcr_root", "" -replace "\\", "/")
# get type
if((Get-Item $INPUTFILE) -is [System.IO.DirectoryInfo]) {
	$TYPE="folder"
}else {
	$TYPE="file"
}

#############################################################################

function create_base_package() {
	try {
		# delete old package artifacts
		if(Test-Path jcr_root) {
			Remove-Item -Force -Recurse jcr_root
		}
		if(Test-Path META-INF) {
			Remove-Item -Force -Recurse META-INF
		}
		
		# create folders
		New-Item -F $TMPPKGFOLDER/META-INF/vault -ItemType "directory" | Out-Null
		New-Item -F $TMPPKGFOLDER/jcr_root -ItemType "directory" | Out-Null
		
		$FILTER = "<?xml version=""1.0"" encoding=""UTF-8""?><workspaceFilter version=""1.0""><filter root=""", $AEMFILE, """/></workspaceFilter>" -Join ""
		
		$PROPERTIES = "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""no""?><!DOCTYPE properties SYSTEM ""http://java.sun.com/dtd/properties.dtd""><properties><entry key=""name"">aempowersync</entry><entry key=""version"">1.0.0</entry><entry key=""group"">aempowersync</entry></properties>"
		
		Add-Content -Path $TMPPKGFOLDER/META-INF/vault/filter.xml -Value $FILTER
		Add-Content -Path $TMPPKGFOLDER/META-INF/vault/properties.xml -Value $PROPERTIES

		return $true
	}catch {
		echo "Error: issues creating base package. Try re-launching VSCode as an Administrator."
	}
	return $false
}

function zip_package() {
	# delete old package artifacts
	if(Test-Path $TMPPKG) {
		Remove-Item -Force $TMPPKG
	}
	if($USE7Z) {
		echo "Using 7z for package creation"
		7z a -sdel $TMPPKG ./$TMPPKGFOLDER/jcr_root ./$TMPPKGFOLDER/META-INF -xr!$TMPPKGFOLDER | Out-Null
	}else {
		tar -C $TMPPKGFOLDER -acf $TMPPKG jcr_root META-INF
	}
}

function unzip_package() {
	# delete old package artifacts
	if(Test-Path $TMPPKGFOLDER) {
		Remove-Item -Force -Recurse $TMPPKGFOLDER
	}
	if($USE7Z) {
		echo "Using 7z for package extraction"
		7z x $TMPPKG -o"$TMPPKGFOLDER" | Out-Null
	}else {
		New-Item -F $TMPPKGFOLDER -ItemType "directory" | Out-Null
		tar -C $TMPPKGFOLDER -xf $TMPPKG
	}
	Remove-Item -Force $TMPPKG
}

# copy from package to your working folder
function copy_here() {
	$COPYITEM=($TMPPKGFOLDER,"/jcr_root",$AEMFILE -Join "")
	if($TYPE -eq "folder") {
		if(Test-Path $COPYITEM) {
			# remove local folder
			Remove-Item -Force -Recurse $INPUTFILE
			#$COPYITEM=($COPYITEM,"/*" -Join "")
			Copy-Item $COPYITEM -Destination $INPUTFILE -Force -Recurse
		}else {
			echo "Error: missing content from package. Skipping local file copy."
			echo "$COPYITEM contains no content"
			echo "Skipping content copy to $INPUTFILE"
		}
	}else {
		if(Test-Path $COPYITEM) {
			Copy-Item $COPYITEM -Destination $INPUTFILE -Force
		}else {
			Remove-Item -Force $INPUTFILE
		}
	}
	# cleanup
	Remove-Item -Force -Recurse $TMPPKGFOLDER
}

# copy from your working folder to temporary content package
function copy_local() {
	# split path folders
	$PATHARR=($AEMFILE -Split "/")
	# remove last element
	$PATHARR=$PATHARR[1..($PATHARR.length -2)]
	# BASEPATH = working directory
	$BASEPATH=($INPUTFILE -replace $AEMFILE, "")
	# COPYPATH = temporary package
	$COPYPATH=($TMPPKGFOLDER,"/jcr_root" -Join "")

	# construct parent folders of sync directory
	foreach($p in $PATHARR) {
		if($p) {
			# create new folder within package contents
			New-Item -Path "$COPYPATH/$p" -ItemType "directory" | Out-Null
			# check for folder metadata. if found, copy to package contents
			if(Test-Path -Path "$BASEPATH/.content.xml") {
				Copy-Item "$BASEPATH/.content.xml" -Destination "$COPYPATH/"
			}
			$COPYPATH="$COPYPATH/$p"
			$BASEPATH="$BASEPATH/$p"
		}
	}
	# copy last content.xml to folder
	if(Test-Path -Path "$BASEPATH/.content.xml") {
		Copy-Item "$BASEPATH/.content.xml" -Destination "$COPYPATH/"
	}

	# copy file/folder to package
	if($TYPE -eq "folder") {
		Copy-Item $INPUTFILE -Destination "$COPYPATH/" -Force -Recurse
	}else {
		Copy-Item $INPUTFILE -Destination "$COPYPATH/" -Force
	}
}

function cleanup_packages() {
	if(Test-Path -PathType "container" $TMPPKGFOLDER) {
		Remove-Item -Force -Recurse $TMPPKGFOLDER
	}
	if(Test-Path -PathType "any" $TMPPKG) {
		Remove-Item -Force $TMPPKG
	}
}

#####################################################################

function upload_pkg() {
	$AEMURL=$AEMSERVER,$AEMPACKMGRUPLOAD -Join ""
	$Fields = @{
		'name'='aempowersync'
		'force'='true'
		'file'= Get-Item -Path $TMPPKG
	}
	Invoke-RestMethod -Method post -Headers $AEMHeaders -Uri $AEMURL -Form $Fields | Out-Null
	# delete package
	if(Test-Path -PathType "any" $TMPPKG) {
		Remove-Item -Force $TMPPKG
	}
}

function install_pkg() {
	$AEMURL=$AEMSERVER,$AEMPACKMGR,$AEMPACKAGES,"aempowersync/aempowersync-1.0.0.zip?cmd=install" -Join ""
	$WEBREQ=(Invoke-RestMethod -Method post -Headers $AEMHeaders -Uri $AEMURL)
	$MSG=$WEBREQ.success," - ",$WEBREQ.msg -Join ""
	echo $MSG
}

function build_pkg() {
	$AEMURL=$AEMSERVER,$AEMPACKMGR,$AEMPACKAGES,"aempowersync/aempowersync-1.0.0.zip?cmd=build" -Join ""
	$WEBREQ=(Invoke-RestMethod -Method post -Headers $AEMHeaders -Uri $AEMURL)
	$MSG=$WEBREQ.success," - ",$WEBREQ.msg -Join ""
	echo $MSG
}

function delete_pkg() {
	$AEMURL=$AEMSERVER,$AEMPACKMGR,$AEMPACKAGES,"aempowersync/aempowersync-1.0.0.zip?cmd=delete" -Join ""
	$WEBREQ=(Invoke-RestMethod -Method post -Headers $AEMHeaders -Uri $AEMURL)
	$MSG=$WEBREQ.success," - ",$WEBREQ.msg -Join ""
	echo $MSG
}

function download_pkg() {
	$AEMURL=$AEMSERVER,$AEMPACKAGES,"aempowersync/aempowersync-1.0.0.zip" -Join ""
	Invoke-RestMethod -Headers $AEMHeaders -Uri $AEMURL -OutFile $TMPPKG
	# verify file was downloaded
	if(!(Test-Path -PathType "any" $TMPPKG)) {
		echo "Error: package not downloaded. Aborting."
		exit
	}
}

#####################################################################

cleanup_packages

switch($ACTION)
{
	"get" {
		echo ("GET ",$AEMFILE -Join "")
		if(create_base_package) {
			zip_package
			upload_pkg
			build_pkg
			download_pkg
			unzip_package
			copy_here
		}
	}
	"put" {
		echo ("PUT ",$AEMFILE -Join "")
		# copy fresh structure from AEM instance
		if(create_base_package) {
			copy_local
			zip_package
			upload_pkg
			install_pkg
		}
	}
	default {
		echo "invalid action"
	}
}