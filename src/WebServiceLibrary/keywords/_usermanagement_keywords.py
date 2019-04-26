import os
import time
import json
from robot.api import logger
from _WebServiceCore import _WebServiceCore


class _UserManagement_Keywords(_WebServiceCore):
    user_ids = dict()
    user_names = dict()
    user_groups = dict()

    def get_user_info(self, session_index=''):
        """ Get User Inforamtion
        
        Requests the user information of the current user.

        Variable
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

        For more information, visit `/user-info`_.
        
        .. _/user-info: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user-info     
        """
        logger.info(self.base_url)
        api_call = self._get('user-info', session_index=session_index)
        userinfo = self._assert_json_response_stop_on_error(api_call, True)
        logger.info(userinfo, also_console=True)

        for item in ('user-rights',
                     'user-name',
                     'root-zones',
                     'cannot-change-pwd',
                     'user-group-name',
                     'full-name',
                     'must-change-pwd',
                     'user-id',
                     'user-group'):
            assert item in userinfo.keys(), AssertionError('Unable to find {0}'.format(item))

    # api/user is no longer in use by Polaris, but still can be called by ECU.
    # we need to keep this api so we still get user_ids(), user_names(), user_groups()
    def get_user_list(self):
        """ Get User List

        Requests the current user list of the site.

        For more information, visit `/user`_.

        .. _/user: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user
        """
        api_call = self._get('user')
        userlist_dict = self._assert_json_response_stop_on_error(api_call, True)

        # for item in ('users',):
        #     assert item in userlist_dict.keys(), AssertionError('Unable to find {0}'.format(item))
        assert 'users' in userlist_dict.keys(), AssertionError('Unable to find users.')

        user_id_list = list()
        user_name_list = list()
        user_group_list = list()
        userlist_list = userlist_dict['users']
        for list_item in userlist_list:
            logger.info('list_item is {0}'.format(list_item))
            for key in ('user-id',
                        'user-name',
                        'user-group',
                        'user-group-name'):
                assert key in list_item.keys(), AssertionError('Unable to find {0}'.format(key))
            user_id_list.append(list_item['user-id'])
            user_name_list.append(list_item['user-name'])
            user_group_list.append(list_item['user-group'])

        for user_id in user_id_list:
            if user_id not in _UserManagement_Keywords.user_ids.values():
                _UserManagement_Keywords.user_ids['USER{0}'.format(len(_UserManagement_Keywords.user_ids))] = user_id
        logger.info(_UserManagement_Keywords.user_ids)

        for user_name in user_name_list:
            if user_name not in _UserManagement_Keywords.user_names.values():
                _UserManagement_Keywords.user_names['USER{0}'.format(len(_UserManagement_Keywords.user_names))] = user_name
        logger.info(_UserManagement_Keywords.user_names)

        _UserManagement_Keywords.user_groups.clear()
        for user_group in user_group_list:
            _UserManagement_Keywords.user_groups['USER{0}'.format(len(_UserManagement_Keywords.user_groups))] = user_group
        logger.info(_UserManagement_Keywords.user_groups)

    # api/user is no longer in use by Polaris, but still can be called by ECU.
    def add_user(self, json_payload, session_index=''):
        """ Add User to Site
        
        Adds user to site.
        Must be logged in as administrator to create users.
        
        Variable
            *json_payload*
                - string that contains json configuration for the new user
                
        .. code:: robotframework
        
            *** Variables ***
            ${user}   SEPARATOR=\\n
            ...   {
            ...       "user-id": "",
            ...       "user-name": "Brand New User",
            ...       "user-group": 3,
            ...       "password-plaintext" : "Lumenade-1234!"
            ...   }
            
            *** Test Cases ***
            Sample
                Add user   ${user}
                
        For more information, visit `/user`_.
        
        .. _/user: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user     
        """

        logger.warn("Add user call is out of date!  "
                    "Webservice calls have been removed to be replaced by direct database management")

        try:
            # logger.info(json_payload)
            user_info = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        for key in ('user-id',
                    'user-name',
                    'user-group',
                    'password-plaintext'):
            assert key in user_info.keys(), AssertionError('Invalid user parameters')

        if session_index == '':
            api_call = self._post('user', json_payload)
        else:
            api_call = self._post('user', json_payload, session_index=session_index)

        response_dict = self._assert_json_response_stop_on_error(api_call, True)
        assert 'user-id' in response_dict.keys(), AssertionError("can not find user-id.")

        response_id = self._assert_json_response_stop_on_error(api_call, 'user-id')
        return response_id

    # api/user is no longer in use by Polaris, but still can be called by ECU.
    def modify_user(self, user_index, json_payload):
        """ Modify Site Users

        Modifies a user within a site
        Must be logged in as administrator to modify user.

        Variable
            *json_payload*
                - string that contains json configuration for the modified user

        .. code:: robotframework

            *** Variables ***
            ${user}   SEPARATOR=\\n
            ...   {
            ...       "user-id": "",
            ...       "user-group": 2",
            ...       "password-plaintext" : "Lumenade-5678!"
            ...   }

            *** Test Cases ***
            Sample
                Modify user   USER0   ${user}

        For more information, visit `/user`_.

        .. _/user: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user     
        """

        logger.warn("Modify user call is out of date!  "
                    "Webservice calls have been removed to be replaced by direct database management")

        assert user_index in _UserManagement_Keywords.user_ids.keys(),\
            AssertionError('Invalid user {}, please selection from the following users {1}'
                           .format(user_index, _UserManagement_Keywords.user_ids.keys()))
        try:
            user_info = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        assert 'user-id' in user_info, AssertionError("Invalid user parameters")

        user_info['user-id'] = _UserManagement_Keywords.user_ids[user_index]

        response = self._assert_json_response_stop_on_error(self._post('user', json.dumps(user_info)), True)

        assert 'user-id' in response.keys(), AssertionError('Unable to find user-id.')

        logger.info(response)

    # api/user is no longer in use by Polaris, but still can be called by ECU.
    def delete_user(self, user_index):
        """ Delete Site Users

        Delete a user within a site
        Must be logged in as administrator to delete user.

        Variable
            *json_payload*
                - string that contains json configuration for the user to delete

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Delete user   USER0

        For more information, visit `/user`_.

        .. _/user: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user     
        """

        logger.warn("Delete user call is out of date!  "
                    "Webservice calls have been removed to be replaced by direct database management")

        assert user_index in _UserManagement_Keywords.user_ids.keys(), \
            AssertionError('Invalid user {}, please selection from the following users {1}'
                           .format(user_index, _UserManagement_Keywords.user_ids.keys()))

        user_info = {"user-id": "{0}".format(_UserManagement_Keywords.user_ids[user_index])}
        logger.info(user_info)

        assert 'user-id' in user_info.keys(), AssertionError("Invalid user parameters")

        self._assert_json_response_stop_on_error(self._delete('user', json.dumps(user_info)))

    def change_user_password(self, user_index, json_payload, session_index=''):
        """ Change User Password

        Change user password
        Must be logged in as administrator to change user passwords.

        Variable
            *json_payload*
                - string that contains json configuration for the user to delete
            *session_index*
                - optional input, will use the most recently returned session id if not specified.

        .. code:: robotframework

            *** Variables ***
            ${user}   SEPARATOR=\\n
            ...   {
            ...       "user-id": "",
            ...       "password-plaintext": "MyChangedPassword"
            ...   }

            *** Test Cases ***
            Sample
                Login   ${user}   ${pass}
                Get user list   #USER0, USER1... returned
                Change user password   USER0   ${user}

        For more information, visit `/user-change-password`_.

        .. _/user-change-password: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/user-change-password     
        """
        assert user_index in _UserManagement_Keywords.user_ids.keys(), \
            AssertionError('Invalid user {}, please select from the following users: {1}'
                           .format(user_index, _UserManagement_Keywords.user_ids.keys()))
        try:
            user_info = json.loads(json_payload)
        except ValueError:
            raise ValueError('Invalid json payload!')

        assert 'user-id' in user_info.keys(), AssertionError("Invalid user parameters")

        user_info['user-id'] = _UserManagement_Keywords.user_ids[user_index]

        self._assert_json_response_stop_on_error(self._post('user-change-password', json.dumps(user_info), session_index=session_index), True)

    def post_recovery_key(self, user_name, recovery_key):
        """ User login without password but recovery key

        recovery key times out in 48 hours.

        Variable
            *user_name*
                - string that contains user name
            *recovery-key*
                - string that contains recovery key

        .. code:: robotframework

            *** Variables ***
            ${user_name}   sysadmin
            ${recovery_key}   Fsre0h17jICcbaPzGmBmy0m2WR0CEn8RvRIzLy4O3lNJhI2DHI0WKmSFpIVx2hCRCenakyemA2fh
           60tsrECLp+wxgnp8x6S7u3CfeEwD+jTrsjIW6o4JldwejomcwtP9FQCAFVuFr9sE+Swez14Qx8K0
           VT4Dx2U0lkUOkUe5oKj5tYcO1nArqKkooJEmk0r0cLCqX54Z/piJoUWBP0j4UR/m9VxDl0NXhbwl
           zShVG701vPGmXqd84fh6qqbgfd1Y9JakrLOjEmyvglhNjpfUUn17QXKVt4ZxEKn4t05FLzL1ZGYC
           C1/mefNgTyyfrEwXux4qPgI5wgByk1PbTpBKWA==

            *** Test Cases ***
            Sample
                clean sessions
                Post Recovery Key   ${user_name}   ${recovery_key}

        For more information, visit `/user-recovery-key`_.

        .. _/user-recovery-key: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/user-recovery-key
        """
        input = dict()
        input['username'] = user_name
        input['recovery-key'] = recovery_key

        output = self._assert_json_response_stop_on_error(self._post('user-recovery-key', json.dumps(input)), True)

        # added the returned session-id for future use
        try:
            assert 'session-id' in output.keys(), KeyError('Unable to find session-id in return.')
            session_string = output['session-id'][0:]
            self.query_string = 'session-id=%s' % session_string
            session_index = 'SESSION{0}'.format(len(_WebServiceCore.session_ids))
            if session_string not in _WebServiceCore.session_ids.values():
                _WebServiceCore.session_ids[session_index] = session_string
            logger.info('After enter recovery key, available session ids are: {0}'.format(_WebServiceCore.session_ids))
        except:
            pass

    def get_new_challenge_key(self, user_name):
        """ Get New Chanllenge Key

        Generate and returns a challenge-key for the provided user who forget the password.

        Variable
            *user_name*
                - string that contains user name

        .. code:: robotframework

            *** Variables ***
            ${user_name}   sysadmin

            *** Test Cases ***
            Sample
                clean sessions
                Get New Challenge Key   ${user_name}

        For more information, visit `/user-new-challenge-key`_.

        .. _/user-new-challenge-key: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/user-new-challenge-key
        """
        input = dict()
        input['username'] = user_name
        new_challenge_key = self._assert_json_response_stop_on_error(self._get('user-new-challenge-key', json.dumps(input)), True)
        return new_challenge_key

    def get_challenge_key(self):
        """ Get New Chanllenge Key

        Generate and returns a challenge-key for the provided user who forget the password.

        Variable
            *user_name*
                - string that contains user name

        .. code:: robotframework

            *** Test Cases ***
            Sample
                clean sessions
                Get Challenge Key   ${user_name}

        For more information, visit `/user-challenge-key`_.

        .. _/user-challenge-key: http://wiki:8090/display/ERD/Data+Web+Service+API#DataWebServiceAPI-/api/user-challenge-key
        """
        challenge_key = self._assert_json_response_stop_on_error(
            self._get('user-challenge-key'), True)
        return str(challenge_key['challenge-key'])

    def generate_recovery_key(self, challenge_key, challenge_key_file_path, batch_file_folder_path, recovery_key_file):
        """ Generate recovery key by a tool

        Generate and returns a recovery-key.

        .. code:: robotframework

            *** Variables ***
            ${challenge_key}   jiaqi
            ${challenge_key_file_path}   .//input//tool_to_create_recovery_key//text_id.txt
            ${batch_file_folder_path}   .//input//tool_to_create_recovery_key
            ${recovery_key_file}   text_0d.sig_64

            *** Test Cases ***
            Sample
                ${recovery_key}=   generate recovery key   ${challenge_key}   ${challenge_key_file_path}   ${batch_file_folder_path}   ${recovery_key_file}
        """
        # write challenge key into txt_id_txt
        with open(challenge_key_file_path, 'w') as the_file:
            the_file.write(challenge_key)

        # execute cmd.bat file
        os.chdir(batch_file_folder_path)   # you are inside ".//input//tool_to_create_recovery_key" folder after this point
        os.system("cmd.bat")

        # return the content from text_0d.sig_64, which is the recovery key
        # a = os.path.abspath(recovery_key_file_path)
        # logger.info(a)
        with open(recovery_key_file, 'r') as the_file2:
            recovery_key = the_file2.read()
            # logger.info(repr(recovery_key))
            # remove \n at the end of each line
            recovery_key = recovery_key.replace('\n', '')
            # logger.info(repr(recovery_key))
        # switch back to .//test_cases//webservices directory
        os.chdir("..")
        os.chdir("..")

        return recovery_key