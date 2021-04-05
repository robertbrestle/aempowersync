# AEM PowerSync README
AEM PowerSync is an extension for VSCode that allows you to sync files and folders between your local AEM instance and file system.

This tool was only intended for local AEM development and should not be considered for use in production environments due to security vulnerabilities.

## Features
This extension was designed for AEM 6.5 local development on Windows 10.

Sync options at the bottom of the Explorer window context menu:
![context menu options](images/menu.png)

**Please, only use this extension for local AEM development.**

## Setup Configuration
Please follow all configuration steps before attempting to use this extension.  

### Software Dependencies
- [PowerShell 6+](https://github.com/PowerShell/PowerShell/releases)
- Windows 10 (1903) build 17063 or later
    - requirement for using `tar` for archive management
    - if not possible, install 7z
- [7z](https://www.7-zip.org/a/7z1900-x64.msi) accessible via PATH environment variable \[OPTIONAL\]
    - [More information on environment variables here.](https://support.microsoft.com/en-us/help/310519/how-to-manage-environment-variables-in-windows-xp)

### AEM OSGi Component Configuration
For the script to manage packages, CSRF and referrer filter OSGi configurations will need relaxed permissions. For increased security, ensure your local AEM instance isn't exposed to the public internet.  

By default, this extension will update the below component properties on initial sync.  
In [configMgr](http://localhost:4502/system/console/configMgr)  
- [Apache Sling Referrer Filter](http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter) => Enable allow empty, Remove POST  
- [Adobe Granite CSRF Filter](http://localhost:4502/system/console/configMgr/com.adobe.granite.csrf.impl.CSRFFilter) => remove POST  


These properties can also be set programmatically with curl:  
```
curl -u admin:admin -X POST "http://localhost:4502/system/console/configMgr/org.apache.sling.security.impl.ReferrerFilter" --data "apply=true&allow.empty=true&filter.methods=DELETE&propertylist=allow.empty,filter.methods"
curl -u admin:admin -X POST "http://localhost:4502/system/console/configMgr/com.adobe.granite.csrf.impl.CSRFFilter" --data "apply=true&filter.methods=DELETE&propertylist=filter.methods"
```

**If you do not update these configurations, the script may delete folders/files from your filesystem.**

### Unblock PowerShell Script [Conditional]
This extension uses a PowerShell script to manage AEM packages and code on your filesystem.  
The script is located at:  
`%USERPROFILE%\.vscode\extensions\aempowersync-X.X.X\aemsync.ps1`

Per Microsoft, I encourage you to read the contents of the script before unblocking the file or changing your execution policy.  
[You can read more here](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7#example-7--unblock-a-script-to-run-it-without-changing-the-execution-policy)  


## Extension Settings
- aempowersync.powershell
    - Location of the PowerShell executable
    - default = `C:\\Program Files\\PowerShell\\6\\pwsh.exe`
- aempowersync.uri
    - AEM server uri as `https?://HOSTNAME:PORT`
    - default = `http://127.0.0.1:4502`
- aempowersync.credentials
    - AEM admin user credentials as `USERNAME:PASSWORD`
    - default = `admin:admin`
- aempowersync.healthcheck
    - AEM healthcheck endpoint as url path
    - default = `/libs/granite/core/content/login.html`
- aempowersync.use7z
    - use 7z to manage local archives
    - if disabled, the script will attempt to use `tar`
    - default = `false`
- aempowersync.enableOsgiConfig
    - automatically enable OSGi components for access to the AEM API
    - if enabled, the extension will attempt to update the OSGi components found in aempowersync.json
    - default = `true`

## Known Issues
- Syncing `.content.xml` files **to AEM** does not work; you must sync the parent folder
    - `.content.xml` from AEM = **enabled**
    - `.content.xml` to AEM = **disabled**
    - `_cq_editConfig.xml` from/to AEM = **disabled**
    - `_cq_template/` from/to AEM = **disabled**
