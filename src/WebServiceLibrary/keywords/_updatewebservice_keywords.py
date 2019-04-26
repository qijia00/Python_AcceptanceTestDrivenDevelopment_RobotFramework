import os
import time
from robot.api import logger
from _WebServiceCore import _WebServiceCore
from _general_keywords import _General_Keywords as generalinfo

class _Updatewebservice_Keywords(_WebServiceCore):
    def upgrade_login(self, username, password):
        """ Logs in user and return Session ID

        Login request is being forwarded to the DataWebService.

        For more information, visit `/update/login`_.

        .. _/update/login: http://wiki:8090/display/ERD/Update+Web+Service+API#UpdateWebServiceAPI-/api/update/login
        """
        if 'update' not in self.base_url:
            self.base_url = self.base_url + '/update'

        self._assert_json_response_stop_on_error(self._login(username, password))

    def upgrade_logout(self, session_index=''):
        """ Logs out the current user

        Logout request is being forwarded to the DataWebService.

        For more information, visit `/update/logout`_.

        .. _/update/logout: http://wiki:8090/display/ERD/Update+Web+Service+API#UpdateWebServiceAPI-/api/update/logout
        """
        if 'update' not in self.base_url:
            self.base_url = self.base_url + '/update'

        self._assert_json_response_stop_on_error(self._post('logout', session_index=session_index))

    def upgrade_status(self, complete='', session_index=''):
        """ Get upgrade status

        Get status of upload and execute an upgrade package.

        Variable
            *complete*
                - optional variable to dictate a complete check on the \`update\` keyword
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        For more information, visit `/update/update`_.

        .. _/update/update: http://wiki:8090/display/ERD/Update+Web+Service+API#UpdateWebServiceAPI-/api/update/update
        """
        if 'update' not in self.base_url:
            self.base_url = self.base_url + '/update'

        logger.info('Requesting upgrade status')
        status = self._assert_json_response_stop_on_error(self._get('update', 'done', session_index=session_index),
                                                          True)
        _complete = complete.lower()

        if _complete == 'true' and not status:
            raise AssertionError("upgrade is not finished!")

        self.base_url = self.base_url.replace('/update', '')

        return status

    def upgrade(self, location, timeout=300, session_index=''):
        """ Upload and execute an upgrade package

        Upload and execute an upgrade package.

        Variable
            *location*
                - location of the upgrade zip to be uploaded
            *timeout*
                - optional parameter to set the wait time to get the create site status.
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Connect to web services   ${IP}
                upgrade   .//input//LUMENADE_WM_ECU_UPDATE_ZIP_5.zip
                clean sessions
                Connect to web services   ${IP}   ${user}   ${pass}   ${version}
                upgrade   .//input//LUMENADE_WM_ECU_UPDATE_ZIP_5.zip   session_index=SESSION0

        For more information, visit `/update/update`_.

        .. _/update/update: http://wiki:8090/display/ERD/Update+Web+Service+API#UpdateWebServiceAPI-/api/update/update
        """
        if 'update' not in self.base_url:
            self.base_url = self.base_url + '/update'

        assert int(timeout), ValueError('Invalid timeout parameter')

        assert os.path.exists(location), IOError('Unable to file input file {0}'.format(location))

        # Upgrade
        with open(location, 'rb') as upgradezip:
            self._assert_json_response_stop_on_error(self._post('update', upgradezip, session_index=session_index))

        logger.info('upgrade will cause reboot of the ECU, sleep for {} seconds.'.format(timeout))
        time.sleep(timeout)

        # During upgrade post api, the ECU will reboot, once it reboot, get factory-reset status will not work
        # Since we lost the session, and also after the ECU reboot, the IP will revert back to default IP 172.24.172.200
        # Keep getting upgrade status until it is done
        # _timeout = int(timeout)
        #
        # for i in range(0, _timeout):
        #     try:
        #         self.upgrade_status('True', session_index=session_index)
        #         logger.info('Upgrade complete.')
        #         return
        #     except AssertionError:
        #         time.sleep(1.0)
        #
        # raise AssertionError('Unable to confirm completion of upgrade.')

        self.base_url = self.base_url.replace('/update', '')

    def ecu_version(self, username='', password='', session_index=''):
        """ Get ECU Version

        Queries the ECU for ECU versions

        Variable
            *username*
                - optional parameter to login into the ECU, only required if the ECU is part of a site.
            *password*
                - optional parameter to login into the ECU, only required if the ECU is part of a site.
            *session_index*
                - required input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${user}   sysadmin
            ${pass}   newpassword

            *** Test Cases ***
            Sample
                Connect to web services   ${IP}
                #for blank ECU
                ecu version
                #for ECU in site
                ecu version   ${user}   ${pass}

        For more information, visit `/update/version`_.

        .. _/update/version: http://wiki:8090/display/ERD/Update+Web+Service+API#UpdateWebServiceAPI-/api/update/version
        """
        if 'update' not in self.base_url:
            self.base_url = self.base_url + '/update'

        generalinfo.clean_sessions
        if username != '' and password is not '':
            self._assert_json_response_stop_on_error(self._login(username, password))

        self._assert_json_response_stop_on_error(self._get('version', session_index=session_index))

        if username != '' and password is not '':
            self.upgrade_logout(session_index=session_index)

        self.base_url = self.base_url.replace('/update', '')