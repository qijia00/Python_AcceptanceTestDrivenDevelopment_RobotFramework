import os
import time
import json
from requests import ConnectionError
from robot.api import logger
from _WebServiceCore import _WebServiceCore
from _sitemanagement_keywords import _SiteManagement_Keywords as siteinfo


class _ECUManagement_Keywords(_WebServiceCore):

    def backup_ecu_download(self, location, session_index=''):
        """ Download Backed-up Vital ECU Configuration
        
        Returns ECU data files.  
        
        Backups include, but are not limited to:
            - NVRAM files
            - Log files
            - ECU.ini
            - misc configuration flies
            
        Variable
            *location*
                - target output file for the ECU backups
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/backup-ecu-download`_.

        .. _/backup-ecu-download: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-ecu-download        
        """

        _location = os.path.dirname(location)
        if not os.path.exists(_location):
            os.makedirs(_location)

        response = self._get('backup-ecu-download', session_index=session_index)

        with open(location, 'wb') as ecu_backup:
            ecu_backup.write(response[0].content)

        assert os.path.getsize(location) > 1000, AssertionError('Invalid ecu backup!')

    def backup_ecu_status(self, complete='', session_index=''):
        """ Backup ECU Status
        
        Queries the ECU of the backup ECU progress.
        It is possible to assert a complete status of this keyword if the *complete* variable is set to true.
        
        Variable
            *complete*
                - optional variable to dictate a complete check on \`Backup ECU\` status
            *session_index*
                - optional input, will use the most recently returned session id if not specified.
                
        .. code:: robotframework
        
            *** Test Cases ***
            Sample
                Backup ECU status   complete=True
                
        For more information, visit `/backup-ecu`_.

        .. _/backup-ecu: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-ecu
        """
        status = self._assert_json_response_stop_on_error(self._get('backup-ecu', session_index=session_index), 'done')

        _complete = complete.lower()

        if _complete == 'true' and status is False:
            raise AssertionError("Backup ECU not yet complete!")

        return status

    def backup_ecu(self, json_payload, timeout=30, session_index=''):
        """ Backup ECU

        Signals the ECU to start an ECU backup

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/backup-ecu`_.

        .. _/backup-ecu: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-ecu
        """
        try:
            backup_specification = json.loads(json_payload)
        except ValueError:
            logger.error('Invalid json payload!')
            return

        if backup_specification:
            for item in ('store-log-files', 'store-event-files', 'store-core-dumps'):
                assert item in backup_specification.keys(), AssertionError('Unable to find {0}.'.format(item))
            self._assert_json_response_stop_on_error(self._post('backup-ecu', json_payload, session_index=session_index))
        else:
            self._assert_json_response_stop_on_error(self._post('backup-ecu', json.dumps({}), session_index=session_index))

        assert int(timeout), AssertionError('Invalid timeout parameter')
        _timeout = int(timeout)

        # Temporary fix to handle the timing problem between the request and status
        # time.sleep(3)

        for i in range(0, _timeout):
            try:
                self.backup_ecu_status('True')
                logger.info('Backup ECU complete.', also_console=True)
                return
            except AssertionError:
                time.sleep(1.0)

        raise AssertionError('Unable to confirm ECU backup.')

    def backup_ecu_cancel(self, session_index=''):
        """ Cancels ECU Backup 
        
        Cancels an in-progress ECU backup

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/backup-ecu-cancel`_.

        .. _/backup-ecu-cancel: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/backup-ecu-cancel
        """

        self._assert_json_response_stop_on_error(self._post('backup-ecu-cancel', session_index=session_index))

    def backup_ecu_and_download(self, json_payload, location, timeout=30, session_index=''):
        """ Backs-up the ECU and Downloads
        
        Complex keyword that calls the following keywords, \`Backup ECU\` and \`Backup ECU download\`.
        Signals the ECU to start ECU backup.
        Once complete, downloads the ECU backup file and stores it into *location*.
         
        Variable
            *location*
                - target output file for the ECU backups
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${back_ecu_input}   SEPARATOR=\\n
            ...     {
            ...         "store-log-files": true,
            ...         "store-event-files": true,
            ...         "store-core-dumps": true
            ...     }

            ${backup_slave_ecu_file_location}   .//artifacts//slave_ecu_backup.zip

            *** Test Cases ***
            Sample
                Backup ecu and download   ${back_ecu_input}   location=${backup_slave_ecu_file_location}
        """
        assert int(timeout), ValueError('Invalid timeout parameter')
        _timeout = int(timeout)

        try:
            self.backup_ecu(json_payload, _timeout, session_index=session_index)
            time.sleep(3)
            self.backup_ecu_download(location, session_index=session_index)
        except AssertionError:
            self.backup_ecu_cancel(session_index=session_index)
            raise AssertionError('Unable to backup ECU and download configuration')

    def restore_ecu_status(self, complete='', session_index=''):
        """ Restore ECU Status
        
        Queries the ECU of the restore ECU progress.
        It is possible to assert a complete status of this keyword if *complete* variable is set to true.
        
        Variable
            *complete*
                - optional variable to dictate a complete check on \`Restore ECU\` status
            *session_index*
                - optional input, will use the most recently returned session id if not specified.
                - User should be able to know when to pass in session index is allowed.
        
        .. code:: robotframework
            
            *** Test Cases ***
            Sample 
                Restore ECU status   complete=True
                
        For more information, visit `/restore-ecu`_.

        .. _/restore-ecu: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/restore-ecu        
        """
        status = self._assert_json_response_stop_on_error(self._get('restore-ecu', session_index=session_index), 'done')

        _complete = complete.lower()

        if _complete == 'true' and not status:
            raise AssertionError("Bring into site is not finished!")

        return status

    def restore_ecu(self, master_ip, ecu_backup, site_index='', offset='', session_index='', timeout=45):
        """ Restore ECU

        Restores ECU from a local backup file.

        Variable
            *master_ip*
                - master ecu ip
                - when restore master ecu backup to a blank ecu, use the the new ecu ip as master_ip
            *ecu_backup*
                - location of the ecu backup file to restore
                - if the master ecu ip changed after backup slave ecu (which was part of site)
                - the master ECU will be continuously telling every ECU who the master is
                - it is expected that there might be a short window of time where the master ip on a slave ecu is wrong.
            *site_index*
                - reference to the site id index generated by reading the ECU databases
            *offset*
                - ECU offset
            *session_index*
                - optional input, will use the most recently returned session id if not specified.
                - User should be able to know when to pass in session index is allowed.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                # when ECU is out of site and has no db before restore ecu
                Restore ECU   ${master_ECU_IP}   ecu_backup=file
                # when ECU is out of site and has db before restore ecu
                login   username   password
                Restore ECU   ${master_ECU_IP}   ecu_backup=file
                # when ECU is in site before restore site
                login   username   password
                Get Database Information
                ${ecu_offset}=   get ecu offset
                Restore ECU   ${master_ECU_IP}   SITE0   ${ecu_offset}    ecu_backup=file

        For more information, visit `/restore-ecu`_.

        .. _/restore-ecu: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/restore-ecu
        """
        assert int(timeout), ValueError('Invalid timeout input.')
        _timeout = int(timeout)
        assert os.path.exists(ecu_backup), ImportError('Unable to find file {0}'.format(ecu_backup))
        if site_index:
            assert site_index in siteinfo.site_ids, AssertionError('Invalid site {0}'
                                                                   'Please select from the following sites {1}'
                                                                   .format(site_index, siteinfo.site_ids.keys()))
        if offset:
            assert int(offset), AssertionError('Invalid offset parameter')

        if site_index is '' and offset is '':
            with open(ecu_backup, 'rb') as backup:
                self._assert_json_response_stop_on_error(self._post('restore-ecu/{0}'.format(master_ip), backup, session_index=session_index))
                logger.info(self.last_url)
        else:
            _offset = int(offset)
            with open(ecu_backup, 'rb') as backup:
                self._assert_json_response_stop_on_error(self._post('restore-ecu/{0}/{1}/{2}'
                                                                    .format(siteinfo.site_ids[site_index],
                                                                            _offset, master_ip), session_index=session_index), backup)
                logger.info(self.last_url)

        logger.info('Sleep 120 seconds while restoring', also_console=True)
        time.sleep(120)
        logger.info('Wait while ecu rebooting during restore call', also_console=True)
        for i in range(0, timeout):
            try:
                self._get_about()
                logger.info('Rebooting finished.')
                return  # once you hit the return statement, you return from the function/method (either with or without a return value).
            except AssertionError:
                logger.info('Still rebooting..')
                # time.sleep(1) # python internal http request time out 15s to 20s
        raise AssertionError('Restore and reboot took too long, ECU is still not responding')


    def factory_default_ecu(self, timeout=240, session_index=''):
        """ Factory Reset ECU Back to Default

        The ECU will automatically reboot and restore the default factory state.

        Variable
            *timeout*
                - dictates how long to wait, in seconds, before failing the keyword.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${user}   sysadmin
            ${pass}   newpassword
            ${default_ip}   172.24.172.200

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}
                Factory default ecu   timeout=360
                establish ssh connection   ${default_ip}   # please run this test on you own network
                change encelium ip   ${IP}   255.255.252.0   10.215.20.1

        For more information, visit `/factory-reset`_.

        .. _/factory-reset: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/factory-reset

        """
        assert int(timeout), ValueError('Invalid timeout input.')
        self._assert_json_response_stop_on_error(self._post('factory-reset', session_index=session_index))
        self._assert_json_response_stop_on_error(self._get('factory-reset', session_index=session_index))
        _timeout = int(timeout)
        time.sleep(_timeout)

        # During factory-reset post api, the ECU will reboot, once it reboot, get factory-reset status will not work
        # because we lost the session, and also after the ECU reboot, the IP will revert back to default IP 172.24.172.200
        # _timeout = int(timeout)
        # for i in range(0, _timeout):
        #     _val = self._assert_json_response_stop_on_error(self._get('factory-reset'), 'done')
        #     logger.info('RETURN VAL {0}'.format(_val))
        #     #the return will always have 'in-process': True, 'done': False before ECU reboot
        #     if _val:
        #         break
        #     time.sleep(1.0)
        #
        # assert _val, AssertionError('Get factory-reset \'done\' status did NOT return True.')

    def reboot_ecu(self, retry=15, session_index=''):
        """ Reboot ECU

        Reboot ECU and waits until web services is functional again.

        Variable
            *retry*
                - dictates may times to try re-establishing connection before failing the keyword.
                - each retry counts for 15 to 20s seconds
                - calls a \`Get Version\` keyword to validate the state of the web services
             *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Reboot ecu

        For more information, visit `/reboot`_.
        
        .. _/reboot: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/reboot        
        
        """

        assert int(retry), ValueError('Invalid timeout input')
        _retry = int(retry)

        # Reboot(This will automatically abort all ongoing sessions.)
        logger.info('Attempting to reboot the ECU', also_console=True)
        self._assert_json_response_stop_on_error(self._post('reboot', session_index=session_index))

        logger.info('Sleep 45 seconds before system boots up', also_console=True)
        time.sleep(45)

        # Try to GET about. If the ECU is still rebooting, we will expect to catch exception.
        # Sleep 5 sec to try next login
        # When no exception is found, it means the ECU is back up again

        for i in range(0, _retry):
            try:
                self._get_about()
                logger.info('Rebooting finished.')
                return  # once you hit the return statement, you return from the function/method (either with or without a return value).
            except AssertionError:
                logger.info('Still rebooting..')
                # time.sleep(1) # python internal http request time out 15s to 20s

        raise ConnectionError('Unable to validate ECU reboot status')

    def unmap_ecu(self, timeout=60, session_index=''):
        """ Unmap previous mapped nodes and reboot the ECU but keep the ECU in the site.

        The ECU will automatically reboot after unmap previously mapped nodes from the ECU.

        Variable
            *timeout*
                - dictates how long to wait, in seconds, before failing the keyword.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${user}   sysadmin
            ${pass}   newpassword

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}
                ${original_ecu_offset} = get ecu offset
                unmap ecu   timeout=60
                ${current_ecu_offset} = get ecu offset
                should be equal   ${original_ecu_offset}   ${current_ecu_offset}

        For more information, visit `/unmap-ecu`_.

        .. _/unmap-ecu: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/unmap-ecu

        """
        assert int(timeout), ValueError('Invalid timeout input.')
        self._assert_json_response_stop_on_error(self._post('unmap-ecu', session_index=session_index))
        self._assert_json_response_stop_on_error(self._get('unmap-ecu', session_index=session_index))
        _timeout = int(timeout)
        time.sleep(_timeout)

        # During unmap-ecu post api, the ECU will reboot, once it reboot, get unmap-ecu status will not work because we lost the session
        # _timeout = int(timeout)
        # for i in range(0, _timeout):
        #     _val = self._assert_json_response_stop_on_error(self._get('unmap-ecu'), 'done')
        #     logger.info('RETURN VAL {0}'.format(_val))
        #     #the return will always have 'in-process': True, 'done': False before ECU reboot
        #     if _val:
        #         break
        #     time.sleep(1.0)
        #
        # assert _val, AssertionError('Get unmap-ecu \'done\' status did NOT return True.')

