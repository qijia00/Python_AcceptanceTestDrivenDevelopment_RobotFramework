import ast
from time import sleep

from robot.api import logger
from selenium import webdriver
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface
from PolarisLibrary.base import ui_reference as ui_ref


class UserKeywords(PolarisInterface):
    def __init__(self):
        super(UserKeywords, self).__init__()

        self._editing_rights = False

    @keyword
    def add_user(self, name, username, password, usertype='', email=''):
        """ Creates a User in Polaris 4

        Creates a user in Polaris 4 with the specified username, password and user type.
        This attempts to open up the user management dialog, if not opened already.
        Once the dialog has been opened, it accesses the User Add button and inputs the required elements into the
        user fields.  

        Please not that this keyword does not synchronizes user changes nor does it verify any created users.

        Examples:
            - Polaris Add User   Full Name   User1
            - Polaris Add User   Full Name   User2   Password2   Advanced User   user2@password.com
        """

        try:
            PolarisInterface.navi.go_to('user management')
        except errorhandler.NoSuchElementException:
            raise AssertionError('User Management Menu item could not be found')

        logger.info('Configure new user parameters')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['add user']['id']))

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user fullname']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user fullname']['id']).send_keys(name)

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user username']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user username']['id']).send_keys(username)

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user new password']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user new password']['id']).send_keys(password)
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user confirm password']['id']).send_keys(password)
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))

        if email:
            logger.warn('add_user: user email is currently not implemented in Polaris')
        #     PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user email']['id']).clear()
        #     PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user email']['id']).send_keys(email)
        #
        if usertype:
            logger.warn('add_user: user type is currently not implemented in Polaris')
        #     group = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user group']['id'])
        #     PolarisInterface.webdriver.click(group)
        #
        #     sleep(0.5)
        #     PolarisInterface.webdriver.click(group.find_element_by_name(usertype))
        #
        # PolarisInterface.webdriver.click(
        #     PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))

        logger.info('Checking that the user is in the list now')
        try:
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['edit user']['id'].format(username))
        except errorhandler.NoSuchElementException:
            raise AssertionError('User {0} was not added'.format(username))

        logger.info('Close User Management dialog')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard cancel']['id']))

    @keyword
    def remove_user(self, username):
        """ Removes a user from Polaris 4

        Attempts to remove.  If the user cannot be seen from the user management dialog,
        the logged in user does not have access to the particular user.
        Logging as administrator will prevent any potential user inaccessibility issues.

        Examples:
            - Polaris remove user   User1   UserType    
        """

        try:
            PolarisInterface.navi.go_to('user management')
        except errorhandler.NoSuchElementException:
            raise AssertionError('User Management Menu item could not be found')

        logger.info('Searching for user {0}'.format(username))

        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['remove user']['id'].format(username)))
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['yes button']['id']))
        except errorhandler.NoSuchElementException:
            raise AssertionError('User or its Delete button not found in the list!')

        try:
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['remove user']['id'].format(username))
            raise AssertionError('Unable to delete {0}'.format(username))
        except errorhandler.NoSuchElementException:
            pass

        logger.info('Close User Management dialog')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard cancel']['id']))

    @keyword
    def modify_user_rights(self, user, user_right, enable=True, complete=False):
        """ Enables or disables user rights

        Opens up the user rights dialog and enables and disables specified user rights.
        By default, selected user rights are enabled.  
        Furthermore, the last keyword to issue a user right modification needs to complete the transaction.

        Examples:
            Polaris modify user rights   User1   Structure   False
            Polaris modify user rights   User1   Mapping   True
            Polaris modify user rights   User1   Comfort   True
            Polaris modify user rights   User1   Fire Alarm   True   complete=True
        """

        if enable and isinstance(enable, bool):
            _enable = True
        else:
            _enable = False

        if complete:
            _complete = True
        else:
            _complete = False

        logger.info("Setting {0}'s {1} to {2}".format(user, user_right, _enable))

        if not self._editing_rights:
            PolarisInterface.navi.go_to('user management')
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['edit user']['id'].format(user)))
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['user rights']['id']))
            self._editing_rights = True

        _ui = PolarisInterface.webdriver.scroll_to_element(user_right,
                                                           ui_ref.mapping['user rights list']['id'],
                                                           ui_ref.mapping['user right']['id'])

        ref_clickablepoint = ast.literal_eval(_ui.get_attribute('ClickablePoint'))

        for item in PolarisInterface.webdriver.find_elements_by_id(user_right):
            if ref_clickablepoint[1] * 0.95 < ast.literal_eval(item.get_attribute('ClickablePoint'))[1] < \
                            ref_clickablepoint[1] * 1.05:
                _target = item
                break

        if _enable and not _target.is_selected():
            pass
            PolarisInterface.webdriver.click(_target)

        elif not _enable and _target.is_selected():
            # To handle the checkbox tri-state (enable, read-only, disable)
            PolarisInterface.webdriver.click(_target)
            sleep(0.5)
            PolarisInterface.webdriver.click(_target)

        logger.info('{0} selected {1}, set to {2}'.format(user_right, _target.is_selected(), _enable), also_console=True)

        if _complete:
            PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id('OKButton'))
            PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id('CloseButton'))
            self._editing_rights = False
