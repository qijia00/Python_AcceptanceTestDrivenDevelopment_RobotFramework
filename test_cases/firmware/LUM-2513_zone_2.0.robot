*** Settings ***
Library             ECULibrary
Library             BuiltIn
Library             String
Library             Collections

#Suite Setup         Setup system
#Suite Teardown      Breakdown System

#why the script is semi-automated:
#back-end mapping is manually done http://wiki:8090/display/ERD/Back-end+mapping
#Note this script also requires 3 fixtures, 1 keypads, 1 sensor to run properly

#for debug, run shark from zone_2.0 branch code
Force Tags       firmware   semi-automated

*** Test Cases ***
#Test write zone prop_elements
#    Connect to ECU   ${IP}
#
#    ${Scheduler_Slave_address_with_ECU_offset_str}=   Build Address   ${scheduler_slave_address}
#    ${zone1_address_with_ECU_offset_str}=   Build Address   ${zone1_address}
#    ${zone2_address_with_ECU_offset_str}=   Build Address   ${zone2_address}
#    ${fixture1_address_with_ECU_offset_str}=   Build Address   ${fixture1_address}
#    ${fixture2_address_with_ECU_offset_str}=   Build Address   ${fixture2_address}
#    ${fixture3_address_with_ECU_offset_str}=   Build Address   ${fixture3_address}
#    ${ProgrammableController1_address_with_ECU_offset_str}=   Build Address   ${programmablecontroller1_address}
#    ${OccupancySensor1_address_with_ECU_offset_str}=   Build Address   ${OccupancySensor1_address}
#    set global variable   ${Scheduler_Slave_address_with_ECU_offset}   ${Scheduler_Slave_address_with_ECU_offset_str}
#    set global variable   ${zone1_address_with_ECU_offset}   ${zone1_address_with_ECU_offset_str}
#    set global variable   ${zone2_address_with_ECU_offset}   ${zone2_address_with_ECU_offset_str}
#    set global variable   ${fixture1_address_with_ECU_offset}   ${fixture1_address_with_ECU_offset_str}
#    set global variable   ${fixture2_address_with_ECU_offset}   ${fixture2_address_with_ECU_offset_str}
#    set global variable   ${fixture3_address_with_ECU_offset}   ${fixture3_address_with_ECU_offset_str}
#    set global variable   ${ProgrammableController1_address_with_ECU_offset}   ${ProgrammableController1_address_with_ECU_offset_str}
#    set global variable   ${OccupancySensor1_address_with_ECU_offset}   ${OccupancySensor1_address_with_ECU_offset_str}
#    ${zone1_prop_elements_input_temp}=   replace variables   ${zone1_prop_elements_input}
#    set global variable   ${zone1_prop_elements_input}   ${zone1_prop_elements_input_temp}
#    ${zone2_prop_elements_input_temp}=   replace variables   ${zone2_prop_elements_input}
#    set global variable   ${zone2_prop_elements_input}   ${zone2_prop_elements_input_temp}
#    ${zone3_prop_elements_input_temp}=   replace variables   ${zone3_prop_elements_input}
#    set global variable   ${zone3_prop_elements_input}   ${zone3_prop_elements_input_temp}
#
#    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
#    Write Property Access   target=${zone1_address_hex}   index=0   value=${zone1_prop_elements_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone1_address_hex}
#    Sleep   2s
#    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
#    Write Property Access   target=${zone2_address_hex}   index=0   value=${zone2_prop_elements_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone2_address_hex}
#    Sleep   2s
#    ${zone3_address_int}   ${zone3_address_hex}=   Get Object Address   ${zone3_address}
#    Write Property Access   target=${zone3_address_hex}   index=0   value=${zone3_prop_elements_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone3_address_hex}
#    Sleep   2s
#
#    #Verify input and output values are the same
#    ${zone1_prop_elements_output}=   Read Property Access   target=${zone1_address_hex}   index=0
#    ${zone2_prop_elements_output}=   Read Property Access   target=${zone2_address_hex}   index=0
#    ${zone3_prop_elements_output}=   Read Property Access   target=${zone3_address_hex}   index=0
#    Check shark output key dictionary of list   ${zone1_prop_elements_input}   ${zone1_prop_elements_output}
#    Check shark output key dictionary of list   ${zone2_prop_elements_input}   ${zone2_prop_elements_output}
#    Check shark output key dictionary of list   ${zone3_prop_elements_input}   ${zone3_prop_elements_output}

Test write zone prop_scenes
    Connect to ECU   ${IP}
#    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
#    Write Property Access   target=${zone1_address_hex}   index=1   value=${zone_prop_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone1_address_hex}
#    Sleep   2s
#    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
#    Write Property Access   target=${zone2_address_hex}   index=1   value=${zone_prop_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone2_address_hex}
#    Sleep   2s
#    ${zone3_address_int}   ${zone3_address_hex}=   Get Object Address   ${zone3_address}
#    Write Property Access   target=${zone3_address_hex}   index=1   value=${zone_prop_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone3_address_hex}
#    Sleep   2s
#    #Verify input and output values are the same
#    ${zone1_prop_scenes_output}=   Read Property Access   target=${zone1_address_hex}   index=1
#    ${zone2_prop_scenes_output}=   Read Property Access   target=${zone2_address_hex}   index=1
#    ${zone3_prop_scenes_output}=   Read Property Access   target=${zone3_address_hex}   index=1
#    Check shark output key dictionary of list   ${zone_prop_scenes_input}   ${zone1_prop_scenes_output}
#    Check shark output key dictionary of list   ${zone_prop_scenes_input}   ${zone2_prop_scenes_output}
#    Check shark output key dictionary of list   ${zone_prop_scenes_input}   ${zone3_prop_scenes_output}

    ${zone1_address_with_ECU_offset_str}=   Build Address   ${zone1_address}
    ${zone2_address_with_ECU_offset_str}=   Build Address   ${zone2_address}
    ${ProgrammableController1_address_with_ECU_offset_str}=   Build Address   ${programmablecontroller1_address}
    set global variable   ${zone1_address_with_ECU_offset}   ${zone1_address_with_ECU_offset_str}
    set global variable   ${zone2_address_with_ECU_offset}   ${zone2_address_with_ECU_offset_str}
    set global variable   ${ProgrammableController1_address_with_ECU_offset}   ${ProgrammableController1_address_with_ECU_offset_str}
    ${prop_groupList_input_temp}=   replace variables   ${prop_groupList_input}
    set global variable   ${prop_groupList_input}   ${prop_groupList_input_temp}

    #Assign keypad button actions.
    ${ProgrammableController1_address_int}   ${ProgrammableController1_address_hex}=   Get Object Address   ${ProgrammableController1_address}
    ${prop_groupList}=   groupList   ${prop_groupList_input}
    Log   the line below will fail due to "Don't know how to format type: Dynarray -- unit32", wait for Alex to look into this.   WARN
    #Write the keypad action target groups through Shark Target: ProgrammableController, Index: prop_groupList.
    Write Property Access   target=${ProgrammableController1_address_hex}   index=5   value=${prop_groupList}   access==   data_type=Dynarray -- unit32

    # The code below I have not check yet

    #Write the button actions in the keypad through Shark Target: ProgrammableController, Index: m_ButtonEventActionsConfig.
    Write Property Access   target=${ProgrammableController1_address_hex}   index=1   value=${m_ButtonEventActionsConfig_input}   access==   data_type=Dynarray
    #Write both prop_groupList and m_ButtonEventActionConfig, then save
    Send Message   command=MsgT_SaveConfiguration   target=${ProgrammableController1_address_hex}
    Sleep   2s
#    #Verify input and output values are the same (this may not be necessary!)
#    ${ProgrammableController1_prop_groupList_output}=   Read Property Access   target=${ProgrammableController1_address_hex}   index=5
#    ${a}=   Evaluate   $prop_groupList
#    ${b}=   Evaluate   type($prop_groupList)   #<type 'str'>
#    ${c}=   Evaluate   $ProgrammableController1_prop_groupList_output
#    ${d}=   Evaluate   type($ProgrammableController1_prop_groupList_output)   #<type 'str'>
#    Check shark output key list of dictionary   ${prop_groupList}   ${ProgrammableController1_prop_groupList_output}

#Test write zone prop_parameters
#    Connect to ECU   ${IP}
#    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
#    Write Property Access   target=${zone1_address_hex}   index=2   value=${zone_prop_parameters_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone1_address_hex}
#    Sleep   2s
#    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
#    Write Property Access   target=${zone2_address_hex}   index=2   value=${zone_prop_parameters_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone2_address_hex}
#    Sleep   2s
#    #Verify input and output values are the same
#    ${zone1_prop_parameters_output}=   Read Property Access   target=${zone1_address_hex}   index=2
#    ${zone2_prop_parameters_output}=   Read Property Access   target=${zone2_address_hex}   index=2
#    ${zone1_prop_parameters_output_string}=   convert to string   ${zone1_prop_parameters_output}
#    ${zone2_prop_parameters_output_string}=   convert to string   ${zone2_prop_parameters_output}
#    ${zone1_prop_parameters_output_string}=   Get Substring    ${zone1_prop_parameters_output_string}   start=0   end=-1
#    ${zone2_prop_parameters_output_string}=   Get Substring    ${zone2_prop_parameters_output_string}   start=0   end=-1
#    should be equal   ${zone_prop_parameters_input}   ${zone1_prop_parameters_output_string}
#    should be equal   ${zone_prop_parameters_input}   ${zone2_prop_parameters_output_string}

#Test fixture prop_scenes
#    Connect to ECU   ${IP}
#    ${fixture1_address_int}   ${fixture1_address_hex}=   Get Object Address   ${fixture1_address}
#    Write Property Access   target=${fixture1_address_hex}   index=67   value=${fixture_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${fixture1_address_hex}
#    Sleep   2s
#    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   ${fixture2_address}
#    Write Property Access   target=${fixture2_address_hex}   index=67   value=${fixture_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${fixture2_address_hex}
#    Sleep   2s
#    ${fixture3_address_int}   ${fixture3_address_hex}=   Get Object Address   ${fixture3_address}
#    Write Property Access   target=${fixture3_address_hex}   index=67   value=${fixture_scenes_input}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${fixture3_address_hex}
#    Sleep   2s
#    Read Property Acceess   target=$
#    Check Shark output key list of dictionary   ${fixture_scenes_input}   ${
#
#Test zone prop_direct_control
#    Connect to ECU   ${IP}
#    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
#    # Recall scene 1
#    Write Property Access   target=${zone1_address_hex}   index=66   value=${recall_scene1}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone1_address_hex}
#    Sleep   2s
#    # Recall scene 2
#    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
#    Write Property Access   target=${zone2_address_hex}   index=2   value=${recall_scene2}   access==   data_type=EString
#    Send Message   command=MsgT_SaveConfiguration   target=${zone2_address_hex}
#    Sleep   2s

*** Variables ***
${IP}   172.24.172.101

# use the ballast object type URI - CLM-DIM
${ballast1_URI}   ZigBee://000D6F00031105FC.02
# if test lamp failure, then use the fixture's DaliOnZB_CG_Fluor. object type URI, don't use the ballast object type URI - WALC connected with DALI lamp
${ballast2_URI}   DALI://2C36E5?V0=0000-FF
# use the ballast object type URI - DALI to Zigbee
${ballast3_URI}   ZigBee://000D6F000EBEE80E.0A

# keypad with scenes
${keypad1_URI}   ZigBee://000D6F0010107690.01

# occupancy sensor
${occupancy_sensor1_URI}   ZigBee://000D6F000310E74D.01

# the ECU offset is 0000 before bring it into site
${profile_address}   0x8000
${Scheduler_Slave_address}   FFF9
${Scheduler_Slave_address_with_ECU_offset}
${zone1_address}   0xFFFC
${zone1_address_with_ECU_offset}
${zone2_address}   0xFFFE
${zone2_address_with_ECU_offset}
${zone3_address}   0xFFF0
# ballast will be wrapped as fixture to have certain properties in Shark - Index
${fixture1_address}   0xFFFB
${fixture1_address_with_ECU_offset}
${fixture2_address}   0xFFFD
${fixture2_address_with_ECU_offset}
${fixture3_address}   0xFFF4
${fixture3_address_with_ECU_offset}
# keypad will be wrapped as ProgrammableController to have certain properties in Shark - Index
${ProgrammableController1_address}   0xFFF8
${ProgrammableController1_address_with_ECU_offset}
# occupancy sensor will be wrapped as OccupancySensor to have certain properties in Shark - Index
${OccupancySensor1_address}   0xFFF7
${OccupancySensor1_address_with_ECU_offset}

${zone1_prop_elements_input}   SEPARATOR=\n
...     {
...         "input-devices": [
...             {"address": "\${OccupancySensor1_address_with_ECU_offset}", "object-type": "ObjectT_OccupancySensor"},
...             {"address": "\${Scheduler_Slave_address_with_ECU_offset}", "object-type": "ObjectT_Scheduler_Slave"},
...             {"address": "\${ProgrammableController1_address_with_ECU_offset}", "object-type": "ObjectT_ProgrammableController"}
...         ],
...         "output-devices": [
...             {"address": "\${fixture1_address_with_ECU_offset}", "object-type": "ObjectT_Fixture"}
...         ],
...         "other": []
...     }

${zone2_prop_elements_input}   SEPARATOR=\n
...     {
...         "input-devices": [
...             {"address": "\${ProgrammableController1_address_with_ECU_offset}", "object-type": "ObjectT_ProgrammableController"}
...         ],
...         "output-devices": [
...             {"address": "\${fixture2_address_with_ECU_offset}", "object-type": "ObjectT_Fixture"}
...         ],
...         "other": []
...     }

${zone3_prop_elements_input}   SEPARATOR=\n
...     {
...         "input-devices": [
...             {"address": "\${zone1_address_with_ECU_offset}", "object-type": "ObjectT_Zone", "relationship": "comfort-master"},
...             {"address": "\${zone2_address_with_ECU_offset}", "object-type": "ObjectT_Zone", "relationship": "comfort-master"}
...         ],
...         "output-devices": [
...             {"address": "\${fixture3_address_with_ECU_offset}", "object-type": "ObjectT_Fixture"}
...         ],
...         "other": []
...     }

${zone_prop_scenes_input}   SEPARATOR=\n
...     {
...         "default-scene-id" : "11111111-1111-1111-1111-111111111111",
...         "scenes" : [
...             {"scene-alias": 0, "scene-id": "11111111-1111-1111-1111-111111111111", "name": "Meeting"},
...             {"scene-alias": 1, "scene-id": "22222222-2222-2222-2222-222222222222", "name": "Medium"},
...             {"scene-alias": 2, "scene-id": "33333333-3333-3333-3333-333333333333", "name": "Presentation"}
...         ]
...     }

${prop_groupList_input}   \${zone1_address_with_ECU_offset} \${zone1_address_with_ECU_offset} \${ProgrammableController1_address_with_ECU_offset} \${zone2_address_with_ECU_offset}

${fixture_scenes_input}   SEPARATOR=\n
...     [
...         {"scene-id": "11111111-1111-1111-1111-111111111111", "brightness": 1000, "fade-time": "0:05"},
...         {"scene-id": "22222222-2222-2222-2222-222222222222", "brightness":   50, "fade-time": "0:05"},
...         {"scene-id": "33333333-3333-3333-3333-333333333333", "brightness":    1, "color-temp": 5500},
...         {"scene-id": "44444444-4444-4444-4444-444444444444", "brightness":  700},
...         {"scene-id": "55555555-5555-5555-5555-555555555555", "brightness":  600}
...     ]

${zone_prop_parameters_input}   SEPARATOR=\n
...     {
...         'manual-extension-time':      '0:10',
...         'occupancy-extension-time':   '0:05',
...         'auto-turn-on':               True,
...         'comfort-brightness':         '60%',
...         'two-stage-off-brightness':   '20 ppk',
...         'two-stage-off-time':         '30:00',
...         'flickwarn-time':             '3:00',
...         'vacancy-recovery-time':      '0:45',
...         'occupancy-fade-to-off-time': '0:15',
...         'manual-fade-to-off-time':    '1:00'
...     }

${recall_scene1}   SEPARATOR=\n
...     {
...         'action':      'recall-scene',
...         'scene-id':    '11111111-1111-1111-1111-111111111111'
...     }

${recall_scene2}   SEPARATOR=\n
...     {
...         'action':      'recall-scene',
...         'scene-id':    '22222222-2222-2222-2222-222222222222'
...     }

*** Keywords ***
Setup system
    Connect to ECU   ${IP}

    # to find 'object-type' number, see "http://bitbucket:7990/projects/ECU/repos/ecu_properties/browse/config/ObjectIndices.cfg".

    #create profile object
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   ${profile_address}
    #create profile object (value={'address':${profile_address_int}, 'object-type':32833})
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile_address_int}, 32833   access=+   data_type=ObjectProperty

    #create zone1 object in profile
    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
    #create zone object (value means {'address':${zone_address_int}, 'object-type':2}, value format in shark '65532, 2')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone1_address_int}, 2   access=+    data_type=ObjectProperty

    #create zone2 object in profile
    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
    #create zone object (value means {'address':${zone_address_int}, 'object-type':2}, value format in shark '65534, 2')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone2_address_int}, 2   access=+    data_type=ObjectProperty

    #create zone3 object in profile
    ${zone3_address_int}   ${zone3_address_hex}=   Get Object Address   ${zone3_address}
    #create zone object (value means {'address':${zone_address_int}, 'object-type':2}, value format in shark '65520, 2')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone3_address_int}, 2   access=+    data_type=ObjectProperty

    #add fixture template
    Write Property Access   target=BallastTemplateManager   index=Templates   value=1C001C000000C84300000000000070420000404131204443001C39558EAAC6E3FF00000000   access==   data_type=Dynarray

    #create fixture1 object for ballast1
    ${fixture1_address_int}   ${fixture1_address_hex}=   Get Object Address   ${fixture1_address}
    #create fixture1 object (value means {'address':${fixture_address_int}, 'object-type':4}, value format in shark '65531, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture1_address_int}, 4   access=+    data_type=ObjectProperty
    #map fixture ioURI (the ballast should already manually mapped to the ECU)
    Write Property Access   target=${fixture1_address_hex}   index=2   value=${ballast1_URI}   access==   data_type=URI
    #map fixture FixtureModel (0x1C refers to the fixture template we added above)
    Write Property Access   target=${fixture1_address_hex}   index=0   value=0x1C   access==   data_type=uint16
    #turn fixture Off then On
    Send Message   command=MsgT_ManualOff   target=${fixture1_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture1_address_hex}
    Sleep   2s

    #create fixture2 object for ballast2
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   ${fixture2_address}
    #create fixture1 object (value means {'address':${fixture_address_int}, 'object-type':4}, value format in shark '65533, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=+    data_type=ObjectProperty
    #map fixture ioURI (the ballast should already manually mapped to the ECU)
    Write Property Access   target=${fixture2_address_hex}   index=2   value=${ballast2_URI}   access==   data_type=URI
    #map fixture FixtureModel (0x1C refers to the fixture template we added above)
    Write Property Access   target=${fixture2_address_hex}   index=0   value=0x1C   access==   data_type=uint16
    #turn fixture Off then On
    Send Message   command=MsgT_ManualOff   target=${fixture2_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture2_address_hex}
    Sleep   2s

    #create fixture3 object for ballast3
    ${fixture3_address_int}   ${fixture3_address_hex}=   Get Object Address   ${fixture3_address}
    #create fixture1 object (value means {'address':${fixture_address_int}, 'object-type':4}, value format in shark '65524, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture3_address_int}, 4   access=+    data_type=ObjectProperty
    #map fixture ioURI (the ballast should already manually mapped to the ECU)
    Write Property Access   target=${fixture3_address_hex}   index=2   value=${ballast3_URI}   access==   data_type=URI
    #map fixture FixtureModel (0x1C refers to the fixture template we added above)
    Write Property Access   target=${fixture3_address_hex}   index=0   value=0x1C   access==   data_type=uint16
    #turn fixture Off then On
    Send Message   command=MsgT_ManualOff   target=${fixture3_address_hex}
    Sleep   2s
    Send Message   command=MsgT_ManualOn   target=${fixture3_address_hex}
    Sleep   2s

    #create ProgrammableController1 object for keypad1
    ${ProgrammableController1_address_int}   ${ProgrammableController1_address_hex}=   Get Object Address   ${ProgrammableController1_address}
    #create ProgrammableController1 object (value means {'address':${ProgrammableController1_address_int}, 'object-type':174}, value format in shark '65528, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${ProgrammableController1_address_int}, 174   access=+    data_type=ObjectProperty
    #map ProgrammableController prop_uri (the keypad should already manually mapped to the ECU)
    Write Property Access   target=${ProgrammableController1_address_hex}   index=9   value=${keypad1_URI}   access==   data_type=URI

    #create OccupancySensor1 object for occupancy sensor1
    ${OccupancySensor1_address_int}   ${OccupancySensor1_address_hex}=   Get Object Address   ${OccupancySensor1_address}
    #create OccupancySensor1 object (value means {'address':${OccupancySensor1_address_int}, 'object-type':19}, value format in shark '65527, 4')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${OccupancySensor1_address_int}, 19   access=+    data_type=ObjectProperty
    #map OccupancySensor ioURI (the occupancy sensor should already manually mapped to the ECU)
    Write Property Access   target=${OccupancySensor1_address_hex}   index=1   value=${occupancy_sensor1_URI}   access==   data_type=URI

    #create Scheduler_Slave object
    ${Scheduler_Slave_address_int}   ${Scheduler_Slave_address_hex}=   Get Object Address   ${Scheduler_Slave_address}
    #create OccupancySensor1 object (value means {'address':${Scheduler_Slave_address_int}, 'object-type':75}, value format in shark '65529, 75')
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${Scheduler_Slave_address_int}, 75   access=+    data_type=ObjectProperty

Breakdown System
    #remove Scheduler_Slave object
    ${Scheduler_Slave_address_int}   ${Scheduler_Slave_address_hex}=   Get Object Address   ${Scheduler_Slave_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${Scheduler_Slave_address_int}, 75   access=-    data_type=ObjectProperty

    #remove OccupancySensor1 object
    ${OccupancySensor1_address_int}   ${OccupancySensor1_address_hex}=   Get Object Address   ${OccupancySensor1_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${OccupancySensor1_address_int}, 19   access=-    data_type=ObjectProperty

    #remove ProgrammableController1 object
    ${ProgrammableController1_address_int}   ${ProgrammableController1_address_hex}=   Get Object Address   ${ProgrammableController1_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${ProgrammableController1_address_int}, 174   access=-    data_type=ObjectProperty

    #remove ProgrammableController2 object
    ${ProgrammableController2_address_int}   ${ProgrammableController2_address_hex}=   Get Object Address   ${ProgrammableController2_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${ProgrammableController2_address_int}, 174   access=-    data_type=ObjectProperty

    #remove fixture1 object
    ${fixture1_address_int}   ${fixture1_address_hex}=   Get Object Address   ${fixture1_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture1_address_int}, 4   access=-    data_type=ObjectProperty

    #remove fixture2 object
    ${fixture2_address_int}   ${fixture2_address_hex}=   Get Object Address   ${fixture2_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture2_address_int}, 4   access=-    data_type=ObjectProperty

    #remove fixture3 object
    ${fixture3_address_int}   ${fixture3_address_hex}=   Get Object Address   ${fixture3_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${fixture3_address_int}, 4   access=-    data_type=ObjectProperty

    #remove fixture template
    Write Property Access   target=BallastTemplateManager   index=Templates   value=1C001C000000C84300000000000070420000404131204443001C39558EAAC6E3FF00000000   access=-   data_type=Dynarray
    Write Property Access   target=BallastTemplateManager   index=Templates   value=   access==   data_type=Dynarray

    #remove zone1 object
    ${zone1_address_int}   ${zone1_address_hex}=   Get Object Address   ${zone1_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone1_address_int}, 2   access=-    data_type=ObjectProperty

    #remove zone2 object
    ${zone2_address_int}   ${zone2_address_hex}=   Get Object Address   ${zone2_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone2_address_int}, 2   access=-    data_type=ObjectProperty

    #remove zone3 object
    ${zone3_address_int}   ${zone3_address_hex}=   Get Object Address   ${zone3_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${zone3_address_int}, 2   access=-    data_type=ObjectProperty

    #remove profile object (value={'address':${profile_address_int}, 'object-type':32833})
    ${profile_address_int}   ${profile_address_hex}=   Get Object Address   ${profile_address}
    Write Property Access   target=ObjectAssistant   index=ObjectList   value=${profile_address_int}, 32833   access=-   data_type=ObjectProperty

    #disconnect from ECU
    Disconnect

