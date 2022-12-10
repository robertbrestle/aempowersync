# Change Log
All notable changes to the "aempowersync" extension will be documented in this file.

---

## [Unreleased]

## [0.2.5] - 2022-12-10
### Changed
- updated npm packages to patch vulnerabilities  

## [0.2.4] - 2022-06-22
### Added
- `Enable AEM PowerSync extension` explorer context menu option  
    - shows on vscode startup  
    - required to enable AEM PowerSync  
- configuration to toggle explorer context menu options  
    - `Enable the "Sync from AEM" explorer menu option`  
    - `Enable the "Sync to AEM" explorer menu option`  
    - if an option is disabled, it will not be present in the context menu  

### Changed
- updated npm packages to patch vulnerabilities  
- default to PowerShell 7  
- moved enable OSGi to run on activate instead of the get/put commands  
    - the AEM healthcheck is still called before executing any command  

### Fixed
- callback race condition in `enableOSGIConfig()` in extension.js  
- added try-catch to `create_base_package()` in aemsync.ps1  
    - returns success boolean used to determine if all additional functions should be called  
    - prevents stack trace spam in output  

## [0.2.3] - 2022-02-21
### Added  
- README instructions for compiling

### Changed  
- updated npm packages to patch vulnerabilities

## [0.2.2] - 2021-05-12
### Added  
- project license (MIT)  
- project icon  

### Changed  
- updated npm packages to patch vulnerabilities

## [0.2.1] - 2021-04-05
### Added  
- extension configuration for automatically modifying OSGi components to allow the script to access AEM APIs  
    - property enabled by default  
    - modify the following OSGi components  
        - org.apache.sling.security.impl.ReferrerFilter  
        - com.adobe.granite.csrf.impl.CSRFFilter  

## [0.2.0] - 2021-03-08
### Added  
- support for `tar.exe`  
    - requires Windows 10 (1903) build 17063 or later  
- extension configuration for toggling the archive manager  

### Changed  
- allow extension configuration variables to take effect immediately without restart  
    - excludes PowerShell executable  
- prioritized sync check over healthcheck  

## [0.1.9] - 2020-12-03
### Added
- support for syncing `/content/*` and `/conf/*`
- output window spooling of severe PowerShell script errors  

### Changed
- default healthcheck path to `/libs/granite/core/content/login.html`
- spool full healthcheck result to output window
- return more errors from the PowerShell script to the output window

## [0.1.8] - 2020-10-22
### Added
- extension configuration for PowerShell executable: `aempowersync.powershell`  

### Changed
- removed PATH dependency for PowerShell in README

## [0.1.7] - 2020-08-18
### Fixed
- updated downloaded package file test syntax

## [0.1.6] - 2020-08-12
### Added
- verify GET package was downloaded
- bubble up error messages as popup notifications  

### Changed
- updated `cleanup_packages` to test before deleting old packages from the filesystem

## [0.1.5] - 2020-08-04
### Added
- check + error messages for trying to sync metadata/dialog files and folders  

### Changed
- refactored `Sync to AEM` local package construction
- README

## [0.1.4] - 2020-08-02
### Changed
- README with more explicit setup instructions
- changelog formatting  

### Fixed
- removed leftover comments that disabled script execution
- updated healthcheck to be more consistent

## [0.1.3] - 2020-07-29
### Added
- configuration parameters for the AEM server
- pass of AEM credentials to powershell
- catch for null healthcheck  

### Changed
- README

## [0.1.2]
### Added
- extension configuration support for AEM hostname/port
- custom output window for detailed logging
    - open **OUTPUT** window > select **AEM PowerSync** from dropdown

## [0.1.1]
### Added
- protection against syncing `/jcr_root` and `/apps`
- protection against multiple sync operations
- check if local AEM server is running before issuing commands  

### Changed
- project name

## [0.1.0]
### Added
- core sync to/from AEM functionality
- explorer view context options
- informational messages
- limited sync functionality to AEM folder hierarchy