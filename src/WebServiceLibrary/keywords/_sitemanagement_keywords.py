import os
import zipfile
import shutil
import time
import json
import paramiko
from robot.api import logger
from datetime import datetime
from _WebServiceCore import _WebServiceCore


class _SiteManagement_Keywords(_WebServiceCore):
    site_ids = dict()
    site_names = dict()

    def get_site_id(self, site_index, session_index=''):
        """ Get Site ID
        
        Get site ID from a list of site IDs generated by calling the keyword \`Get database information\`.
        
        Variable
            *site_index*
                - reference to the site id index generated by reading the ECU databases
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: python
        
            {
                'site': 'CC8E39AC-D813-427E-92B3-D0B141EA0FF9'
            }
            
        For more information, visit `/site/X`_.
        
        .. _/site/X: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/site/X        
        """
        logger.warn('This site ID rest api is going to change...')
        logger.info('Site IDs must identified from the received database')

        assert site_index in _SiteManagement_Keywords.site_ids, \
            AssertionError('Invalid site number.  Please select from {0}'
                           .format(_SiteManagement_Keywords.site_ids.keys()))

        site_id = self._assert_json_response_stop_on_error(
            self._get('site/{0}'.format(_SiteManagement_Keywords.site_ids[site_index])), 'site-id', session_index=session_index)

        logger.info("Site ID: {0}".format(site_id))

        return site_id

    def validate_site_id(self, site_index):
        """ Validate Site ID
        
        Checks whether site ID is in list of site ids received from the ECU.
        
        Variable
            *site_index*
                - reference to the site id index generated by reading the ECU databases
                - validates the existence of site index
        """

        assert site_index in _SiteManagement_Keywords.site_ids.keys(), \
            AssertionError('Unable to find {0} from {1}'.format(site_index, _SiteManagement_Keywords.site_ids.keys()))

    def delete_site_with_id(self, site_index, session_index=''):
        """ Delete Site With ID
        
        Removes a site ID from a list of site IDs generated by calling the keyword \`Get database information\`.
        
        Variable
            *site_index*
                - reference to the site id index generated by reading the ECU databases
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Get database information
                Delete site with id   SITE0

        For more information, visit `/site/X`_.
        
        .. _/site/X: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/site/X        
        """
        self.validate_site_id(site_index)
        self._assert_json_response_stop_on_error(self._delete('site/{0}'.format(_SiteManagement_Keywords.site_ids[site_index]), session_index=session_index))

    def bring_into_site_status(self, complete=''):
        """ Bring into Site Status
        
        Queries the ECU of the \`Bring into site\` status.        
        It is possible to call this keyword if *complete* variable is populated.
        
        Variable
            *complete*
                - optional variable to dictate a complete check on the \`Bring into site\` keyword
                        
        For more information, visit `/bring-into-site`_.
        
        .. _/bring-into-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/bring-into-site     
        """
        status = self._assert_json_response_stop_on_error(self._get('bring-into-site'), 'done')

        _complete = complete.lower()

        if _complete == 'true' and status is False:
            raise AssertionError("Bring into site is not finished!")

        return status

    def _bring_into_site(self, json_payload, timeout=120):
        """ Bring ECU into Site internal functions

        bring_ecu_into_site located in src\WebServiceLibrary\_init_.py consumes this function.
        """
        try:
            site_info = json.loads(json_payload)
        except ValueError:
            logger.error('Invalid json payload!')
            return

        for item in ('date',
                     'ecu-name',
                     'ecu-offset',
                     'master-ecu-ip',
                     'site-id',
                     'site-name',
                     'site-type'):

            assert item in site_info, AssertionError('Unable to find {0}'.format(item))

        self._assert_json_response_stop_on_error(self._post('bring-into-site', json_payload))
        assert int(timeout), ValueError('Invalid timeout parameter')

        _timeout = int(timeout)
        for i in range(0, _timeout):
            try:
                self.bring_into_site_status('True')
                logger.info('Bring ECU into site complete.')
                return
            except AssertionError:
                time.sleep(1.0)

        raise AssertionError('Unable to bring ECU into site.')

    def remove_from_site_status(self, complete=''):
        """ Remove from Site Status
        
        Queries the ECU of the \`Remove from site\` status.        
        It is possible to call this keyword if *complete* variable is populated.
        
        Variable
            *complete*
                - optional variable to dictate a complete check on the \`Remove from site\` keyword

        For more information, visit `/remove-from-site`_.
        
        .. _/remove-from-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/remove-from-site
        """
        status = self._assert_json_response_stop_on_error(self._get('remove-from-site'), 'done')

        _complete = complete.lower()

        if _complete == 'true' and status is False:
            raise AssertionError("Remove site is not finished!")

        return status

    def remove_from_site(self, timeout=45, session_index=''):
        """ Remove from Site Status

        Removes the ECU from the site.
        
        Variable
            *timeout*
                - optional parameter to set the wait time of removing ECU from site.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                # Note after Remove from site, no need to Logout,
                # especially for slave ECU it will fail see LUM-2181
                Remove from site

        For more information, visit `/remove-from-site`_.

        .. _/remove-from-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/remove-from-site
        """
        self._assert_json_response_stop_on_error(self._post('remove-from-site', session_index=session_index))
        assert int(timeout), ValueError('Invalid timeout parameter')

        # Keep getting remove from site status until it is done
        _timeout = int(timeout)

        for i in range(0, _timeout):
            try:
                self.remove_from_site_status('True')
                logger.info('Remove from site complete.')
                logger.info('Sleep 45 seconds for ecu to reboot after remove from site', also_console=True)
                time.sleep(45)
                return
            except AssertionError:
                time.sleep(1.0)

        raise AssertionError('Unable to confirm ECU removal from site.')

    def create_new_site(self, json_payload, timeout=30, session_index=''):
        """ Create a new site
        
        Variable 
            *json_payload*
                - string that contains json configuration of the site
            *timeout*
                - optional parameter to set the wait time to get the create site status.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variables ***
            ${user}   sysadmin
            ${pass}   newpassword
            ${new_site}   SEPARATOR=\n
            ...     {
            ...         "name": "Site management test",
            ...         "version": "Version 4.0.0",
            ...         "customer": "QA",
            ...         "project": "Robot",
            ...         "author": "Jia",
            ...         "default": true,
            ...         "date": "06/29/2017 9:54:00 AM",
            ...         "username": "${user}",
            ...         "password": "${pass}",
            ...         "fullname": "System Administrator",
            ...         "site-type": "lumenade"
            ...     }

            *** Test Cases ***
            Sample
                Create new site   ${new_site}
            
        For more information, visit `/create-site`_.

        .. _/create-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/create-site
        """
        assert int(timeout), ValueError('Invalid timeout parameter')

        try:
            site_info = json.loads(json_payload)
            logger.info(site_info)
        except ValueError:
            raise ValueError('Invalid json payload!')

        for item in ('name',
                     'version',
                     'customer',
                     'project',
                     'author',
                     'default',
                     'date',
                     'password',
                     'username',
                     'fullname'):

            assert item in site_info, AssertionError('Unable to find {0}'.format(item))

        site_info['date'] = datetime.strftime(datetime.now(), '%m/%d/%Y %I:%M:%S %p')

        # Create a new site
        self._assert_json_response_stop_on_error(self._post('create-site', json_payload, session_index=session_index))

        # Keep getting create site status until it is done
        _timeout = int(timeout)

        for i in range(0, _timeout):
            try:
                self.create_site_status('True', session_index=session_index)
                logger.info('Create site complete.')
                return
            except AssertionError:
                time.sleep(1.0)

        raise AssertionError('Unable to confirm completion of create site')

    def create_site_status(self, complete='', session_index=''):
        """ Create Site Status
        
        Creates a site
        
        Variable
            *complete*
                - optional variable to dictate a complete check on the \`Create site\` keyword
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/create-site`_.
        
        .. _/create-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/create-site
        """
        logger.info('Requesting create site status')
        status = self._assert_json_response_stop_on_error(self._get('create-site', 'done', session_index=session_index), True)

        _complete = complete.lower()

        if _complete == 'true' and not status:
            raise AssertionError("Create site is not finished!")

        return status

    def backup_site_download(self, location, session_index=''):
        """ Backup site download

        Backup on-line site (download site archive - database + plans).
        \`Backup site\` must be called first prior to attempting to download the backup.

        Variable
            *location*
                - file location to save the site backup to
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/backup-site-download`_.
        
        .. _/backup-site-download: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-site-download
        """

        _location = os.path.dirname(location)
        if not os.path.exists(_location):
            os.makedirs(_location)

        response = self._get('backup-site-download', session_index=session_index)

        with open(location, 'wb') as site:
            site.write(response[0].content)

        assert os.path.getsize(location) > 1000, AssertionError('Invalid site backup!')

    def backup_site_status(self, complete='', session_index=''):
        """ Backup site Status

        Queries the ECU of the backup site progress.
        It is possible to assert a complete status of this keyword if the *complete* variable is set to true.

        Variable
            *complete*
                - optional variable to dictate a complete check on \`Backup Site\` status
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Backup site status   complete=True

        For more information, visit `/backup-site`_.

        .. _/backup-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-site
        """
        status = self._assert_json_response_stop_on_error(self._get('backup-site', session_index=session_index), 'done')

        _complete = complete.lower()

        if _complete == 'true' and status is False:
            raise AssertionError("Backup site not yet complete!")

        return status

    def backup_site(self, timeout=30, session_index=''):
        """ Backup site 

        Signals the ECU to start a site backup

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                backup site

        For more information, visit `/backup-site`_.

        .. _/backup-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-site
        """
        self._assert_json_response_stop_on_error(self._post('backup-site', session_index=session_index))
        assert int(timeout), AssertionError('Invalid timeout parameter')

        _timeout = int(timeout)

        # Temporary fix to handle the timing problem between the request and status
        # time.sleep(3)

        for i in range(0, _timeout):
            try:
                self.backup_site_status('True', session_index=session_index)
                logger.info('Backup site complete.', also_console=True)
                return
            except AssertionError:
                time.sleep(1.0)

        raise AssertionError('Unable to confirm site backup.')

    def backup_site_cancel(self, session_index=''):
        """ Cancels site Backup 

        Cancels an in-progress site backup
        
        For more information, visit `/backup-site-cancel`_.

        .. _/backup-site-cancel: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-site-cancel
        """

        self._assert_json_response_stop_on_error(self._post('backup-site-cancel', session_index=session_index))

    def backup_site_and_download(self, location, timeout=30, offline=False, session_index=''):
        """ Backs-up the Site and Downloads

        For online site, this is a complex keyword that calls the following keywords, \`Backup site\` and \`Backup site download\`.
        Signals the ECU to start site backup. Once complete, downloads the site backup file and stores it into *location*.
        For offline site, zip the db, floorplan, and db.json files into *location*.

        Variable
            *location*
                - target output file for the ECU backups
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${IP}   10.215.21.121
            ${user}   sysadmin
            ${pass}   newpassword
            ${offline_dll}   .//artifacts//DataServiceDLL.dll
            ${offline_storage}   .//artifacts//testdata
            ${backup_site_file_location}   .//artifacts//site_backup.zip

            *** Test Cases ***
            Sample
                Connect to web services   ${IP}   ${user}   ${pass}   dll=${offline_dll}   dll_data=${offline_storage}
                Backup site and download   location=${backup_site_file_location}   offline=True

                Connect to web services   ${IP}   ${user}   ${pass}
                Backup site and download   location=${backup_site_file_location}
        """
        if not offline:
            assert int(timeout), ValueError('Invalid timeout parameter')
            _timeout = int(timeout)

            try:
                self.backup_site(_timeout, session_index=session_index)
                time.sleep(3)
                self.backup_site_download(location, session_index=session_index)
            except AssertionError:
                self.backup_site_cancel(session_index=session_index)
                raise AssertionError('Unable to backup site and download configuration')
        else:
            db_folder = './/artifacts//testdata//data//db'
            db_files = os.listdir(db_folder)
            for f in db_files:
                if f.endswith('sqlite'):
                    db_file = os.path.join(db_folder, f).replace('\\', '//')

            plan_file_exists = False
            plan_folder = './/artifacts//testdata//data//plan'
            plan_files = os.listdir(plan_folder)
            for f in plan_files:
                if f.endswith('egf.gz'):
                    plan_file_exists = True
                    plan_file = os.path.join(plan_folder, f).replace('\\', '//')

            db_json = './/artifacts//testdata//data//db.json'

            directory_inside_zip = './/artifacts//zip_temp//firmware//upgrade'
            if not os.path.exists(directory_inside_zip):
                os.makedirs(directory_inside_zip)

            db_file_copy = os.path.join(directory_inside_zip, os.path.basename(db_file))
            shutil.copyfile(db_file, db_file_copy)

            if plan_file_exists:
                plan_file_copy = os.path.join(directory_inside_zip, os.path.basename(plan_file))
                shutil.copyfile(plan_file, plan_file_copy)

            db_json_copy = os.path.join(directory_inside_zip, os.path.basename(db_json))
            shutil.copyfile(db_json, db_json_copy)

            directory_to_zip = './/artifacts//zip_temp//'

            with zipfile.ZipFile(location, mode='w') as zf:
                for root, dirs, files in os.walk(directory_to_zip):
                    for f in files:
                        path = os.path.normpath(os.path.join(root, f))
                        zf.write(path, os.path.relpath(path, directory_to_zip))

            shutil.rmtree('.//artifacts//zip_temp')

    def rename_site(self, json_payload, site_index, session_index=''):
        """ Rename site

        Changes the name of the site. Note that this changes the name of the site, as well as the database file stored on the ECU.

        Variable
            *site_name*
                - file location of the site to restore
            *site_index*
                - reference to the site id index generated by reading the ECU databases
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

         .. code:: robotframework

            *** Variable ***
            ${site_name}   SEPARATOR=\n
            ...   {
            ...       "site-name" : "New Name"
            ...   }

            *** Test Cases ***
            Sample
                login   username   password   #SESSION0 returned
                Get Database Information   #SITE0 returned
                Rename Site   ${site_name}   SITE0
                Rename Site   ${site_name}   SITE0   SESSION0

        For more information, visit `/rename-site`_.

        .. _/rename-site: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/rename-site
        """
        assert site_index in _SiteManagement_Keywords.site_ids, \
            AssertionError('Invalid site {0}. Please select from the following sites {1}'
                           .format(site_index, _SiteManagement_Keywords.site_ids.keys()))

        try:
            site_name = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        assert 'site-name' in site_name.keys(), AssertionError('Unable to find site_name from input')

        response = self._assert_json_response_stop_on_error(self._post('rename-site', json_payload, session_index=session_index))
        logger.info('input is {0}'.format(site_name))
        logger.info('response is {0}'.format(response))

    def restore_site(self, site_backup, site_index='', session_index=''):
        """ Restore site

        Restore site (upload site archive)

        Variable
            *site_backup*
                - file location of the site to restore
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

         .. code:: robotframework

            *** Test Cases ***
            Sample
                # when ECU is out of site before restore site
                Restore Site   ecu_backup=file
                # when ECU is in site before restore site
                login   username   password   #SESSION0 returned
                Get Database Information   #SITE0 returned
                Restore Site   ecu_backup=file   SITE0
                Restore Site   ecu_backup=file   SITE0   SESSION0

        For more information, visit `/restore-site`_.

        .. _/restore-site: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/restore-site
        """
        assert os.path.exists(site_backup), ImportError('Unable to find file {0}'.format(site_backup))

        if site_index is '':
            with open(site_backup, 'rb') as backup:
                self._assert_json_response_stop_on_error(self._post('restore-site', backup))
        else:
            assert site_index in _SiteManagement_Keywords.site_ids, \
                AssertionError('Invalid site {0}. Please select from the following sites {1}'
                               .format(site_index, _SiteManagement_Keywords.site_ids.keys()))
            with open(site_backup, 'rb') as backup:
                self._assert_json_response_stop_on_error(self._post(
                    'restore-site/{0}'.format(_SiteManagement_Keywords.site_ids[site_index]), backup, session_index=session_index))
