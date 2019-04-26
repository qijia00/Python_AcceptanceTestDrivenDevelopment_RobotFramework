import json
import os
import sqlite3
import paramiko
from robot.api import logger
from _WebServiceCore import _WebServiceCore
from _sitemanagement_keywords import _SiteManagement_Keywords as siteinfo
from _usermanagement_keywords import _UserManagement_Keywords as usersinfo


class _Misc_Keywords(_WebServiceCore):
    lock_id = None

    def get_about(self):
        """ Request ECU information
        
        Queries the ECU for the following information     
        
        .. code:: python
                
            {
                'ssid': 'ENC-02F3AF64',
                'copyright': 'Copyright 2016 OSRAM SYLVANIA Inc and its licensors. All rights reserved.', 
                'free-disk-space-string': '66 MB',
                'version': '1.0',
                'architecture': 'arm-little_endian-ilp32-eabi-hardfloat',
                'build-date': 'Monday February 27 2017 12:46:41',
                'os': 'linux 3.0.15-encelium-svn63089',
                'free-disk-space': 70213632
            }
            
        For more information, visit `/about`_.
        
        .. _/about: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/about
        """
        self._get_about()

    def get_automated_backup_configuration(self, session_index=''):
        """ Request Automated ECU Backup Configuration
        
        Gets the current parameters for ECU distributed backup

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Get Automated Backup Configuration
            
        For more information, visit `/automated-backup-config`_.
        
        .. _/automated-backup-config: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-GET.2
        """
        self._assert_json_response_stop_on_error(self._get('automated-backup-config', session_index=session_index))

    def set_automated_backup_configuration(self, json_payload, session_index=''):
        """ Sets Automated Backup Configuration Parameters
        
        Sets new parameters for ECU distributed backup.
        
        Variable
            *json_payload*
                - string that contains json configuration information
                - passed as a robot framework variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.
            
        .. code:: robotframework
        
            *** Variable ***
            ${payload}   SEPARATOR=\\n
            ...   {
            ...      "automated-backups": [
            ...      {
            ...        "backup-type": "site-backup",
            ...        "store-log-files": "all-backups",
            ...        "time-of-day": 9,
            ...        "day-of-week": "Monday",
            ...        "num-of-months": 2,
            ...        "week-of-month": 2,
            ...        "num-of-weeks": 2,
            ...        "num-of-days": 1,
            ...        "ecu-address": "10.215.20.12"
            ...      },
            ...      {
            ...        "backup-type": "ecu-backup",
            ...        "store-log-files": "none",
            ...        "time-of-day": 13,
            ...        "day-of-week": "Saturday",
            ...        "num-of-months": 2,
            ...        "week-of-month": 3,
            ...        "num-of-weeks": 2,
            ...        "num-of-days": 3,
            ...        "ecu-address": "172.24.172.200"
            ...       }
            ...     ]
            ...  }

            *** Test Cases ***
            Sample
                Set backup configuration   json_payload=${payload}
        
        For more information, visit `/automated-backup-config`

        .. _/automated-backup-config: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-config
        """
        try:
            backup_config = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        assert 'automated-backups' in backup_config.keys(), AssertionError('Unable to find automated-backups.')
        automated_backups_list = backup_config['automated-backups']
        for list_item in automated_backups_list:
            logger.info('list_item is {0}'.format(list_item))
            for key in ('backup-type',
                        'store-log-files',
                        'time-of-day',
                        'day-of-week',
                        'num-of-months',
                        'week-of-month',
                        'num-of-weeks',
                        'num-of-days',
                        'ecu-address'):
                assert key in list_item.keys(), AssertionError('Unable to find {0}'.format(key))

        self._assert_json_response_stop_on_error(self._post('automated-backup-config', json_payload, session_index=session_index))

    def get_automated_backup(self, session_index=''):
        """ Get Automated Backup

        Gets a list automated backup files

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Get Automated Backup

        For more information, visit `/automated-backup`_.

        .. _/automated-backup: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-GET.3
        """
        self._assert_json_response_stop_on_error(self._get('automated-backup', session_index=session_index))

    def automated_backup_download(self, json_payload, location, session_index=''):
        """ Download Automated Backed-up

        Returns selected automated backup files.

        Variable
            *json_payload*
                - specify ECU, time and backup file to download
            *location*
                - target output file for the ECU backups
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${payload}   SEPARATOR=\\n
            ...   {
            ...       "ecu-address": "172.24.172.200",
            ...       "backup-date": "2017-08-01",
            ...       "backup-name": "test.zip"
            ...   }

            *** Test Cases ***
            Sample
                automated backup download   json_payload=${payload}

        For more information, visit `/automated-backup-download`_.

        .. _/automated-backup-download: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/automated-backup-download
        """
        try:
            download_specification = json.loads(json_payload)
        except ValueError:
            logger.error('Invalid json payload!')
            return

        for item in ('ecu-address', 'backup-date', 'backup-name'):
            assert item in download_specification.keys(), AssertionError('Unable to find {0}'.format(item))

        _location = os.path.dirname(location)
        if not os.path.exists(_location):
            os.makedirs(_location)

        response = self._get('automated-backup-download', json_payload, session_index=session_index)
        logger.info('json_payload is {0}'.format(json_payload))
        logger.info('response is {0}'.format(response))
        logger.info('response[0].content is {0}'.format(response[0].content))

        with open(location, 'wb') as automated_backup:
            automated_backup.write(response[0].content)

        assert os.path.getsize(location) > 1000, AssertionError('Invalid ecu backup!')

    def get_database_information(self, expected_site_name='', session_index=''):
        """ Gets ECU Database Information
        
        Queries the database for the following information
        
        .. code:: python
        
            [
                {
                    "database-id": "D1F7B3D7-EAA6-4C9D-961F-258F0AF5EB45",
                    "database-name": "SOUTH_HEALTH_CAMPUS",
                    "file": "SOUTH_HEALTH_CAMPUS.sqlite",
                    "is-default": true,
                    "site-alias": "0",
                    "site-id": "41944E56-A6F2-4528-A88C-BCE3434A4939",
                    "update-id": "018194AF-1405-42DA-BC4F-5EBA06B703A7"
                },
                {
                    "database-id": "796BD86E-213E-4DF4-AC48-AC8D9265D9E0",
                    "database-name": "68_LEEK",
                    "file": "68_LEEK.sqlite",
                    "is-default": false,
                    "site-alias": "1",
                    "site-id": "497432EE-87EE-40EA-9214-D0EA5915D284",
                    "update-id": "39497047-E99E-4B0A-A024-9B23BA4DE6CF"
                },
                {
                    "database-id": "64EF90C5-94C1-45E9-BF6F-D7301B6DF631",
                    "database-name": "BROOKFIELD_TEST",
                    "file": "BROOKFIELD_TEST.sqlite",
                    "is-default": false,
                    "site-alias": "2",
                    "site-id": "8228B93D-F756-4EBD-B9C0-A6F0A4BF7B94",
                    "update-id": "A25E7205-1403-496D-B057-FA5A324D08CE"
                }
            ]

        .. code:: robotframework

            *** Variable ***
            ${IP}   172.24.172.111
            ${site_original}   Site management test

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}   # SESSION0 is returned
                Get database information
                Get database information   SESSION0
                Get Database Information   expected_site_name=${site_original}

        For more information, visit `/db-info`_.
        
        .. _/db-info: http://http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/db-info
        """
        response = self._assert_non_json_response_stop_on_error(self._get('db-info', session_index=session_index), True)

        assert json.loads(response), AssertionError('Empty or invalid response from db-info API call')
        # logger.info('Received database response\n'
        #             '{0}'.format(response))

        #Extract site ids
        siteinfo.site_ids = dict()

        for site in json.loads(response):
            _site_index = 'SITE{0}'.format(len(siteinfo.site_ids))
            # logger.info('_site_index is {0}'.format(_site_index))
            # logger.info(siteinfo.site_ids)
            # logger.info(site.keys())

            assert 'site-id' in site.keys(), KeyError('Unable to find site-id')
            if site['site-id'] not in siteinfo.site_ids.values():
                siteinfo.site_ids[_site_index] = site['site-id']

            assert 'database-name' in site.keys(), KeyError('Unable to find database-name')
            if site['database-name'] not in siteinfo.site_names.values():
                siteinfo.site_names[_site_index] = site['database-name']

            assert 'file' in site.keys(), KeyError('Unable to find file')

        if expected_site_name is not '':
            # response is a string, inside string it is a list, inside list it is a dictionary
            # logger.info('response is {0} {1}'.format(response, type(response)))
            response_list = json.loads(response)
            # logger.info('response_object is {0} {1}'.format(response_list, type(response_list)))
            response_dictionary = response_list[0]
            # logger.info('response[0] is {0} {1}'.format(response_dictionary, type(response_dictionary)))
            # logger.info('expected_site_name is {0} {1}'.format(expected_site_name, type(response_dictionary)))
            assert response_dictionary["database-name"] == expected_site_name, AssertionError(
                'Expect site name to be {0}, but it actually is {1}'.format(expected_site_name, response_dictionary["database-name"]))

        # logger.info(type(response))   # <type 'str'>
        # logger.info(type(json.loads(response)))   #	<type 'list'>
        # logger.info(type(json.loads(response)[0]))   # <type 'dict'>
        return json.loads(response)

    def get_update_id(self, session_index=''):
        """ Returns update id

        Parse the update id out from the return of Get Database Information

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${IP}   172.24.172.111
            ${user}   sysadmin
            ${pass}   password
            ${tbl_add}      SEPARATOR=\\n
            ...   {
            ...       "lock-id": "",
            ...       "add": [
            ...           {
            ...               "db_info": [
            ...                   {"DB_DATA": "", "DB_NAME": "Jia", "DB_VALUE": "7+"}
            ...                ]
            ...           }
            ...       ]
            ...   }

            *** Test Cases ***
            Sample
                Connect to web services   ${IP}   ${user}   ${pass}
                Get user list
                ${lock_id}=   Lock configuration   USER0   force=true
                ${update_id}=   get update id
                Get database information
                Update tables   site_index=SITE0   json_payload=${tbl_add}   update_id=${update_id}   lock_id=${lock_id}

        For more information, visit `/db-info`_.

        .. _/db-info: http://http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/db-info
        """
        update_id = self.get_database_information(session_index)[0]['update-id']
        return update_id

    def get_ecu_information(self, session_index=''):
        """ Requests ECU Information
        
        The ECU responds with the following information
        
        .. code:: python
        
            {
                "firmware-version" : "4.0.0.128",
                "hw-config" : "ZigBee",
                "ecu-offset" : 181,
                "is-master" : true,
                "ecu-architecture" : "linux-armv5|linux-armv7|windows-x86"
            }
            
        For more information, visit `/ecu-info`_.
        
        .. _/ecu-info: http://http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/ecu-info
        """
        response = self._assert_json_response_stop_on_error(self._get('ecu-info', session_index=session_index))
        return response

    def get_ecu_offset(self, session_index=''):
        """ Returns ECU Offset

        Parse the ECU offset (int) out from the return of Get ECU Information

        .. code:: robotframework

            *** Test Cases ***
            Sample
                ${ecu_offset}=   get ecu offset

        For more information, visit `/ecu-info`_.

        .. _/ecu-info: http://http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/ecu-info
        """
        ecu_offset = self.get_ecu_information(session_index)['ecu-offset']
        # if ecu_offset = 0 then the ECU is not part of a site
        # when the ECU is part of a site, the ecu_offset should be an integer equal or larger than 100
        return ecu_offset

    def change_local_ip(self, json_payload, session_index=''):
        """ Change network configuration of Encelium network adapter of ECU.

        Returns success or fail.

        Variable
            *json_payload*
                - specify dhcp, netmask, gateways, ip address
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${payload}   SEPARATOR=\n
            ...   {
            ...       "Dhcp": false,
            ...       "Netmask": "255.255.255.0",
            ...       "Gateways": ["172.24.172.1"],
            ...       "Address": "172.24.172.222"
            ...   }

            *** Test Cases ***
            Sample
                change local ip   json_payload=${payload}
                clean sessions
                Connect to web services   ${IP_new}   ${user}   ${pass}   ${version}
                change local ip   json_payload=${original_master_IP}   session_index=SESSION0

        For more information, visit `/local-network`_.

        .. _/local-network: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/local-network
        """
        try:
            network_specification = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        for item in ('Dhcp', 'Netmask', 'Gateways', 'Address'):
            assert item in network_specification.keys(), AssertionError('Unable to find {0}'.format(item))

        response = self._assert_json_response_stop_on_error(self._post('local-network', json_payload, session_index=session_index))
        logger.info('input is {0}'.format(network_specification))
        logger.info('response is {0}'.format(response))

    def get_local_ip(self, expected_ip=''):
        """ Get Local IP
        
        Requests the local IP information of the ECU.
        
        .. code:: python
        
            {
                "ip-address": "192.168.1.1",
                "subnet-mask": "255.255.255.0",
                "is-routing": false
            }
            
        For more information, visit `/local-ip`_.
        
        .. _/local-ip: http://http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/local-ip
        """
        response = self._assert_json_response_stop_on_error(self._get('local-network'))
        if expected_ip is not '':
            assert response["ip-address"] == expected_ip, AssertionError('Expect ECU IP to be {0}, but it actually is {1}'.format(expected_ip, response["ip-address"]))
        return response["ip-address"]

    def get_locator(self, local_only=True):
        """ Get Locator Information

        Requests the current locator results.
        The keyword \`Start Locator\` should be called prior to this keyword.

        .. code:: python

            {
                "Results" : [
                {
                     "Address" : 100,
                     "Dns" : {
                         "Domain" : "",
                         "Servers" : [ "", "", "" ]
                     },
                    "EnceliumNetwork" : {
                         "Address" : "192.168.97.203",
                         "Dhcp" : false,
                         "Gateways" : [ "", "", "" ],
                         "HwAddr" : "00:14:2D:5B:C6:C4",
                         "Netmask" : "255.255.255.0",
                         "Port" : 4533
                      },
                      "Encryption" : {
                         "Port" : 0,
                         "PublicKey" : "",
                         "Version" : 0,
                         "VersionSupported" : 0
                      },
                      "FirmwareVersion" : "3.6.4.64180",
                      "Id" : "000D6F000310F41C",
                      "Name" : "Room Controller",
                      "SiteId" : "0E8B6C4D-CA59-4280-A99C-C65B177BC7BC",
                      "SiteName" : "brian",
                      "TenantNetwork" : {
                         "Address" : "",
                         "Dhcp" : true,
                         "Gateways" : [ "", "", "" ],
                         "HwAddr" : "",
                         "Netmask" : "",
                         "Port" : 4533
                      },
                      "Type" : {
                         "BusArch" : [ "ZigBee" ],
                         "HwArch" : "ZigBee",
                         "OsVersion" : "2.08___64180___2017-",
                         "ProcessorArch" : "ARMv7",
                         "SystemArch" : "Mini",
                         "SystemType" : 0
                      },
                      "WlanNetwork" : {
                         "Address" : "",
                         "Channel" : 1,
                         "Dhcp" : true,
                         "DhcpLeaseTime" : 72,
                         "DhcpRange" : "172.24.173.2,172.24.173.200",
                         "Gateways" : [ "", "", "" ],
                         "HwAddr" : "74:DA:38:8B:25:27",
                         "MasterHwAddr" : "74:DA:38:8B:25:27",
                         "Netmask" : "",
                         "Ssid" : "ENC-0310F41C"
                      }
                }
                ],
                "Timestamp" : "18/04/2017 18:16:15 PM"
            }

        For more information, visit `/locator`_.

        .. _/locator: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/locator
        """
        _input = dict()
        # every input from Robot Frame work is a string, we need to convert them to BOOL and NONE types
        if str(local_only).lower() == 'none':
            self._assert_json_response_stop_on_error(self._get('locator'))
        else:
            if str(local_only).lower() == 'true':
                local_only = True
            elif str(local_only).lower() == 'false':
                local_only = False
            _input['local-only'] = local_only
            self._assert_json_response_stop_on_error(self._get('locator', json.dumps(_input)))

    def start_locator(self, local_only):
        """ Start Locator Service
        
        Starts the locator on the ECU to scan the network.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Start Locator   local_only=True
                Start Locator   local_only=False
                Start Locator   local_only=
        
        For more information, visit `/locator`_.
        
        .. _/locator: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/locator
        """
        _input = dict()
        # every input from Robot Frame work is a string, we need to convert them to BOOL and NONE types
        if str(local_only).lower() == 'none':
            self._assert_json_response_stop_on_error(self._post('locator'))
        else:
            if str(local_only).lower() == 'true':
                local_only = True
            elif str(local_only).lower() == 'false':
                local_only = False
            _input['local-only'] = local_only
            self._assert_json_response_stop_on_error(self._post('locator', json.dumps(_input)))

    def configuration_lock_status(self, lock_id, session_index=''):
        """ Configuration Lock Status

        Queries the ECU for the configuration lock status.
        If the configuration is locked, a json response will be returned.
        If configuration is not locked, response is empty.

        For more information, visit `/configure-lock`_.

        .. _/configure-lock: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/configure-lock
        """

        _input = dict()
        # every input from Robot Frame work is a string, we need to convert them to BOOL and NONE types
        if str(lock_id).lower() == 'none':
            response = self._assert_json_response_stop_on_error(self._get('configure-lock', session_index=session_index))
        else:
            _input['lock-id'] = lock_id
            logger.info('input is {0}'.format(_input))
            response = self._assert_json_response_stop_on_error(self._get('configure-lock', json.dumps(_input), session_index=session_index))

        if response['lock']:
            logger.info('Configuration has been previously locked')
        else:
            logger.info('There is no configuration lock')

        return response

    def lock_configuration(self, user_index, force, session_index=''):
        """ Lock Configuration 
        
        Attempts to lock configuration of webservices.
        If successful, a lock id will be return.  
        If unsuccessful, a json response will be returned with the configuration lock information

        Variable
            *user_index*
                - which user you want to lock, call Get User List before.
            *force*
                - If configuration is locked by another user, current lock information is returned unless the "force" flag is true.
                - "force" is an optional flag in the input json.
                - If it is true, ECU does not check if lock is currently taken by another user and acquires the lock for the current user.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${user}   sysadmin
            ${pass}   newpassword

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}
                Get user list
                Lock configuration   USER0

        For more information, visit `/configure-lock`_.
        
        .. _/configure-lock: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/configure-lock
        """
        assert user_index in usersinfo.user_names.keys(), AssertionError('Invalid user {0}, '
                                                                         'please select from the following users {1}'
                                                                         .format(user_index, usersinfo.user_names.keys()))

        assert user_index in usersinfo.user_groups.keys(), AssertionError('Invalid user {0}, '
                                                                          'please select from the following users {1}'
                                                                          .format(user_index, usersinfo.user_groups.keys()))

        _json_payload = dict()
        _json_payload['user-name'] = usersinfo.user_names[user_index]
        _json_payload['user-group'] = usersinfo.user_groups[user_index]

        # every input from Robot Frame work is a string, we need to convert them to BOOL and NONE types
        if str(force).lower() != 'none':
            if str(force).lower() == 'true':
                force = True
            elif str(force).lower() == 'false':
                force = False
            _json_payload['force'] = force

        logger.info('input is {0}'.format(_json_payload))
        response = self._assert_json_response_stop_on_error(self._post('configure-lock', json.dumps(_json_payload), session_index=session_index))

        if 'lock-id' in response:
            _Misc_Keywords.lock_id = response['lock-id']
            logger.info('Configuration locked!')
            return _Misc_Keywords.lock_id
        else:
            raise AssertionError('Configuration lock unsuccessful!')

    def unlock_configuration(self, force, session_index=''):
        """ Unlock Configuration
        
        Attempts to unlock the configuration.

        Variable
            *force*
                - "force" flag is optional in input json string.
                - If force is set to true, server does not check the configured lock-id and deletes the current lock.
                - If "force" is false or not preset in input json, "lock-id" should match the current lock-id to be deleted.
                - Otherwise, an "invalid lock id" error is returned.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Unlock configuration   force=True

        For more information, visit `/configure-lock`_.
        
        .. _/configure-lock: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/configure-lock
        """

        _json_payload = dict()
        if _Misc_Keywords.lock_id is None:
            _Misc_Keywords.lock_id = 'give invalid id to test force=True otherwise will complain the lock_id type'
        _json_payload['lock-id'] = _Misc_Keywords.lock_id

        # every input from Robot Frame work is a string, we need to convert them to BOOL and NONE types
        if str(force).lower() != 'none':
            if str(force).lower() == 'true':
                force = True
            elif str(force).lower() == 'false':
                force = False
            _json_payload['force'] = force

        logger.info('input is {0}'.format(_json_payload))
        self._assert_json_response_stop_on_error(self._delete('configure-lock', json.dumps(_json_payload), session_index=session_index))
        _Misc_Keywords.lock_id = None

    def wink_ecu(self):
        """ Make the ECU identify itself via the wink (e.g. flash the blue light on the WM)

        Calling this will cause the ECU to wink.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                wink ecu

        For more information, visit `/wink`_.

        .. _/wink: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/wink
        """
        self._assert_json_response_stop_on_error(self._post('wink'))

    def validate_session(self, session_id='', session_index='', is_valid=True):
        """ Validate if a session id is valid

        Variable
            *session_id*
                - optional input, needs to specify either session_id or session_index
            *session_index*
                - optional input, needs to specify either session_id or session_index
            *is_valid*
                - do you expect the session id or session index to be valid or not

        .. code:: robotframework

            *** Variable ***
            ${IP}   172.24.172.111
            ${user}   sysadmin
            ${pass}   12345

            *** Test Cases ***
            Sample
                Connect to web services   ${IP}   ${user}   ${pass}   ${version}   # SESSION0 is returned
                validate session   session_index=SESSION0
                logout
                validate session   session_index=SESSION0   is_valid=False

            For more information, visit `/session`_.

        .. _/session: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/session
        """
        _input = dict()
        if session_id != '' and session_index == '':
            _input['session-id'] = session_id
        elif session_id == '' and session_index != '':
            assert session_index in _WebServiceCore.session_ids.keys(), \
                AssertionError(
                    'Unable to find {0} from {1}'.format(session_index, _WebServiceCore.session_ids.keys()))
            _input['session-id'] = _WebServiceCore.session_ids[session_index]
        else:
            assert False, AssertionError('Pass in either session_id or session_index.')
        logger.info('_input is {0}'.format(_input))
        response = self._assert_json_response_stop_on_error(self._get('session', json.dumps(_input)), True)

        if is_valid=='True':
            is_valid = True
        elif is_valid=='False':
            is_valid = False
        assert response['session']['is-valid'] == bool(is_valid), \
            AssertionError('session id is {0}, expect it to be {1}.'.format(response['session']['is-valid'], is_valid))

    def get_master_info(self, session_index=''):
        """ Get current "master pointing" information

        Get current "master pointing" information

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Get Master Info

        For more information, visit `/master-info`_.

        .. _/master-info: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/master-info
        """
        self._assert_json_response_stop_on_error(self._get('master-info', session_index=session_index))

    def set_master_info(self, json_payload, site_index, session_index=''):
        """ Set the current "master pointing" information.

        Set the current "master pointing" information.
        This will be periodically called by the master of the site to maintain the "mastering" information on all ECUs.

        Variable
            *json_payload*
                - string that contains json configuration information
                - passed as a robot framework variable
            *site_index*
                - reference to the site id index generated by reading the ECU databases
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${master_info}   SEPARATOR=\n
            ...   {
            ...      "master-ecu-ip": "172.24.172.100",
            ...      "site-id" : ""
            ...  }

            *** Test Cases ***
            Sample
                Connect to web services   ${master_IP}   ${user}   ${pass}   ${version}
                Get database information
                Logout
                Connect to web services   ${slave_IP}   ${user}   ${pass}   ${version}
                Set Master Info   json_payload=${master_info}   site_index=SITE0

        For more information, visit `/master-info`_.

        .. _/master-info: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/master-info
        """
        try:
            master_info = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        assert 'master-ecu-ip' in master_info.keys(), AssertionError('Unable to find master ecu address.')
        assert 'site-id' in master_info.keys(), AssertionError('Unable to find master ecu address.')

        self.validate_site_id(site_index)
        master_info['site-id'] = siteinfo.site_ids[site_index]

        self._assert_json_response_stop_on_error(
            self._post('master-info', json.dumps(master_info), session_index=session_index))
