# Change Log
All notable changes to the "aempowersync" extension will be documented in this file.

---

## [Unreleased]

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