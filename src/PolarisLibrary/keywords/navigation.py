import ast
import time
import winrm
import shutil
from time import sleep
from robot.api import logger
from os.path import expanduser


from PolarisLibrary.base import keyword
from selenium.webdriver.remote import errorhandler
from PolarisLibrary.base import ui_reference as ui_ref
from PolarisLibrary.base import PolarisInterface, WiniumInterface


class NavigationKeywords(PolarisInterface):
    def __init__(self):
        super(NavigationKeywords, self).__init__()
        PolarisInterface.navi = self

    @keyword
    def go_to(self, location):
        """ Navigate to various UI locations in Polaris 4

        Navigates to any mapped UI location in Polaris 4.

        Examples:
            - go to   User Management
            - go to   Main
        """

        assert location.lower() in ui_ref.mapping.keys(), \
            AssertionError("Unable to find {0}.  Please select from the following UI mappings {1}"
                           .format(location, [item.title() for item in ui_ref.mapping.keys()]))

        for item in ui_ref.mapping[location.lower()]['navi']:
            if item == ui_ref.mapping['burger menu']['id']:
                logger.info('Trying to find if the menu is hidden', also_console=PolarisInterface.output_console)

                _boundingbox = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['inner menu']['id']).get_attribute('ClickablePoint')

                logger.info('Polaris box {0}'.format(PolarisInterface.boundingbox), also_console=PolarisInterface.output_console)
                logger.info('Burger box {0}'.format(_boundingbox), also_console=PolarisInterface.output_console)

                if int(PolarisInterface.boundingbox[0]) < int(_boundingbox.split(',')[0]) and \
                   int(_boundingbox.split(',')[0]) > 0:
                    logger.info('Burger menu open!', also_console=PolarisInterface.output_console)
                    continue

            PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(item))
            sleep(1)

    @keyword
    def synchronize(self):
        """ Synchronize Polaris

        Synchronizes Polaris configuration with the ECU

        Examples:
            - synchronize
        """

        logger.warn('synchronize keyword is deprecated, Polaris button to sync has disappeared')
        self.go_to('sync')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ok button']['id']))

        sleep(15)

    @keyword
    def close_dialog(self):
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['close button']['id']))

    @keyword
    def verify_popup_message(self, keywords_list='', color=''):
        """ Verify if the text_phrase in the pop-up actually contains the list of keywords specified

         Variable:
             - Pop-up error message when you try to import an offline site with the same name during Manage offline sites
             - The keywords list  will be separated by commas
             - If the  pop-up Dialog is NOT found first,it will flag an error
             - If the Text phrase does not contain the list of keywords flag an error
              First convert the actual phrase , convert it into lowercase ,remove the special characters and then split by space

        Examples:
            - verify_popup_message   keywords_list=successful
         """

        PolarisInterface.webdriver.waitfor(ui_ref.mapping['popup message']['id'], 30)
        item_popup = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['popup message']['id'])

        if keywords_list:
            assert len(keywords_list) > 0, AssertionError('Please enter at least one keyword')
            assert item_popup.is_enabled(), \
                AssertionError('Pop-up Notice Not found')

            text_phrase_list = item_popup.get_attribute('Name').lower().split(" ")
            substring_list = keywords_list.lower().split(",")

            for x in range(0, len(text_phrase_list)):
                text_phrase_list[x] = ''.join(e for e in text_phrase_list[x] if e.isalnum())

            for item in substring_list:
                assert item in text_phrase_list, AssertionError("Unable to find keyword '{0}'".format(item))

        elif color:
            detect_color = PolarisInterface.visual.extract_dominant_color(
                PolarisInterface.webdriver.find_element_by_name('PolarisWindowMessage'))

            if color.lower() != detect_color:
                raise AssertionError('Invalid popup message response! {0}'.format(detect_color))

        try:
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['popup message']['id'])

            button = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['yes button']['id'])
            if button.is_displayed():
                PolarisInterface.webdriver.click(button)
            else:
                button = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ok button']['id'])
                PolarisInterface.webdriver.click(button)

            if not button:
                raise AssertionError('OK or Yes button on the popup window is NOT detected.')

        except (errorhandler.NoSuchElementException, errorhandler.WebDriverException):
            logger.info('No popup window detected.', also_console=PolarisInterface.output_console)

        logger.info('Wait 3 sec for Polaris to processing after dismiss the pop up window.',
                    also_console=PolarisInterface.output_console)
        time.sleep(3)

    @keyword
    def remove_isolated_storage(self, hostname='', auth=()):
        """ Remove the IsolatedStorage folder

        Examples:
            - Remove Isolated Storage
        """

        if auth:
            if isinstance(auth, (str, unicode)):
                try:
                    PolarisInterface.remote_username, PolarisInterface.remote_password = ast.literal_eval(auth)
                except ValueError:
                    raise ValueError("Unable to parse auth {0}\n"
                                     "Please provide auth in format ('user', 'password')")
            else:
                PolarisInterface.remote_username, PolarisInterface.remote_password = auth

        if hostname:
            PolarisInterface.hostname = hostname

        isolated_storage = '\AppData\Local\IsolatedStorage'

        if 'localhost' in PolarisInterface.hostname or '127.0.0.1' in PolarisInterface.hostname:
            home = expanduser("~")
            try:
                shutil.rmtree("{0}{1}".format(home, isolated_storage))
            except WindowsError as e:
                logger.info('No IsolatedStorage found', also_console=PolarisInterface.output_console)
                logger.info(e, also_console=PolarisInterface.output_console)

        elif PolarisInterface.remote_username or PolarisInterface.remote_password:
            assert PolarisInterface.remote_username, AssertionError('Please provide remote authentication username')
            assert PolarisInterface.remote_password, AssertionError('Please provide remote authentication password')

            ps_script = """
            $users = get-childitem C:/Users
            foreach ($user in $users) {{
                $folder = "C:/Users/" + $user + "{0}"
                try {{
                   Remove-Item $folder -recurse -force -erroraction ignore
                }}
                catch {{}}
            }}
            """.format(isolated_storage)

            remote_session = winrm.Session(hostname, auth=(PolarisInterface.remote_username,
                                                           PolarisInterface.remote_password))
            response = remote_session.run_ps(ps_script)

    @keyword
    def maximize_application(self):
        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            try:
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['max button']['id']))
                time.sleep(1)
                logger.info('Maximize the screen.', also_console=PolarisInterface.output_console)
                self.update_polaris_location()
            except errorhandler.NoSuchElementException:
                logger.info('Unable to maximize the application', also_console=PolarisInterface.output_console)
        else:
            PolarisInterface.webdriver.maximize_window()
            self.update_polaris_location()

    def ok_to_synchronize(self):
        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ok button']['id']))
            time.sleep(1)
            logger.info('OK the unsynchronized changes confirmation dialog.',
                        also_console=PolarisInterface.output_console)
        except errorhandler.NoSuchElementException:
            pass

    def open_site_management_window(self):
        logger.warn('site management is not available in Polaris anymore')
        try:
            # 'offline sites' is the box that contains all the offline sites in the site management window
            # the automation id stays the same as 'offline sites' no matter you open site management window from offline or online
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline sites']['id'])
            logger.info('Site Management dialog is already opened.', also_console=PolarisInterface.output_console)
        except errorhandler.NoSuchElementException:
            logger.info('Open Site Management dialog.', also_console=PolarisInterface.output_console)
            PolarisInterface.navi.go_to('site management')







