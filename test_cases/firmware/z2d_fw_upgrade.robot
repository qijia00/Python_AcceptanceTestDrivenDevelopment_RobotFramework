*** Settings ***
Library             ECULibrary
Library             BuiltIn
Suite Setup         Setup system
Suite Teardown      Run keyword and ignore error   Teardown system

*** Variables ***
${IP}               10.215.23.65
${OTA_LOC_PATH}     C:\\Users\\a.viaestrem\\Downloads\\
${OTA_FILE}         ZigbeePbc-00045A03.ota
${OTA_REV}          285187  # This translates to 0x00045A03
${NODES}            ZigBee://000B57FFFEF19361.00
# or empty or [000D6F000D84B2D6.00, 000D6F000D84B2D6.01]
# legacy is now needed when not using the new upgrade procedure
${Node_Nr}          0

*** Test Cases ***
Upgrade Z2D Converter
    Add node to polaris whitelist   000B57FFFEF19361
    Upload file   ${OTA_LOC_PATH}${OTA_FILE}   /firmware/upgrade/${OTA_FILE}
    OTA upgrade   ${NODES}
    Verify z2d fw version   ${OTA_REV}   ${Node_Nr}


*** Keywords ***
Setup system
    Connect to ECU   ${IP}
    Establish SSH connection   ${IP}

Teardown system
    Disconnect
