*** Settings ***
Library          PolarisLibrary
Library          WebServiceLibrary
Library          BuiltIn
Library          OperatingSystem
Suite Setup      Setup Polaris
Suite Teardown   Run keyword and ignore error   Cleanup Polaris

Force Tags      polaris   regression

*** Variables ***
${pass}   newpassword

*** Keywords ***
Setup Polaris
    Remove File   .//results//artifacts//*.*
    Remove Isolated Storage

    # The above line is for regression testing use, the line below is for Jia to use on her pc.
    Connect to polaris  url=http://localhost:9999
    # Need to maximize Polaris screen
    Maximize application

Cleanup Polaris
    Stop monitor performance
    Plot performance
    Disconnect from polaris
    Remove File   .//artifacts//*.*

*** Test Cases ***
Create Offline Site A
    # Create new site from Home - Working Offline - [Create New Site]
    PolarisLibrary.Create New Site   sitename=OfflineSiteA   password=${pass}   customer=hospital   project=hospital_project   author=jia
    Synchronize
    PolarisLibrary.Logout

Create Offline Site B
    # Create new site from Home - Working Offline - create or load a offline site - site management - [Create New]
    PolarisLibrary.Create New Site   sitename=OfflineSiteB   password=${pass}   customer=school   project=school_project   author=jia
    Synchronize

Config Export Delete Offline Site
    Export offline site   site=OfflineSiteA   path=.//artifacts//OfflineSiteAExport
    Delete offline site   site=OfflineSiteA
    Config offline site   site=OfflineSiteB

Import Offline Site
    # Import site from site management window
    Import offline site   path=.//artifacts//OfflineSiteAExport.zip
    Delete offline site   site=OfflineSiteA
    PolarisLibrary.Logout

    # Import site from home page
    Import offline site   path=.//artifacts//OfflineSiteAExport.zip

Load Offline Site
    Load offline site   site=OfflineSiteA