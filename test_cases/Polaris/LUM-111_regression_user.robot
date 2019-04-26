*** Settings ***
Library         PolarisLibrary
Library         WebServiceLibrary
Library         BuiltIn
Suite Setup     Setup Polaris
Suite Teardown  Run keyword and ignore error   Cleanup ECU for next test

*** Variables ***

${IP}   10.215.23.145
${user}   sysadmin
${pass}   12345

*** Keywords ***

Setup Polaris
#   This test-case runs on a Live site which has WM mapped already
    Connect to polaris  url=http://localhost:9999
    PolarisLibrary.login   ${user}   ${pass}   ${IP}

Cleanup ECU for next test
    Disconnect from polaris


*** Test Cases ***
#   These tests are deprecated as they are called here
Add Basic Users
    PolarisLibrary.add user   Basic One   basic1   111   Basic User   basic1@one.com
    PolarisLibrary.add user   Basic Two   basic2   222   Basic User   basic2@one.com
    PolarisLibrary.add user   Basic Three   basic3   333   Basic User   basic3@one.com

Add Advanced Users
    PolarisLibrary.add user   Advanced One   advanced1   111   Advanced User   advan1@one.com
    PolarisLibrary.add user   Advanced Two   advanced2   222   Advanced User   advan2@one.com
    PolarisLibrary.add user   Advanced Three   advanced3   333   Advanced User   advan3@one.com

Add Configurator Users
    PolarisLibrary.add user   Configurator One   config1   111   Configurator   config1@one.com
    PolarisLibrary.add user   Configurator One   config2   222   Configurator   config2@one.com
    PolarisLibrary.add user   Configurator One   config3   333   Configurator   config2@one.com
    PolarisLibrary.logout

Validate Basic User Access
    PolarisLibrary.login   basic1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic3   333   ${IP}
    PolarisLibrary.logout

Validate Advanced User Access
    PolarisLibrary.login   advanced1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   advanced2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   advanced3   333   ${IP}
    PolarisLibrary.logout

Validate Configurator User Access
    PolarisLibrary.login   config1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   config2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   config3   333   ${IP}
    PolarisLibrary.logout

Create system snapshot
    PolarisLibrary.login    ${user}   ${pass}   ${IP}
    Take system snapshot   ./artifacts/sanity_snapshot

Delete All Added Users

    PolarisLibrary.remove user   basic1
    PolarisLibrary.remove user   basic2
    PolarisLibrary.remove user   basic3
    PolarisLibrary.remove user   advanced1
    PolarisLibrary.remove user   advanced2
    PolarisLibrary.remove user   advanced3
    PolarisLibrary.remove user   config1
    PolarisLibrary.remove user   config2
    PolarisLibrary.remove user   config3

    PolarisLibrary.logout

Validate users are deleted
    Run keyword and expect error   *   PolarisLibrary.login  basic1   111   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  basic2   222   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  basic3   333   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  advanced1   111   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  advanced2   222   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  advanced3   333   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  config1   111   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  config2   222   ${IP}
    Run keyword and expect error   *   PolarisLibrary.login  config3   333   ${IP}

Restore system snapshot
    PolarisLibrary.login    ${user}   ${pass}   ${IP}
    Restore system snapshot   ./artifacts/sanity_snapshot.zip   ${IP}

Validate Basic User Access
    PolarisLibrary.login   basic1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   basic3   333   ${IP}
    PolarisLibrary.logout

Validate Advanced User Access
    PolarisLibrary.login   advanced1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   advanced2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   advanced3   333   ${IP}
    PolarisLibrary.logout

Validate Configurator User Access
    PolarisLibrary.login   config1   111   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   config2   222   ${IP}
    PolarisLibrary.logout

    PolarisLibrary.login   config3   333   ${IP}
    PolarisLibrary.logout

Delete All Added Users
    PolarisLibrary.login   ${user}   ${pass}   ${IP}
    PolarisLibrary.remove user   basic1
    PolarisLibrary.remove user   basic2
    PolarisLibrary.remove user   basic3
    PolarisLibrary.remove user   advanced1
    PolarisLibrary.remove user   advanced2
    PolarisLibrary.remove user   advanced3
    PolarisLibrary.remove user   config1
    PolarisLibrary.remove user   config2
    PolarisLibrary.remove user   config3

    PolarisLibrary.logout