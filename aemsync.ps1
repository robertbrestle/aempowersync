### aemsyncps - VSCode extension for easily integrating with your local AEM instance

# Run with PS 6.1+
#   Required for Invoke-RestMethod "-Form" parameter
# Requires PATH variable for 7z

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
	[String] $AEMCREDS
)

# if script is run from the terminal, exit
if($INPUTFILE -eq "undefined") {
	echo "No path specified. Exiting."
	exit
}

# DO NOT RUN THIS AGAINST HIGHER ENVIRONMENTS !!
#$AEMSERVER="http://localhost:4502"
# DO NOT RUN THIS AGAINST HIGHER ENVIRONMENTS !!
#$AEMCREDS="admin:admin"
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

function create_base_package($filterpath) {
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
	
	$FILTER = "<?xml version=""1.0"" encoding=""UTF-8""?><workspaceFilter version=""1.0""><filter root=""", $filterpath, """/></workspaceFilter>" -Join ""
	
	$PROPERTIES = "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""no""?><!DOCTYPE properties SYSTEM ""http://java.sun.com/dtd/properties.dtd""><properties><entry key=""name"">aempowersync</entry><entry key=""version"">1.0.0</entry><entry key=""group"">aempowersync</entry></properties>"
	
	Add-Content -Path $TMPPKGFOLDER/META-INF/vault/filter.xml -Value $FILTER
	Add-Content -Path $TMPPKGFOLDER/META-INF/vault/properties.xml -Value $PROPERTIES
}

function zip_package() {
	# delete old package artifacts
	if(Test-Path $TMPPKG) {
		Remove-Item -Force $TMPPKG
	}
	7z a -sdel $TMPPKG ./$TMPPKGFOLDER/jcr_root ./$TMPPKGFOLDER/META-INF -xr!$TMPPKGFOLDER | Out-Null
}

function unzip_package() {
	# delete old package artifacts
	if(Test-Path $TMPPKGFOLDER) {
		Remove-Item -Force -Recurse $TMPPKGFOLDER
	}
	7z x $TMPPKG -o"$TMPPKGFOLDER" | Out-Null
	Remove-Item -Force $TMPPKG
}

function copy_here() {
	$COPYITEM=($TMPPKGFOLDER,"/jcr_root",$AEMFILE -Join "")
	if($TYPE -eq "folder") {
		Remove-Item -Force -Recurse $INPUTFILE
		if(Test-Path $COPYITEM) {
			#$COPYITEM=($COPYITEM,"/*" -Join "")
			Copy-Item $COPYITEM -Destination $INPUTFILE -Force -Recurse
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

function copy_local() {
	$COPYITEM=($TMPPKGFOLDER,"/jcr_root",$AEMFILE -Join "")
	echo $COPYITEM
	if($TYPE -eq "folder") {
		#$INPUTFILE=($INPUTFILE,"/*" -Join "")
		Remove-Item -Force -Recurse $COPYITEM
		Copy-Item $INPUTFILE -Destination $COPYITEM -Force -Recurse
	}else {
		Copy-Item $INPUTFILE -Destination $COPYITEM -Force
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
	
	#Start-Job -Name WebReq -ScriptBlock { 
	#	Invoke-RestMethod -Method post -Headers $AEMHeaders -Uri $AEMURL -Form $Fields
	#} | Out-Null
	#Wait-Job -Name WebReq | Out-Null
	#Remove-Job WebReq
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
	# TODO: verify file was downloaded
}

#####################################################################

switch($ACTION)
{
	"get" {
		echo ("GET ",$AEMFILE -Join "")
		create_base_package $AEMFILE
		zip_package
		upload_pkg
		build_pkg
		download_pkg
		unzip_package
		copy_here
	}
	"put" {
		echo ("PUT ",$AEMFILE -Join "")
		# copy fresh structure from AEM instance
		create_base_package $AEMFILE
		zip_package
		upload_pkg
		build_pkg
		download_pkg
		unzip_package
		# copy working directory into existing server structure
		copy_local
		zip_package
		upload_pkg
		install_pkg
	}
	default {
		echo "invalid action"
	}
}