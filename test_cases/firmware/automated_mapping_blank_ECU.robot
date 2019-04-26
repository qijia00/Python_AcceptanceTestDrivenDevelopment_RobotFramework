*** Settings ***
Library             ECULibrary
Library             WebServiceLibrary
Library             OperatingSystem
Library             BuiltIn
Library             String
Library             Collections
Library             HWSupportLibrary

Force Tags       firmware   automated-mapping

# MsgT_ManualOn & MsgT_ManualOff won't work if the ECU has been brought into site
# by returning error: ushort format requires 0 <= number <= USHRT_MAX
# this is why I created another sample script for automated_mapping_master_ECU.robot
# which uses ballast endpoint/ref-address to turn on/off lights

*** Test Cases ***
Map Fixture
    # powered device can join ECU via white list, but battery device can only join via mapping tool.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    # write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_fixture_input}  access==   data_type=Dynarray
    sleep   30s
    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}>0   No fixture is mapped to the ECU

    # create fixture1 object so we can turn ON/OFF the fixture
    ${fixture1_address_int}   ${fixture1_address_hex}=   Get Object Address   0xF001
    # create fixture object (value means {'address':${fixture_address_int}, 'object-type':4}, value format in shark '61441, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture1_address_int}, 4   access=+    data_type=ObjectProperty
    # map fixture ioURI (the fixture should already manually mapped to the ECU)
    Write Property Access   target=${fixture1_address_hex}   index=2   value=${fixture1_URI}   access==   data_type=URI
    # Msg_ManualOn and Msg_ManualOff doesn't work on Master ECU but work on blank ECU
    Send Message   command=MsgT_ManualOn   target=${fixture1_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOff   target=${fixture1_address_hex}
    Sleep   2s

    # to kick out nodes from your ECU, you need to clear out the white list, then kick them out one by one from Shark.
    # clear white list by write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray
    # kick out nodes one by one by write to Shark Target: ZigBee_NetworkManager, Index: prop_URIToDeleteNode
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_fixture1_input}  access==   data_type=URI
    sleep   30s   # if unmap 2 fixtures, you will need to disconnect and reconnect to ECU to remove the 2nd fixture, see example in script for LUM-1526, breakdown system section.
    # read from Shark Target: Zigbee_NetworkManager, Index: prop_nodetree for a list of devices that are mapped to the ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}==0   Fixture is NOT unmapped from the ECU

    # remove fixture1 object
    ${fixture1_address_int}   ${fixture1_address_hex}=   Get Object Address   0xF001
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture1_address_int}, 4   access=-    data_type=ObjectProperty

    #disconnect from ECU
    Disconnect

Map Sensor
    # powered device can join ECU via white list, but battery device can only join via mapping tool after wake up.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    # write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_sensor_input}  access==   data_type=Dynarray
    sleep   30s
    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture} > 0   No fixture is mapped to the ECU

    # wake sensor up by turn the fixture above sensor on and off in step 3 below (create fixture object here so you can turn it on and off)
    # create fixture2 object
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   0xF002
    # create fixture object (value means {'address':${fixture2_address_int}, 'object-type':4}, value format in shark '61442, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=+    data_type=ObjectProperty
    # map fixture ioURI (the fixture should already manually mapped to the ECU)
    Write Property Access   target=${fixture2_address_hex}   index=2   value=${fixture2_URI}   access==   data_type=URI

    # battery device has to join by Mapping Tool via 3 steps
    # step 1, change ECU channel away from channel 26:
    Change Channel   extendedPanId=${extendedPanId}
    # the above line write to ECU Shark Target: 0032 -- ZigBee_NetworkManager, Index: 103 -- prop_zigbeeNetworkParams
    # after the write, you suppose to see Rodio Channel is 11, channel mask is 00000800, and Link Key Index is 0
    sleep   5s

#    # DKo suggested me to change operationMode instead of SecurityMode for step 2, but Shark doesn't take the input.
#    # step 2, write 2 to Shark Target: ZigBee_NetworkManager, Index: prop_operationMode
#    Write Property Access   target=${NetworkManager_address_hex}   index=106   value=2  access==   data_type=unit8
    # step 2, write 3 (OpenTemporarily) to Shark Target: ZigBee_NetworkManager, Index: prop_zigbeeNetworkSecurityMode
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s

    # step 3, join via mapping tool.
    # use the fixture as a flashlight to wake the sensor up (pysically place the fixture above the sensor)
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Disconnect
    # battery device has to join via mapping tool, white list won't work
    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${sensor}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    # the above line write to Mapping Tool Shark Target: 0033 -- ZigBee_DeviceScanner, Index: 102 -- prop_joinNetwork
    # but we do not know the input format, so we can not do in shark, we have to use join_via_mapping_tool funtion which based on ecu_test_tools.py
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   30s
    Disconnect

    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture_sensor} > ${device_list_length_fixture}   No sensor is mapped to the ECU

    # to kick out nodes from your ECU, you need to clear out the white list, then kick them out one by one.
    # clear white list by write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray
    ${prop_whiteListFromPolaris}=   Read Property Access   target=${NetworkManager_address_hex}   index=10
    log   ${prop_whiteListFromPolaris}
    # use the fixture as a flashlight to wake the sensor up
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    # kick out nodes one by one by write to Shark Target: ZigBee_NetworkManager, Index: prop_URIToDeleteNode
    # unmap sensor first
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_sensor_input}  access==   data_type=URI
    sleep   30s
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_no_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture_no_sensor} < ${device_list_length_fixture_sensor}   Sensor is NOT unmapped from the ECU
    # unmap fixture next
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_fixture2_input}  access==   data_type=URI
    sleep   30s
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_no_fixture_no_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_no_fixture_no_sensor} == 0   Fixture is NOT unmapped from the ECU

    # remove fixture2 object
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=-    data_type=ObjectProperty

    #disconnect from ECU
    Disconnect

Map Keypad
    # powered device can join ECU via white list, but battery device has to join by Mapping Tool via 3 steps after wake up.
    # step 1, change ECU channel away from channel 26:
    connect to ECU   ${IP}
    Change Channel   extendedPanId=${extendedPanId}
    # the above line write to ECU Shark Target: 0032 -- ZigBee_NetworkManager, Index: 103 -- prop_zigbeeNetworkParams
    # after the write, you suppose to see Rodio Channel is 11, channel mask is 00000800, and Link Key Index is 0
    sleep   5s

#    # DKo suggested my to change operationMode instead of SecurityMode, but Shark doesn't take the input.
#    # step 2, write 2 to Shark Target: ZigBee_NetworkManager, Index: prop_operationMode
#    Write Property Access   target=${NetworkManager_address_hex}   index=106   value=2  access==   data_type=unit8
    # step 2, write 3 (OpenTemporarily) to Shark Target: ZigBee_NetworkManager, Index: prop_zigbeeNetworkSecurityMode
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s
    Disconnect

    # step 3, wake the keypad up and join via mapping tool.
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays

    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${keypad}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    # the above line write to Mapping Tool Shark Target: 0033 -- ZigBee_DeviceScanner, Index: 102 -- prop_joinNetwork
    # but we do not know the input format, so we can not do in shark, we have to use join_via_mapping_tool funtion which based on ecu_test_tools.py
    ${DeviceScanner_address_int}   ${DeviceScanner_address_hex}=   Get Object Address   0x0033
    ${prop_joinNetwork}=   Read Property Access   target=${DeviceScanner_address_hex}   index=102
    log   ${prop_joinNetwork}   # you suppose to see the eui64 id in the returns.
    sleep   30s
    Disconnect

    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length} > 0   No keypad is mapped to the ECU

    # wake keypad up by relay controller
    Connect to Relays   ${relay_port}
    activate momentary relay   ${relay_number}   delay=0.5
    disconnect from relays
    # kick out nodes one by one by write to Shark Target: ZigBee_NetworkManager, Index: prop_URIToDeleteNode
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_keypad_input}  access==   data_type=URI
    sleep   30s
    # read from Shark Target: Zigbee_NetworkManager, Index: prop_nodetree for a list of devices that are mapped to the ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length} == 0   Sensor is NOT unmapped from the ECU

    #disconnect from ECU
    Disconnect

*** Variables ***
${IP}   172.24.172.101
# you can verbalize ECU Shark 0032 to get the following input
${extendedPanId}   0x000D6F0002F3ADE6
${linkKeyIndex}   255

${mapping_tool_IP}   127.0.0.1

${fixture1}   000D6F00031105FC
#use the Ballast object type URI
${fixture1_URI}   ZigBee://${fixture1}.02

${fixture2}   000D6F0002F3B443   # WALC tethered with Lamp, which is used to wake up sensor by winking
#use the Ballast object type URI for winking
${fixture2_URI}   ZigBee://${fixture2}.02
#if test lamp failure, then use the fixture's DaliOnZB_CG_Fluor. object type URI, don't use the Ballast object type URI
${fixture2_URI}   DALI://2C36E5?V0=0000-FF

${sensor}   000D6F000310E74D
${keypad}   000D6F0010061F00

# How to install driver for relay controller: go to https://www.arduino.cc/en/Guide/ArduinoLeonardoMicro
# from SOFTWARE - DOWNLOADS - Windows ZIP file for non admin install, which contains the "drivers" folder
# follow the instruction to install drivers: https://www.arduino.cc/en/Guide/DriverInstallation
# find port number from Control Panel - Device Manager - Ports - Arduino Leonardo
${relay_port}   COM9
# RELAY number can be from 1 to 4, labels could be wrong, try different number in the script, extend the delay to 5 seconds,
# if your script has the correct RELAY number, you should see the keypad is waking up, i.e., the red LED below all the keypad buttons will light up
${relay_number}   RELAY4

${prop_whiteListFromPolaris_fixture_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture1}"
...             }
...         ]
...     }

${prop_whiteListFromPolaris_sensor_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture2}"
...             },
...             {
...                 "Eui64": "${sensor}"
...             }
...         ]
...     }

${prop_whiteListFromPolaris_empty_input}   SEPARATOR=\n
...     {
...         "Devices": []
...     }

${prop_URIToDeleteNode_fixture1_input}   ZigBee://${fixture1}.00
${prop_URIToDeleteNode_fixture2_input}   ZigBee://${fixture2}.00
${prop_URIToDeleteNode_sensor_input}   ZigBee://${sensor}.00
${prop_URIToDeleteNode_keypad_input}   ZigBee://${keypad}.00