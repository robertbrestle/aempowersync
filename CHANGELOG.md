# Change Log
All notable changes to the "aempowersync" extension will be documented in this file.

## [Unreleased]

## [0.1.4] - 2020-08-02
### Changed
- updated README with more explicit setup instructions
- changelog formatting

### Fixed
- removed leftover comments that disabled script execution
- updated healthcheck to be more consistent

## [0.1.3] - 2020-07-29
### Added
- added configuration parameters for the AEM server
- added pass of AEM credentials to powershell
- added catch for null healthcheck
### Changed
- updated README

## [0.1.2]
### Added
- added extension configuration support for AEM hostname/port
- added custom output window for detailed logging
    - open **OUTPUT** window > select **AEM PowerSync** from dropdown

## [0.1.1]
### Added
- added protection against syncing `/jcr_root` and `/apps`
- added protection against multiple sync operations
- added check if local AEM server is running before issuing commands
### Changed
- changed project name

## [0.1.0]
initial release