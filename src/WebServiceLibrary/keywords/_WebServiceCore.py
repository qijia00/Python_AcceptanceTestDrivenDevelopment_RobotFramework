import string
import ctypes
import json
from time import time
import requests
import ntpath
from path import path
from robot.api import logger
import websocket
import ssl

def encode_ascii(data):
    '''encode to ascii instead of unicode'''
    if isinstance(data, list):
        rv = []
        for item in data:
            if isinstance(item, unicode):
                item = item.encode('ascii')
            elif isinstance(item, (list, dict)):
                item = encode_ascii(item)
            rv.append(item)
        return rv
    elif isinstance(data, dict):
        rv = {}
        for key, value in data.iteritems():
            if isinstance(key, unicode):
                key = key.encode('ascii')
            if isinstance(value, unicode):
                value = value.encode('ascii')
            elif isinstance(value, (list, dict)):
                value = encode_ascii(value)
            rv[key] = value
        return rv
    else:
        raise Exception('unknown data type for json: %s' % type(data))


class DllSession(object):
    c_ubyte_p = ctypes.POINTER(ctypes.c_ubyte)

    def __init__(self, dll, data_path):
        self.data_path = data_path

        self.dll = ctypes.cdll.LoadLibrary(dll)
        self.dll._OPEN.restype = DllSession.c_ubyte_p
        self.dll._CLOSE.restype = DllSession.c_ubyte_p
        self.dll._GET.restype = DllSession.c_ubyte_p
        self.dll._POST.restype = DllSession.c_ubyte_p
        self.dll._DELETE.restype = DllSession.c_ubyte_p

        try:
            response = self.open(data_path)
            assert response.data['status-code'] == 200, "DLL already opened.  Closing and reopening DLL..."
        except AssertionError as e:
            logger.info(e)
            self.close()
            self.open(data_path)

    def open(self, data_path):
        return self.Response(self.dll._OPEN(r'{0}'.format(data_path)))

    def close(self):
        return self.Response(self.dll._CLOSE())

    def post(self, url, data=None):
        return self.Response(self.dll._POST(url, str(data), len(str(data))))

    def get(self, url, data=None):
        return self.Response(self.dll._GET(url))

    def delete(self, url, data=None):
        return self.Response(self.dll._DELETE(url))

    class Response(object):
        '''parsed HTTP response object'''

        def __init__(self, p_response):
            '''process the response string into parts'''

            # convert the byte pointer into a string to grab the header first
            response = ctypes.string_at(p_response)
            header, body = response.split('\r\n\r\n', 1)
            header_len = len(header) + len('\r\n\r\n')

            self.text = body
            self.content = bytes(body)

            # parse the header into a dict
            self.headers = dict([map(string.strip, line.split(':', 1)) for line in header.split('\r\n')])

            # process different types of content differently
            if 'json' in self.headers['Content-type']:
                self.data = json.loads(body, object_hook=encode_ascii)

            elif 'octet-stream' in self.headers['Content-type']:
                # binary requires content length to deal with null chars
                body_len = int(self.headers['Content-length'])
                self.data = ctypes.string_at(p_response, header_len + body_len)[header_len:]

            else:
                self.data = body

            logger.info(body)

        def __str__(self):
            return self.headers, self.data

        def json(self):
            return self.data


class _WebServiceCore(object):
    session_ids = dict()

    def __init__(self):

        self.query_string = 'session-id=%s'
        self.session = requests.Session()
        self.session.headers['content-type'] = 'application/json; charset=utf8'
        # ---------------------------------------------------------------------------------------------------------------
        # WARNING: this completely disables certificate verification and associated warnings
        self.session.verify = False
        requests.packages.urllib3.disable_warnings()
        # ---------------------------------------------------------------------------------------------------------------
        self.number = 1
        self.oddRow = True
        self.base_url = ''

        self.success_code = 200

        self.ip_address = ''

        self.offline = False

    def _close_dll(self):
        if isinstance(self.session, DllSession):
            self.session.close()
            self.offline = False

    def _offline_mode(self, dll, data_path):
        if dll and data_path:
            if not self.offline:
                self.session = DllSession(str(ntpath.abspath(dll)), str(ntpath.abspath(data_path)))
                self.offline = True

            self.base_url = self.base_url[self.base_url.find('/api'):]

        else:
            self.offline = False
            self._make_new_session()

        return self.session

    def _make_new_session(self):
        self.session = requests.Session()
        self.session.headers['content-type'] = 'application/json; charset=utf8'
        # ---------------------------------------------------------------------------------------------------------------
        # WARNING: this completely disables certificate verification and associated warnings
        self.session.verify = False

    def _get_about(self):
        self._assert_json_response_stop_on_error(self._get('about'))

    def connect_to_websocket(self, ip_address, session_index=''):
        """ Create websocket connection

        Create websocket connection between ip_address and your laptop.
        We can not create websocket connections between master ecu and slave ecu here, it needs to be done by Polaris.

        Variable
            *ip_address*
                - ip_address of the ECU
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variable ***
            ${IP}   172.24.172.111

            *** Test Cases ***
            Sample
                Connect to websocket   ${IP}
                #session not working for websocket yet
                #Login   ${user}   ${pass}   # SESSION0 is returned
                #Connect to websocket   ${IP}   SESSION0
        """
        ws = websocket.WebSocket(sslopt={'cert_reqs': ssl.CERT_NONE, 'ssl_version': ssl.PROTOCOL_TLSv1_2})

        try:
            #officially, we should use: wss://172.24.172.111:443/wss
            #but these will also work: wss://172.24.172.111:4532/wss ws://172.24.172.111:4532/wss
            if session_index == '':
                # assert len(self.query_string) > len('session-id=%s'), AssertionError('query_string is empty.')
                ws.connect('wss://{0}:443/wss'.format(ip_address))
                # If you specify a cookie with a session-id inside, it will validate against that session.
                # before Authentication is developed, no cookie is accepted.
                # s.connect('wss://{0}:443/wss'.format(ip_address), header={'Cookie': self.query_string})
            else:
                # session not working for websocket yet, but test won't fall into the else branch
                ws.connect('wss://{0}:443/wss'.format(ip_address), header={'Cookie': 'session-id={0}'.format(self.session_ids[session_index])})

        except Exception, e:
            raise AssertionError(e)

    def close_websocket(self):
        """ Close websocket connection

        You can make as many connections as you want to websockets. If you want to disconnect, use this keyword

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Close websocket
        """
        ws = websocket.WebSocket(sslopt={'cert_reqs': ssl.CERT_NONE, 'ssl_version': ssl.PROTOCOL_TLSv1_2})
        ws.close()

    def _login(self, username, password, session_index=''):
        url = self.base_url + '/login'
        if session_index != '':
            url += ('&' if '?' in url else '?') + 'session-id={0}'.format(_WebServiceCore.session_ids[session_index])
        logger.info(url)
        a = time()
        data_in = json.dumps({'username' : username, 'password' : password})
        logger.info('login username and password are {0}'.format(data_in))
        response = self.session.post(url, data=data_in)
        logger.info('response is {0}'.format(response.content))
        b = time()
        try:
            self.session.data = response.json()
        except:
            self.session.data = {}

        try:
            assert 'session-id' in self.session.data.keys(), KeyError('Unable to find session-id')
            session_string = self.session.data['session-id'][0:]
            self.query_string = 'session-id=%s' % session_string
            session_index = 'SESSION{0}'.format(len(_WebServiceCore.session_ids))
            if session_string not in _WebServiceCore.session_ids.values():
                _WebServiceCore.session_ids[session_index] = session_string
            logger.info('After login, available session ids are: {0}'.format(_WebServiceCore.session_ids))
        except:
            pass

        self.last_url = url
        return (response, b - a)

    def _get(self, what, data='', session_index=''):
        url = self.base_url + '/%s' % what
        if session_index == '':
            if len(self.query_string) > len('session-id=%s'):
                url += ('&' if '?' in url else '?') + self.query_string
        else:
            url += ('&' if '?' in url else '?') + 'session-id={0}'.format(_WebServiceCore.session_ids[session_index])
        logger.info("GET: " + url)
        a = time()
        try:
            response = self.session.get(url, data=data)
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout), err:
            raise AssertionError(err)
        logger.info('GET response is {0}'.format(response.content))
        b = time()
        self.last_url = url
        return (response, b - a)

    def _post(self, what, data='', session_index=''):
        url = self.base_url + '/%s' % what
        if session_index == '':
            if len(self.query_string) > len('session-id=%s'):
                url += ('&' if '?' in url else '?') + self.query_string
        else:
            url += ('&' if '?' in url else '?') + 'session-id={0}'.format(_WebServiceCore.session_ids[session_index])
        logger.info("POST: " + url)
        a = time()
        # what to do about the file?
        if path('input_%02d.bin' % self.number).exists():
            with open('input_%02d.bin' % self.number, 'rb') as f:
                response = self.session.post(url, f)
        elif path('input_%02d.txt' % self.number).exists():
            response = self.session.post(url, data=path('input_%02d.txt' % self.number).text(encoding='utf-8').encode(
                'utf8'))
        else:
            response = self.session.post(url, data=data)
        b = time()
        self.last_url = url
        return (response, b - a)

    def _delete(self, what, data='', session_index=''):
        url = self.base_url + '/%s' % what
        if session_index == '':
            if len(self.query_string) > len('session-id=%s'):
                url += ('&' if '?' in url else '?') + self.query_string
        else:
            url += ('&' if '?' in url else '?') + 'session-id={0}'.format(_WebServiceCore.session_ids[session_index])
        logger.info("DELETE: " + url)
        a = time()
        response = self.session.delete(url, data=data)
        b = time()
        self.last_url = url
        return (response, b - a)

    # methods to handle API response
    def _convert_api_response_from_json_string_to_json_object(self, api_call):
        _content = json.loads(api_call[0].content) #the api_call output is a string, we use json.loads to convert it to dictionary or list.
        assert len(_content) > 0, AssertionError('ECU data response in empty!')

        return _content

    def _response_nth_element_key(self, api_call, nth_element):
        return self._convert_api_response_from_json_string_to_json_object(api_call).keys()[nth_element - 1]

    def _response_nth_element_value(self, api_call, nth_element):
        return self._convert_api_response_from_json_string_to_json_object(api_call).values()[nth_element - 1]

    # methods to handle response and report error
    def _stop_on_error(self, error_message):
        raise AssertionError(error_message)

    def _assert_json_response_stop_on_error(self, api_call, return_value_keyword=False):
        # potential return value if not overwritten later on in this function
        _retval = self._convert_api_response_from_json_string_to_json_object(api_call)

        # if error status in response, first element is "status-string", and second element is "status-code"
        response_1st_element_key = self._response_nth_element_key(api_call, 1)
        response_1st_element_value = self._response_nth_element_value(api_call, 1)

        if 'status-string' in response_1st_element_key:
            response_2nd_element_key = self._response_nth_element_key(api_call, 2)
            response_2nd_element_value = self._response_nth_element_value(api_call, 2)

            if 'status-code' in response_2nd_element_key and response_2nd_element_value != self.success_code:
                self._stop_on_error('FAILED: {}!'.format(response_1st_element_value))
            else:
                logger.info(
                'PASSED. Return value is {}.'.format(_retval), also_console=True)
        else:
            logger.info(
            'PASSED. Return value is {}.'.format(_retval), also_console=True)

            if return_value_keyword:
                logger.info('printing type of {0} and its value:'.format(return_value_keyword))
                logger.info('{0} \n {1}'.format(type(return_value_keyword), return_value_keyword))
                _retval = self._convert_api_response_from_json_string_to_json_object(api_call)[return_value_keyword] if \
                    isinstance(return_value_keyword, str) else \
                    self._convert_api_response_from_json_string_to_json_object(api_call)

        logger.info('return type is: {0}'.format(type(_retval)))
        #logger.info('return value is: {0}'.format(_retval))
        return _retval

    # When return is non-json: such as binary, list, sqlite format, etc.
    def _assert_non_json_response_stop_on_error(self, api_call, return_value_keyword=False):
        response = api_call[0].content
        logger.info('printing type of response and its value:')
        logger.info('{0} \n {1}'.format(type(response), response))

        # Response is json with "status-string" & "status-code" if failed
        if 'status-string' in response:
            response_1st_element_value = self._response_nth_element_value(api_call, 1)
            self._stop_on_error('FAILED: {}!'.format(response_1st_element_value))
        # Response is non-json
        else:
            # Response is empty so it failed too
            if not response:
                logger.info ('FAILED: empty return!')
                logger.info ('')
            # Response is non-empty and non-json if succeed
            else:
                logger.info ('PASSED: with non-empty non-json return.')
                logger.info ('')

        return response if return_value_keyword else None

    # Check if certain word is in response
    def _assert_word_in_response(self, word, api_call):
        if word in api_call[0].content:
            logger.info ('PASSED: "{}" is in return as expected.'.format(word))
            logger.info ('')
        else:
            self._stop_on_error('FAILED: "{}" is NOT in return!'.format(word))

    def _assert_word_not_in_response(self, word, api_call):
        if word not in api_call[0].content:
            logger.info ('PASSED: "{}" is NOT in return as expected.'.format(word))
            logger.info ('')
        else:
            self._stop_on_error('FAILED: "{}" is in return!'.format(word))

    # Check response count is as expected
    def _assert_response_count(self, expected_count, actual_count):
        if len(actual_count) == expected_count:
            logger.info ('PASSED: return count matches.')
            logger.info ('')
        else:
            self._stop_on_error('FAILED: return count does NOT match!')
