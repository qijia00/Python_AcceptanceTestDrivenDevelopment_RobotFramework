import json
from datetime import datetime
from keywords import *
from robot.api import logger
from robot.libraries import BuiltIn
import paramiko
import os
import ntpath
import time
from zipfile import ZipFile

BUILTIN = BuiltIn.BuiltIn()


class WebServiceLibrary(_General_Keywords,
                        _Misc_Keywords,
                        _SiteManagement_Keywords,
                        _OffsetManagement_Keywords,
                        _TableManagement_Keywords,
                        _UserManagement_Keywords,
                        _ECUManagement_Keywords,
                        _Firmware_Keywords,
                        _Database_Keywords,
                        _Quality_Keywords,
                        _Updatewebservice_Keywords,
                        KeywordGroup):

    ROBOT_LIBRARY_VERSION = '0.21'
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_DOC_FORMAT = 'reST'

    def __init__(self):
        self._run_on_failure_keyword = None
        self._running_on_failure_routine = False

        for base in WebServiceLibrary.__bases__:
            base.__init__(self)

    def register_keyword_to_run_on_failure(self, keyword):
        old_keyword = self._run_on_failure_keyword
        old_keyword_text = old_keyword if old_keyword is not None else "Nothing"

        new_keyword = keyword if keyword.strip().lower() != "nothing" else None
        new_keyword_text = new_keyword if new_keyword is not None else "Nothing"

        self._run_on_failure_keyword = new_keyword
        #self._info('%s will be run on failure.' % new_keyword_text)

        return old_keyword_text

        # Private

    def _run_on_failure(self):
        if self._run_on_failure_keyword is None:
            return
        if self._running_on_failure_routine:
            return
        self._running_on_failure_routine = True
        try:
            BUILTIN.run_keyword(self._run_on_failure_keyword)
        except Exception as err:
            self._run_on_failure_error(err)
        finally:
            self._running_on_failure_routine = False

    def _run_on_failure_error(self, err):
        err = "Keyword '%s' could not be run on failure: %s" % (self._run_on_failure_keyword, err)
        if hasattr(self, '_warn'):
            self._warn(err)
            return
        raise Exception(err)

    def connect_to_web_services(self, ip_address, username='', password='', version='v2', session_index='',
                                db_read='true', dll=None, dll_data=None, timeout=None):
        """ Connect to ECU and Web Services

        Establish the URL with the ECU IP.

        Variables
            *ip_address*
                - ip address of the target ECU
            *username*
                - optional parameter to login into the ECU after connection
            *password*  
                - optional parameter to login into the ECU after connection
            *version*
                - v1 is for Room Controller/Encelium Edge, v2 is for Lumenade/Smart Lighting Platform
            *session_index*
                - optional input, will use the most recently returned session id if not specified
            *db_read*
                - optional input to obtain database information of master ECU after connection
                - empty return if no database such as for slave ECU
            *dll*
                - location of DataServiceDLL.dll
            *dll_data*
                - location to store the created offline site

        .. code:  robotframework

            *** Settings ***
            Suite Setup   Connect to ECU Web Service   ${ecu_ip}

            *** Variables ***
            ${ecu_ip}   192.168.97.99
            ${version}   v2
            ${user}   sysadmin
            ${def_pass}   1um3nad3
            ${pass}   newpassword
            ${offline_dll}   .//artifacts//DataServiceDLL.dll
            ${offline_storage}   .//artifacts//testdata

            *** Test Cases ***
            Sample
                Connect to web services   ${ecu_ip}    # Only connect, do not login
                Connect to web services   ${ecu_ip}   ${user}   ${def_pass}   ${version}
                Connect to web services   ${ecu_ip}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
        """

        def ping_ecu():
            startingtime = time.time()
            while time.time() - startingtime < timeout:
                rep = os.system('ping -w 2000 ' + ip_address.strip())
                if rep == 0:
                    adj_timeout = timeout + (time.time() - startingtime)
                    logger.info('ECU can be pinged, let\'s try connecting to webservices')
                    while time.time() - startingtime < adj_timeout:
                        try:
                            self.get_about()
                            break
                        except AssertionError, e:
                            logger.info('Exception while login: {0}'.format(e))
                            pass
                        time.sleep(10)
                    break

        self.base_url = 'https://{0}/api/{1}'.format(ip_address, version)
        logger.info("Live site base URL is {0}".format(self.base_url))

        _toggle = self.offline

        timeout = int(timeout) if timeout else 0
        ping_ecu()

        if dll:
            assert os.path.exists(dll), "Unable to find dll {0}".format(dll)
            assert os.path.exists(dll_data), "Unable to find data path {0}".format(dll_data)
            self._offline_mode(dll, dll_data)
            logger.info("We are connecting to an offline site instead with base URL: {0}".format(self.base_url))
        else:
            self._offline_mode(False, None)
            logger.info("We are connecting to an online site instead with base URL: {0}".format(self.base_url))

        if _toggle is not self.offline:
            _SiteManagement_Keywords.site_ids.clear()
            _SiteManagement_Keywords.site_names.clear()
            _UserManagement_Keywords.user_ids.clear()
            _UserManagement_Keywords.user_names.clear()
            _UserManagement_Keywords.user_groups.clear()
            _OffsetManagement_Keywords.offsets.clear()
            _Misc_Keywords.lock_id = None
            _Misc_Keywords.session_ids = dict()
            self._db_path = None

        if username or password:
            self.login(username, password)
            self.ip_address = ip_address

        if dll:
            self._extract_db_files(offline=dll_data)
        #else:
        #    self._extract_db_files(ip_address)

        _db_read = db_read.lower()

        if _db_read == 'true':
            try:

                _info = self.get_database_information(session_index)

                # Collect all databases
                for _db in _info:
                    if _db['file']:
                        self._set_db_path(_db['file'])

                # Extract floor plans
                floorplan_list = self._get_all_table_records('TBL_PLAN', 'IDENTIFIER')
                for list_item in floorplan_list:
                    if list_item not in _TableManagement_Keywords.floorplans.values():
                        _TableManagement_Keywords.floorplans[
                            'FLOOR{0}'.format(len(_TableManagement_Keywords.floorplans))] = list_item

            except AssertionError:
                logger.info('No database located in ECU', also_console=True)
            except KeyError:
                logger.info('Unable to extract database file', also_console=True)

    def disconnect_from_web_services(self):
        """  Disconnect from web services

        This function is called when switch between on-line and off-line webservice related tests.
        """
        self._close_dll()

    def compare_ecu_backups(self, backup1, backup2):
        """  Compares 2 ECU backups
        
        Compares critical ECU backup files and ensures they are the same:
            - ECU.NVRam
            - ECU.NVRam save 0
            - ECU.NVRam save 1
            - ECU.NVRam save 2
            - ECU.NVRam save 3
            - upgrade.script
            - ECU.ini
            - ECU.Id
            
        Variables
            *backup1*
                - first ECU backup file
            *backup2*
                - second ECU backup file

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Compare ecu backups   .//artifacts//ecu_backup1.zip   .//artifacts//ecu_backup2.zip
        """

        checklist = list()
        checklist.append('ECU.NVRAM')
        checklist.append('upgrade.script')
        checklist.append('ECU.ini')
        checklist.append('ECU.id')

        assert os.path.exists(backup1), ImportError('Unable to find file {0}'.format(backup1))
        assert os.path.exists(backup2), ImportError('Unable to find file {0}'.format(backup2))

        _backup1 = ZipFile(backup1)
        _backup2 = ZipFile(backup2)

        for item in _backup1.infolist():
            if item.filename in checklist:
                assert item.file_size == _backup2.getinfo(item.filename).file_size, \
                    AssertionError('File {0} size does not match!'.format(item.filename))

    def compare_site_backups(self, backup1, backup2):
        """  Compares 2 site backups

        Compares critical site backup files and ensures they are the same:
            - site database
            - site floorplan

        Variables
            *backup1*
                - first site backup file
            *backup2*
                - second site backup file

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Compare site backups   .//artifacts//site_backup1.zip   .//artifacts//site_backup2.zip
        """

        checklist = list()
        checklist.append('.sqlite')
        checklist.append('.egf.gz')

        assert os.path.exists(backup1), ImportError('Unable to find file {0}'.format(backup1))
        assert os.path.exists(backup2), ImportError('Unable to find file {0}'.format(backup2))

        _backup1 = ZipFile(backup1)
        _backup2 = ZipFile(backup2)

        for item in _backup1.infolist():
            for check in checklist:
                if check in item.filename:
                    assert item.file_size == _backup2.getinfo(item.filename).file_size, \
                        AssertionError('File {0} size does not match!'.format(item.filename))

    def bring_ecu_into_site(self, master_ecu_ip, ecu_name="IamECU", site_type="lumenade", offset=''):
        """ Bring ECU into Site

        Brings a ecu into a site. Note that once bring-into-site is called for a slave ECU, you will need to log out and log back in again.

        Variable
            *master_ecu_ip*
                - master ECU IP
            *ecu_name*
                - string that contains ecu name
            *site_type*
                - site type, ems, room controller, lumenade.
            *offset*
                - ecu offset, either 0 (not part of a site) or >=100 (part of a site)

        .. code:: robotframework

            *** Test Cases ***
            Sample
                # To bring a master ECU into site
                Bring ECU into site  &{master_ECU_IP}   ecu_name=MasterECU
                # To bring a slave ECU into site
                Get offsets   SITE0   1
                Bring ECU into site   &{master_ECU_IP}   ecu_name=SlaveECU   site_type=lumenade   offset=OFFSET0
                Logout
                Login   SiteUserName   SiteUserPassword

        For more information, visit `/bring-into-site`_.

        .. _/bring-into-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/bring-into-site
        """
        # _offset = None

        if offset:
            assert offset in self.offsets.keys(), AssertionError('Unable to find offset {0}'.format(offset))
            # _offset = offset
            # logger.info(self.offsets[_offset])
            logger.info(self.offsets[offset])

        siteinfo = dict()

        siteinfo['date'] = datetime.now().strftime('%d/%m/%Y %I:%M:%S %p')
        siteinfo['ecu-name'] = ecu_name
        # if try to bring the master ECU to site, then use the registration_offset, which is the polaris offset
        # else if try to bring a slave ECU to site, then use an allocated offset
        siteinfo['ecu-offset'] = self.get_registration_offset() if offset == '' else _OffsetManagement_Keywords.offsets[offset]
        #siteinfo['ecu-offset'] = self.get_offsets(self, 'SITE0', 1)[0]
        siteinfo['master-ecu-ip'] = master_ecu_ip
        siteinfo['site-id'] = _SiteManagement_Keywords.site_ids['SITE0']
        siteinfo['site-name'] = _SiteManagement_Keywords.site_names['SITE0']
        siteinfo['site-type'] = site_type

        self._bring_into_site(json.dumps(siteinfo))
        time.sleep(1)

