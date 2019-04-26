from robot.api import logger
from _WebServiceCore import _WebServiceCore


class _Quality_Keywords(_WebServiceCore):
    def mock_session_id(self, session_id):
        """ Creates a mock session ID
        
        Creates a mock session ID and stores it as SESSION_MOCK.
        To use this mock session ID, please call all keywords that require a session ID with SESSION_MOCK
        Repeated calls to this keyword overwrites the value of SESSION_MOCK and is
        therefore only capable of storing 1 mock session ID.
        
        .. code:: robotframework

            *** Test Cases ***
            Sample
                Mock session id   some_session_id
                Get user info   session_index=SESSION_MOCK
                Backup ECU   session_index=SESSION_MOCK            
        """
        _WebServiceCore.session_ids['SESSION_MOCK'] = session_id

    def target_api_endpoint(self, endpoint, method='get', payload='', session_index=''):
        """  Target API endpoint
        
        Sends a message to the ECU through an REST endpoint.
        By default, the method is 'get' but also supports 'post' and 'delete'.
        If necessary, a payload can also be added.
        A session ID will be used but can also be overwritten.
        
        .. code:: robotframework

            *** Test Cases ***
            Sample
                Target api endpoint   some endpoint
                Target api endpoint   some endpoint   get   
                Target api endpoint   some endpoint   post   some payload
                Target api endpoint   some endpoint   delete   session_index=SESSION_MOCK
        """

        _method = method.lower()

        if _method == 'get':
            self._assert_json_response_stop_on_error(self._get(endpoint, payload, session_index))

        elif _method == 'post':
            self._assert_json_response_stop_on_error(self._post(endpoint, payload, session_index))

        elif _method == 'delete':
            self._assert_json_response_stop_on_error(self._delete(endpoint, payload, session_index))

        else:
            raise AssertionError("Unsupported REST method")
