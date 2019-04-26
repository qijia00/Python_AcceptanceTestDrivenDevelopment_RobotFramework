*** Settings ***
Library         PolarisLibrary
Library         OperatingSystem

Suite Setup     Setup Polaris
Suite Teardown  Close Polaris

Force Tags      polaris

*** Variables ***
${pass}   12345678
${site_name}   RobotTestSite

*** Keywords ***
Setup Polaris
    Launch Polaris

Launch Polaris
    Remove isolated storage
    Connect to polaris   url=http://localhost:9999
    Maximize application

Close Polaris
    Disconnect from Polaris
    Stop monitor performance

*** Test Cases ***
Create a new site
    Create new site   ${site_name}   ${pass}

Configure first manager area
    Rename control area  C1

    Create profile   profile=Canteen   target=C1   name=autoCanteen 1
    Search profile   autoCanteen 1

    Create profile   profile=Class Room   target=C1   name=autoClassRoom 1
    Search profile   autoClassRoom 1

Create 3 blank manager areas
    Create control area   C2
    Create control area   C3
    Create control area   C4

Create profiles on C5
    Create control area   C5
    Create profile   profile=Lobby   target=C5   name=autoLobby 1
    Search profile   autoLobby 1

    Create profile   profile=Open Office   target=C5   name=autoOpenOffice 1
    Search profile   autoOpenOffice 1

Create additional profiles on C1
    Create profile   profile=Parking Garage   target=C1
    Search profile   Parking Garage 1

    Create profile   profile=Washroom   target=C1
    Search profile   Washroom 1