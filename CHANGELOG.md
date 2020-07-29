# Change Log
All notable changes to the "aempowersync" extension will be documented in this file.

## [0.1.3]
- added configuration parameters for the AEM server
- pass AEM credentials to powershell
- added catch for null healthcheck
- updated documentation

## [0.1.2]
- added extension configuration support for AEM hostname/port
- added custom output window for detailed logging
    - open **OUTPUT** window > select **AEM PowerSync** from dropdown

## [0.1.1]
- added protection against syncing `/jcr_root` and `/apps`
- added protection against multiple sync operations
- added check if local AEM server is running before issuing commands
- changed name

## [0.1.0]
initial release