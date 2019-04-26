*** Settings ***
Library             ECULibrary
Library             BuiltIn
Library             String
Library             Collections
Library             HWSupportLibrary

Suite Setup         Setup system
Suite Teardown      Breakdown System

Force Tags       firmware   LUM-1526   ecu_profile_objects   regression

*** Test Cases ***
Test prop_profileId
    connect to ECU   ${IP}
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    Write Property Access   target=${profile_address_hex}   index=0   value=${prop_profileId_input}  access==   data_type=EString
    ${prop_profileId}=   Read Property Access   target=${profile_address_hex}   index=0
    log   ${prop_profileId}

    #Verify value read from Shark
#    #${prop_profileId_input} and ${prop_profileId} looks the same but they are different types and different length
#    ${a}=   Evaluate   type($prop_profileId_input)   #<type 'unicode'>
#    ${b}=   Evaluate   len($prop_profileId_input)   #77
#    ${c}=   Evaluate   type($prop_profileId)   #<type 'str'>
#    ${d}=   Evaluate   len($prop_profileId)   #78
    #convert input to <type 'str'>   (use "convert to bytes" to convert to <type 'str'> byte string, use "convert to string" to convert to <type 'unicode'> unicode string)
    ${prop_profileId_input_string}=   Convert To Bytes	${prop_profileId_input}
    #remove the null byte at the end of the output string
    ${prop_profileId_string}=   Get Substring    ${prop_profileId}   start=0   end=-1
    #compare input and output
    should be equal   ${prop_profileId_input_string}   ${prop_profileId_string}

Test prop_config
    connect to ECU   ${IP}
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    ${zone_address_int}   ${zone_address_hex}=   Get Object Address   0xF000
    ${zone_address_str}=   Build Address    0xF000
    ${fixture_address_int}   ${fixture_address_hex}=   Get Object Address   0xF001
    ${fixture_address_str}=   Build Address    0xF001
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   0xF002
    ${fixture2_address_str}=   Build Address    0xF002
    ${dam_address_int}   ${dam_address_hex}=   Get Object Address   0xF003
    ${dam_address_str}=   Build Address    0xF003
    set global variable   ${zone_address}   ${zone_address_str}
    set global variable   ${fixture_address}   ${fixture_address_str}
    set global variable   ${fixture2_address}   ${fixture2_address_str}
    set global variable   ${dam_address}   ${dam_address_str}
    ${prop_config_input_temp}=   replace variables   ${prop_config_input}
    set global variable   ${prop_config_input}   ${prop_config_input_temp}
    #Value in Shark: "{\"zones\":[{\"high-dlhv-fixtures\":[\"0000F001\"],\"medium-dlhv-fixtures\":[],\"low-dlhv-fixtures\":[],\"photo-sensor\":\"00000000\",\"wall-stations\":[],\"occupancy-sensors\":[],\"address\":\"0000F000\"}],\"elements\": [{\"high-level-object-type\": 4,\"naed\": 45583,\"uri\": \"ZigBee://000D6F00031105FC.02\",\"address\": \"0000F001\"}]}"
    Write Property Access   target=${profile_address_hex}   index=1   value=${prop_config_input}   access==   data_type=EString
    ${prop_config}=   Read Property Access   target=${profile_address_hex}   index=1
    log   ${prop_config}

    #Verify value read from Shark
    #change input type to be the same as output type
    ${prop_config_input_string}=   Convert To Bytes	${prop_config_input}
    #change output length to be the same as input length
    ${prop_config_string}=   Get Substring    ${prop_config}   start=0   end=-1
    #compare input and output
    should be equal   ${prop_config_input_string}   ${prop_config_string}

Test prop_status and prop_deviceStatusList
    connect to ECU   ${IP}
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    ${prop_deviceStatusList}=   Read Property Access   target=${profile_address_hex}   index=5
    log   ${prop_deviceStatusList}

    #Verify value read from Shark
    Check Shark output key dictionary of dictionary  ${expected_prop_status_format}   ${prop_status}
    Check Shark output key dictionary of list   ${expected_prop_deviceStatusList}   ${prop_deviceStatusList}

Test prop_test dlhv with prop_status
    connect to ECU   ${IP}
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    Write Property Access   target=${profile_address_hex}   index=3   value=${start_dlhv_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=running
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    sleep   6s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=running
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    Write Property Access   target=${profile_address_hex}   index=3   value=${stop_dlhv_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

Test prop_test functional with prop_status
    connect to ECU   ${IP}
    #start functional test on profile
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    Write Property Access   target=${profile_address_hex}   index=3   value=${start_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=running

    #start DLHV test on profile2, profile 2 contains no devices, so dlhv and functional tests status are always never-run.
    ${profile2_address_int}   ${profile2_address_hex}=   Get Object Address   0x9000
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    Write Property Access   target=${profile2_address_hex}   index=3   value=${start_dlhv_test}   access==   data_type=EString
    sleep   1s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    sleep   6s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    #stop DLHV test on profile2
    Write Property Access   target=${profile2_address_hex}   index=3   value=${stop_dlhv_test}   access==   data_type=EString
    sleep   1s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    #start functional test on profile2
    Write Property Access   target=${profile2_address_hex}   index=3   value=${start_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    sleep   6s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    #stop functional test on profile2
    Write Property Access   target=${profile2_address_hex}   index=3   value=${stop_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop2_status}=   Read Property Access   target=${profile2_address_hex}   index=2
    log   ${prop2_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=never-run
    Check Shark output value dictionary of dictionary   json_payload=${prop2_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=never-run

    #stop functional test on profile
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=success

    Write Property Access   target=${profile_address_hex}   index=3   value=${stop_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=success

Test prop_test bad with prop_status
    connect to ECU   ${IP}
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    #test should not start
    Write Property Access   target=${profile_address_hex}   index=3   value=${start_test_bad_action}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=success

    #test should not start
    Write Property Access   target=${profile_address_hex}   index=3   value=${start_test_bad_type}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=success

    #start functional test
    Write Property Access   target=${profile_address_hex}   index=3   value=${start_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=running

    #test should not stop
    Write Property Access   target=${profile_address_hex}   index=3   value=${stop_test_bad_action}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=running

    #test should not stop
    Write Property Access   target=${profile_address_hex}   index=3   value=${stop_test_bad_type}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=running

    #stop funtional test
    sleep   45s
    Write Property Access   target=${profile_address_hex}   index=3   value=${stop_functional_test}   access==   data_type=EString
    sleep   1s
    ${prop_status}=   Read Property Access   target=${profile_address_hex}   index=2
    log   ${prop_status}
    #Verify value read from Shark
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=dlhv-setup   second_level_key=status   second_level_expected_value=canceled
    Check Shark output value dictionary of dictionary   json_payload=${prop_status}   first_level_key=functional-test   second_level_key=status   second_level_expected_value=success

Test prop_testStatus
    Log   Don't touch this property, it is used internally to store status, use prop_status instead.

*** Variables ***
${IP}   172.24.172.101
${extendedPanId}   0x000D6F0002F3ADE6
${linkKeyIndex}   255
${mapping_tool_IP}   127.0.0.1

${fixture}   000D6F00031105FC
${fixture2}   000D6F000EBEE871
${prop_whiteListFromPolaris_input}   SEPARATOR=\n
...     {
...         "Devices": [
...             {
...                 "Eui64": "${fixture}"
...             },
...             {
...                 "Eui64": "${fixture2}"
...             }
...         ]
...     }
${prop_whiteListFromPolaris_empty_input}   SEPARATOR=\n
...     {
...         "Devices": []
...     }
#use the Ballast object type URI
${fixture_URI}   ZigBee://${fixture}.02
##if test lamp failure, then use the fixture's DaliOnZB_CG_Fluor. object type URI, don't use the Ballast object type URI
#${fixture2_URI}   DALI://2C36E5?V0=0000-FF
${fixture2_URI}   ZigBee://${fixture2}.0A
${prop_URIToDeleteNode_fixture_input}   ZigBee://${fixture}.00
${prop_URIToDeleteNode_fixture2_input}   ZigBee://${fixture2}.00

${sensor}   000D6F000D6B2FBC
#use the photo sensor endpoint
${sensor_URI}   ZigBee://${sensor}.02
${prop_URIToDeleteNode_sensor_input}   ZigBee://${sensor}.00

${prop_profileId_input}   Profile Name Long and with Special Charactors !@#$%^&*()_+~`-={}:"<>?|[]\;',./
${zone_address}
${fixture_address}
${fixture2_address}
${dam_address}   # for photo sensor
# NAED number can be found at http://wiki:8090/display/ERD/Device+Compendium
${prop_config_input}   SEPARATOR=\n
...     {
...         "zones": [
...     		{
...     			"high-dlhv-fixtures":		["\${fixture_address}"],
...     			"medium-dlhv-fixtures":		["\${fixture2_address}"],
...     			"low-dlhv-fixtures":		[],
...     			"photo-sensor":				"\${dam_address}",
...     			"wall-stations":			[],
...     			"occupancy-sensors":		[],
...     			"address":					"\${zone_address}"
...     		}
...         ],
...         "elements": [
...             {
...                 "high-level-object-type": 4,
...                 "naed": 57450,
...                 "uri": "${fixture_URI}",
...                 "address": "\${fixture_address}"
...             },
...             {
...                 "high-level-object-type": 4,
...                 "naed": 45586,
...                 "uri": "${fixture2_URI}",
...                 "address": "\${fixture2_address}"
...             },
...             {
...                 "high-level-object-type": 14,
...                 "naed": 45571,
...                 "uri": "${sensor_URI}",
...                 "address": "\${dam_address}"
...             }
...         ],
...         "dlhv" : { "primary-dependency" : 0.36, "secondary-dependency" : 0.20 }
...     }

${expected_prop_status_format}   SEPARATOR=\n
...     {
...         "device": [],
...         "functional-test": {
...             "status": [],
...             "last-run-timestamp-int": [],
...             "last-run-timestamp": [],
...             "address": []
...         },
...         "dlhv-setup": {
...             "status": [],
...             "last-run-timestamp-int": [],
...             "last-run-timestamp": [],
...             "address": []
...         }
...     }

${expected_prop_deviceStatusList}   SEPARATOR=\n
...     {
...         "device-list": [
...             {
...                 "debug": [],
...                 "status": [],
...                 "high-level-object-type": [],
...                 "address": []
...             },
...             {
...                 "debug": [],
...                 "status": [],
...                 "high-level-object-type": [],
...                 "address": []
...             },
...             {
...                 "debug": [],
...                 "status": [],
...                 "high-level-object-type": [],
...                 "address": []
...             }
...         ]
...     }

${start_test_bad_action}   SEPARATOR=\n
...     {
...         "action": "bad",
...         "test-task-type": "lumenade-dlhv-test"
...     }

${start_test_bad_type}   SEPARATOR=\n
...     {
...         "action": "start-test",
...         "test-task-type": "bad-test"
...     }

${stop_test_bad_action}   SEPARATOR=\n
...     {
...         "action": "bad",
...         "test-task-type": "lumenade-functional-test"
...     }

${stop_test_bad_type}   SEPARATOR=\n
...     {
...         "action": "stop-test",
...         "test-task-type": "bad-test"
...     }

${start_dlhv_test}   SEPARATOR=\n
...     {
...         "action": "start-test",
...         "test-task-type": "lumenade-dlhv-test"
...     }

${stop_dlhv_test}   SEPARATOR=\n
...     {
...         "action": "stop-test",
...         "test-task-type": "lumenade-dlhv-test"
...     }

${start_functional_test}   SEPARATOR=\n
...     {
...         "action": "start-test",
...         "test-task-type": "lumenade-functional-test"
...     }

${stop_functional_test}   SEPARATOR=\n
...     {
...         "action": "stop-test",
...         "test-task-type": "lumenade-functional-test"
...     }

*** Keywords ***
Setup system
    # map 2 fixtures
    Connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    # write to Shark Target: ZigBee_NetworkManager, Index: prop_whiteListFromPolaris
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_input}  access==   data_type=Dynarray
    sleep   60s
    # read from Shark Target 0032 Zigbee_NetworkManager, Index 105 prop_nodetree for a list of devices that mapped to this ECU.
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture}>5   No 2 fixtures are mapped to the ECU

    #add fixture template
    Write Property Access   target=BallastTemplateManager   index=Templates   value=1C001C000000C84300000000000070420000404131204443001C39558EAAC6E3FF00000000   access==   data_type=Dynarray

    #create profile object
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    #create profile object (value={'address':${profile_address_int}, 'object-type':32833})
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile_address_int}, 32833   access=+   data_type=ObjectProperty
    #give profile a name
    Write Property Access   target=${profile_address_hex}   index=0   value=ProfileName   access==   data_type=EString

    #create profile2 object
    ${profile2_address_int}   ${profile2_address_hex}=   Get Object Address   0x9000
    #create profile object (value={'address':${profile_address_int}, 'object-type':32833})
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile2_address_int}, 32833   access=+   data_type=ObjectProperty
    #give profile a name
    Write Property Access   target=${profile2_address_hex}   index=0   value=Profile Name   access==   data_type=EString

    #create zone object in profile
    ${zone_address_int}   ${zone_address_hex}=   Get Object Address   0xF000
    #create zone object (value means {'address':${zone_address_int}, 'object-type':2}, value format in shark '61440, 2')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone_address_int}, 2   access=+    data_type=ObjectProperty

    #create fixture object
    ${fixture_address_int}   ${fixture_address_hex}=   Get Object Address   0xF001
    #create fixture object (value means {'address':${fixture_address_int}, 'object-type':4}, value format in shark '61441, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture_address_int}, 4   access=+    data_type=ObjectProperty
    #map fixture ioURI
    Write Property Access   target=${fixture_address_hex}   index=2   value=${fixture_URI}   access==   data_type=URI
    #map fixture FixtureModel (0x1C refers to the fixture template we added above)
    Write Property Access   target=${fixture_address_hex}   index=0   value=0x1C   access==   data_type=uint16
    #turn fixture Off
    Send Message   command=MsgT_ManualOff   target=${fixture_address_hex}
    Sleep   2s

    #create fixture2 object
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   0xF002
    #create fixture object (value means {'address':${fixture2_address_int}, 'object-type':4}, value format in shark '61442, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=+    data_type=ObjectProperty
    #map fixture ioURI
    Write Property Access   target=${fixture2_address_hex}   index=2   value=${fixture2_URI}   access==   data_type=URI
    #map fixture FixtureModel (0x1C refers to the fixture template we added above)
    Write Property Access   target=${fixture2_address_hex}   index=0   value=0x1C   access==   data_type=uint16
    #turn fixture Off
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s

    # map 1 sensor, and use fixture2 as a flashlight to wake up sensor during mapping
    Change Channel   extendedPanId=${extendedPanId}
    sleep   5s
    Write Property Access   target=${NetworkManager_address_hex}   index=24   value=[(3)]  access==   data_type=ZigBeeNetworkSecurityMode
    sleep   5s
    Send Message   command=MsgT_ManualOn   target=${fixture2_address_hex}
    Sleep   5s
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s
    Disconnect
    connect to ECU   ${mapping_tool_IP}
    Join Via Mapping Tool      eui64=${sensor}   extendedPanId=${extendedPanId}   linkKeyIndex=${linkKeyIndex}
    sleep   30s
    Disconnect
    connect to ECU   ${IP}
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture_sensor} > ${device_list_length_fixture}   No sensor is mapped to the ECU

    #create DAM object
    ${dam_address_int}   ${dam_address_hex}=   Get Object Address   0xF003
    #create DAM object (value means {'address':${fixture_address_int}, 'object-type':14}, value format in shark '61443, 14')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${dam_address_int}, 14   access=+    data_type=ObjectProperty
    #map photo sensor to DAM ioURI
    Write Property Access   target=${dam_address_hex}   index=3   value=${sensor_URI}   access==   data_type=URI

Breakdown System
    # unmap sensor from the ECU
    connect to ECU   ${IP}
    ${NetworkManager_address_int}   ${NetworkManager_address_hex}=   Get Object Address   0x0032
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_sensor}=   Evaluate   len($device_list)
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   0xF002
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_sensor_input}  access==   data_type=URI
    sleep   30s
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length_fixture_no_sensor}=   Evaluate   len($device_list)
    should be true   ${device_list_length_fixture_no_sensor} < ${device_list_length_fixture_sensor}   Sensor is NOT unmapped from the ECU

    #remove fixture object
    ${fixture_address_int}   ${fixture_address_hex}=   Get Object Address   0xF003
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture_address_int}, 14   access=-    data_type=ObjectProperty

    # unmap fixtures from the ECU
    Write Property Access   target=${NetworkManager_address_hex}   index=10   value=${prop_whiteListFromPolaris_empty_input}  access==   data_type=Dynarray
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_fixture_input}  access==   data_type=URI
    sleep   30s
    Disconnect   # to kick out 2 fixtures, you will
    connect to ECU   ${IP}
    Write Property Access   target=${NetworkManager_address_hex}   index=117   value=${prop_URIToDeleteNode_fixture2_input}  access==   data_type=URI
    sleep   30s
    ${device_list}=   Read Property Access   target=${NetworkManager_address_hex}   index=105
    ${device_list_length}=   Evaluate   len($device_list)
    should be true   ${device_list_length}==0   Fixtures are NOT unmapped from the ECU

    #remove fixture object
    ${fixture_address_int}   ${fixture_address_hex}=   Get Object Address   0xF001
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture_address_int}, 4   access=-    data_type=ObjectProperty

    #remove fixture2 object
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   0xF002
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=-    data_type=ObjectProperty

    #remove zone object
    ${zone_address_int}   ${zone_address_hex}=   Get Object Address   0xF000
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone_address_int}, 2   access=-    data_type=ObjectProperty

    #remove profile object (value={'address':${profile_address_int}, 'object-type':32833})
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   0x8000
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile_address_int}, 32833   access=-   data_type=ObjectProperty

    ${profile2_address_int}   ${profile2_address_hex}=   Get Object Address   0x9000
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile2_address_int}, 32833   access=-   data_type=ObjectProperty

    #remove fixture template
    Write Property Access   target=BallastTemplateManager   index=Templates   value=1C001C000000C84300000000000070420000404131204443001C39558EAAC6E3FF00000000   access=-   data_type=Dynarray
    Write Property Access   target=BallastTemplateManager   index=Templates   value=   access==   data_type=Dynarray

    #disconnect from ECU
    Disconnect

