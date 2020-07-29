# AEM PowerSync README
AEM PowerSync is an extension for VSCode that allows you to sync files and folders between your local AEM instance and file system.

## Features
This extension was designed for AEM 6.5 local development on Windows 10.

Sync options at the bottom of the Explorer window context menu:
![context menu options](images/menu.png)

**Please, only use this extension for local AEM development.**

## Requirements

### Software
- [7z](https://www.7-zip.org/a/7z1900-x64.msi)
- [PowerShell 6+](https://github.com/PowerShell/PowerShell/releases)

### Set PATH variable for 7z
Get `7z` to work from your command line
- Install 7z from the link above
- Edit environment variables:
    - press the **Windows Key**
    - search **Edit the system environment variables**
    - click **Environment Variables..**
    - under **System variables** select **Path** and click **Edit..**
    - click **New** and enter the path to your 7z binaries
        - `c:\Program Files\7-Zip\`
- Click **OK** for all the open dialogues
- Open a new **cmd terminal** and enter `7z`
    - if the command is recognized, you should see a list of commands
    - you're **done!**
 
### Set PowerShell 6/7 as default shell in VSCode
- File > Preferences > Settings
- Search for **terminal.integrated.shell.windows**
- Click **Edit in settings.json**
- Set **terminal.integrated.shell.windows** to `C:\\Program Files\\PowerShell\\6\\pwsh.exe`
- Save file
- Reload VSCode ( CTRL + SHIFT + P > **Developer: Reload Window**)
- Upon reload, open terminal and verify the PS version: `$PSVersionTable`
```
Name                           Value
----                           -----
PSVersion                      6.2.7
PSEdition                      Core
GitCommitId                    6.2.7
OS                             Microsoft Windows 10.0.XXXXX
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

### AEM localhost configuration
localhost:4502/system/console/configMgr
- **Apache Sling Referrer Filter** => Enable allow empty, Remove POST
- **Adobe Granite CSRF Filter** => remove POST

## Extension Settings
- aempowersync.uri
    - AEM server uri as `https?://HOSTNAME:PORT`
- aempowersync.credentials
    - AEM admin user credentials as `USERNAME:PASSWORD`
- aempowersync.healthcheck
    - AEM healthcheck endpoint as url path
    - by default, this points to CRXDE `/crx/de/index.jsp`

## Known Issues
- Syncing `.content.xml` files does not work; you must sync the parent folder
