import time
from robot.api import logger
from _WebServiceCore import _WebServiceCore


class _General_Keywords(_WebServiceCore):
    def get_version(self):
        """ Get Web Services Version
         
        Queries the ECU for the web services version
        
        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                clean sessions
                get version
            
        For more information, visit `/version`_.
        
        .. _/version: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/version        
        """
        self._assert_json_response_stop_on_error(self._get('version'))

    def login(self, username, password):
        """ Login to the ECU

        Login with username and password.
        
        Variables
            *username*
                - ECU username
            *password*
                - ECU password

        .. code:: robotframework

            *** Variable ***
            ${IP}   172.24.172.111

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}   # SESSION0 is returned

        For more information, visit `/login`_.
        
        .. _/login: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/login        
        """
        start = time.time()
        try:
            self._assert_json_response_stop_on_error(self._login(username, password))
            end = time.time()
            logger.info('Login time took {0} seconds.'.format(end - start), also_console=True)
        except AssertionError as error:
            end = time.time()
            logger.info('Invalid login took {0} seconds.'.format(end - start), also_console=True)
            raise AssertionError(error)

        return end - start

    def logout(self, session_index=''):
        """ Logout from the ECU

        Logout

        Variable
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}   # SESSION0 is returned
                Logout
                Login   ${user}   ${pass}   # SESSION1 is returned
                Logout   SESSION1

        For more information, visit `/version`_.

        .. _/version: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/version
        """
        self._assert_json_response_stop_on_error(self._post('logout', session_index=session_index))
        self.query_string = {}
        logger.info('Current stored session ids are: {0}'.format(_WebServiceCore.session_ids))

    def clean_sessions(self):
        """ Clean up session ids

        Clean up session_ids dictionary & query_string
        Call this function at the beginning of session id related tests
        """
        _WebServiceCore.session_ids = dict()
        self.query_string = 'session-id=%s'