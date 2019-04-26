import os
import ntpath
from time import sleep
from robot.api import logger

from selenium.webdriver.common.keys import Keys
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.base import keyword
from PolarisLibrary.base import ui_reference as ui_ref
from PolarisLibrary.base import PolarisInterface, WiniumInterface, WinAppDriverInterface


class SiteKeywords(PolarisInterface):
    def __init__(self):
        super(SiteKeywords, self).__init__()

    @keyword
    def activate_system(self, ip_addr, password):
        """ Activate a system
        """

        ref_complete_status = 3

        # Open the discovery and activation tool
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['activate system']['id']))

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh sites']['id'], 30)

        try:
            # Find the ECU
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip']['id'].format(ip_addr))

        except errorhandler.NoSuchElementException:
            # Manually add the IP in case it's not detected
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip address']['id']).send_keys(ip_addr)

            # To handle weird non tapping after entering keys
            if isinstance(PolarisInterface.webdriver, WinAppDriverInterface):
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(
                        ui_ref.mapping['site ip address']['id']))

            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['site add manager']['id']))

            PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['site ip']['id'].format(ip_addr), 30)

        PolarisInterface.webdriver.long_click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip']['id'].format(ip_addr)))

        # Identify (wink) the ECU
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['site identify']['id']))

        # Activate the ECU
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['site activate']['id']))

        # Set system password
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['password']['id']).send_keys(password)

        # Verify password
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['password verify']['id']))

        # Initiate activation process
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['wizard next']['id'], 60)
        activate_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id'])

        PolarisInterface.webdriver.click(activate_ui, PolarisInterface.visual.motion_detection)

        # Validate successful activation
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['wizard next']['id'], 60)
        complete_status = PolarisInterface.webdriver.find_elements_by_name('Completed')

        assert len(complete_status) == ref_complete_status, ('Unable to validate ECU {0} activation.'.format(ip_addr))

        # Close activation window
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['wizard ok']['id'], 30)
        
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['connect to a site']['id'], 60)

    @keyword
    def add_ecu_to_system(self, ip_addr):
        """ Adds a slave ECU into the system
        """

        # Opens the manager discovery tool
        PolarisInterface.navi.go_to('manager discovery tool')
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh sites']['id'], 30)

        try:
            # Find the ECU
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip']['id'].format(ip_addr))

        except errorhandler.NoSuchElementException:
            # Manually add the IP in case it's not detected
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip address']['id']).send_keys(ip_addr)

            # To handle weird non tapping after entering keys
            if isinstance(PolarisInterface.webdriver, WinAppDriverInterface):
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(
                        ui_ref.mapping['site ip address']['id']))

            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['site add manager']['id']))

            PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['site ip']['id'].format(ip_addr), 30)

        # Select the ECU
        PolarisInterface.webdriver.long_click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['site ip']['id'].format(ip_addr)))

        # Bring ECU to system
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['bring to system']['id']))

        # Validate successful activation
        PolarisInterface.navi.verify_popup_message(color='green')

        # Close discovery tool window
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['discovery tool close']['id']))

    @keyword
    def backup_system(self, path, timeout=15):
        """ Backup a system

        Backup a system to the specified path.

        Variable
            *path*
                 - location to export the offline site zip

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Backup system   path=.//artifacts
        """

        if 'localhost' in PolarisInterface.hostname or '127.0.0.1' in PolarisInterface.hostname:
            if ntpath.exists('{0}.zip'.format(ntpath.abspath(path))):
                os.remove('{0}.zip'.format(ntpath.abspath(path)))

        # Open System Backup UI
        PolarisInterface.navi.go_to('backup system')

        # Find backup file Name textbox
        backupname_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup file']['id'])

        # Remove the filename from the Path and save it to Backupfilename
        backup_filename = ntpath.splitext(ntpath.basename(path))[0]

        # Append '*' to the Start and end of the path
        path = "*{0}*".format(ntpath.abspath(ntpath.dirname(path)))

        # Send the path
        backupname_input.send_keys(path)

        # Clear the field
        backupname_input.clear()

        # Send the File name
        backupname_input.send_keys(backup_filename)

        # Perform backup
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        if timeout:
            PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['wizard finish']['id'], int(timeout))

        # Finish the process
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard finish']['id']))

    @keyword
    def restore_system(self, path):
        """ Restore a system

        Restore a system from a specified path.

        Variable
            *path*
                 - location to export the offline site zip

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Restore system   path=.//artifacts
        """

        if 'localhost' in PolarisInterface.hostname or '127.0.0.1' in PolarisInterface.hostname:
            if ntpath.exists('{0}.zip'.format(ntpath.abspath(path))):
                os.remove('{0}.zip'.format(ntpath.abspath(path)))

        logger.info('Go to Burger Menu Restore System')
        # Open System Backup UI
        PolarisInterface.navi.go_to('restore system')

        # Click restore file button
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore backup file']['id']))

        # Manage the file dialog UI
        self.file_dialog(ntpath.abspath(path), 'Open')

        # Perform backup
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        # Validate successful backup
        PolarisInterface.navi.verify_popup_message(color='green')

        # Finish the process
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))

    @keyword
    def import_offline_site(self, path):
        """ Import offline site

        Import an offline site to Polaris.  This can be called from the following screen:
        - Login page (Home page)
        Before it was also here, but not anymore
        - Main UI window (after login on line site)
        - Offline site management window.

        Variable
            *path*
                 - location of the offline site zip

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Import offline site   path=.//input//offline_site.zip
        """

        #assert ntpath.exists(ntpath.abspath(path)), IOError('Unable to find input file {0}'.format(ntpath.abspath(path)))

        # This part makes no sense anymore
        # # Identify at which screen this was called (login, main window, site management window)
        # _screen = self.current_location()
        #
        # if _screen in ('main', 'site management'):
        #     self.restore_system(path)
        #
        # else:
        # Make sure Burger Menu is not open
        PolarisInterface.navi.hide_menu_if_visible()

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['open local site']['id']))
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['import local site']['id']))

        self.file_dialog(ntpath.abspath(path), 'Open')
        PolarisInterface.navi.verify_popup_message(color='green')

    @keyword
    def load_offline_site(self, site):
        """ Loads an offline site

        Designed to be called in the login page, it will attempt to load an offline site.

        Variable
            *site*
                 - offline site name

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Load offline site   site=offline_site
        """
        _screen = self.current_location()

        if _screen == 'main':
            # Site Management is not available in Polaris anymore
            # PolarisInterface.navi.go_to('site management')
            raise AssertionError('We are not in login Page, can\'t continue')

        if _screen == 'login':
            # Make sure Burger Menu is not open
            PolarisInterface.navi.hide_menu_if_visible()

            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['open local site']['id']))

        try:
            target = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site))
        except errorhandler.NoSuchElementException:
            try:
                target = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site.upper()))
            except errorhandler.NoSuchElementException:
                raise errorhandler.NoSuchElementException('Unable to find site {0}.'.format(site))

        PolarisInterface.webdriver.double_click(target, PolarisInterface.visual.motion_detection)

        # if LocalDataLoad check box, then click, otherwise then pass
        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ok button']['id']))
        except errorhandler.NoSuchElementException:
            pass

        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['close button']['id']))
        except errorhandler.NoSuchElementException:
            pass

        try:
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['main ui window']['id'])
        except errorhandler.NoSuchElementException:
            raise AssertionError('Unable to login to Polaris!')
        logger.info('Offline site loaded')

    @keyword
    def export_offline_site(self, site, path):
        """ Exports an offline site

        Exports a Polaris offline site to the specified path.

        Variable
            *site*
                 - offline site name
            *path*
                 - location to export the offline site zip

        .. code:: robotframework

            *** Test Cases ***
            Sample
                Export offline site   site=OfflineSite   path=.//artifacts
        """

        logger.warn('export offline site keyword DEPRECATED')
        if ntpath.exists('{0}.zip'.format(ntpath.abspath(path))):
            os.remove('{0}.zip'.format(ntpath.abspath(path)))

        self.manage_offline_site(site, 'export', path)

    @keyword
    def delete_offline_system(self, site):
        """ Delete an offline site

        Deletes a Polaris offline site
        """

        _screen = self.current_location()

        if _screen == 'main':
            PolarisInterface.navi.go_to('site management')

        if _screen == 'login':
            # Make sure Burger Menu is not open
            PolarisInterface.navi.hide_menu_if_visible()

            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['open local site']['id']))

        try:
            target = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site))
        except errorhandler.NoSuchElementException:
            try:
                target = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site.upper()))
            except errorhandler.NoSuchElementException:
                raise errorhandler.NoSuchElementException('Unable to find site {0}.'.format(site))

        PolarisInterface.webdriver.click(target)

        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['delete system']['id']))
        PolarisInterface.navi.verify_popup_message(color='red')

    @keyword
    def config_offline_site(self, site):
        """ Configures an offline site

        Configuring a Polaris offline site allows switching between offline sites.
        """
        logger.warn('config offline site keyword DEPRECATED')
        logger.info('Switching to {0} site'.format(site))
        self.manage_offline_site(site, 'config')

    @keyword
    def take_system_snapshot(self, snapshot, polaris_logs='true', configuration_data='true', ecu_data='true'):
        """ Takes a system snapshot

        Takes a system snapshot.  Currently limited to taking all ECU data, if the option is selected
        """

        logger.warn('take_system_snapshot DEPRECATED')
        if ntpath.exists('{0}.zip'.format(ntpath.abspath(snapshot))):
            os.remove('{0}.zip'.format(ntpath.abspath(snapshot)))
        else:
            _dir = ntpath.dirname(ntpath.abspath(snapshot))
            if not ntpath.exists(_dir):
                os.makedirs(_dir)

        _plogs = polaris_logs.lower()
        _cdata = configuration_data.lower()
        _edata = ecu_data.lower()

        _complete = list()

        PolarisInterface.navi.go_to('take system snapshot')

        if _plogs == 'true' or _cdata == 'true' or _edata == 'true':
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup custom snapshot']['id']))

            if _plogs == 'true':
                _complete.append(_plogs)
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup polaris logs']['id']))

            if _cdata == 'true':
                _complete.append(_cdata)
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup config data']['id']))
            if _edata == 'true':
                _complete.append(_edata)
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup ecu data']['id']))

        else:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup default snapshot']['id']))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup start']['id']))
        self.file_dialog(ntpath.abspath(snapshot), 'Save')

        sleep(60)

        assert len(_complete) <= len(PolarisInterface.webdriver.find_elements_by_name('Complete')), \
            AssertionError('Unable to verify successful system snapshot')

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['backup close']['id']))

    @keyword
    def restore_system_snapshot(self, snapshot, ip):
        """ Restores a system snapshot on target ECU

        Loads a system snapshot and restores it on a specific ECU.
        Currently limited to restoring 1 ECU in snapshot.
        """

        #assert ntpath.exists(snapshot), IOError('Unable to find input file {0}'.format(snapshot))

        logger.warn('restore_system_snapshot DEPRECATED')
        PolarisInterface.navi.go_to('restore system snapshot')

        # Stage 1, file selection
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore backup file']['id']))
        self.file_dialog(ntpath.abspath(snapshot), 'Open')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        # Stage 2, backup source option
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore backup source']['id']))
        # Click to expose the detected ecu list
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore target ecu']['id']))

        # Find the target ECU IP and click it
        for ui in PolarisInterface.webdriver.find_elements_by_class_name('TextBlock'):
            if ip in ui.get_attribute('Name'):
                PolarisInterface.webdriver.click(ui)
                break

        sleep(10)
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        # Stage 3, ecu restore selection
        #PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore ecu checkbox']['id'].format(ip)))
        #PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard next']['id']))

        sleep(120)
        logger.info(ui_ref.mapping['restore ecu status']['id'].format(ip))
        status = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['restore ecu status']['id'].format(ip)).get_attribute('Name')

        logger.info('Restore status:  {0}'.format(status))
        assert status == 'Success', AssertionError("Backup on ECU {0} {1}!".format(ip, status))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))
        sleep(30)

    def current_location(self):
        # Identify at which screen this was called (login, main window, site management window)
        try:
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['open local site']['id'])
            _screen = 'login'
        except errorhandler.NoSuchElementException:
            # site management window doesn't exist anymore in Polaris
            # try:
            #     PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['restore backup file']['id'])
            #     _screen = 'site management'
            # except errorhandler.NoSuchElementException:
            _screen = 'main'

        return _screen

    def file_dialog(self, path, action):
        PolarisInterface.webdriver.find_element_by_class_name('Edit').send_keys('{0}\n'.format(ntpath.abspath(path)))

        for ui in PolarisInterface.webdriver.find_elements_by_class_name('Button'):
            if ui.get_attribute('Name') == str(action).lower().title():
                PolarisInterface.webdriver.click(ui)

                if action.lower() is not 'Open':
                    try:
                        for replace_ui in PolarisInterface.webdriver.find_elements_by_name('Yes'):
                            if replace_ui.get_attribute('ClassName') == 'Button':
                                PolarisInterface.webdriver.click(replace_ui)
                                break
                    except:
                        pass

                break

    def manage_offline_site(self, site, action_type, path=''):
        """ Manage offline sites

        Configure, Export, or Delete a Polaris offline site.

        Variable
            *site*
                - offline site name
            *action_type*
                - choose from 'config', 'export', 'delete'
            *path*
                - location to export the offline site zip (including the file name)
        """
        logger.warn('manage_offline_site DEPRECATED')
        assert action_type in ('config', 'export', 'delete'), AssertionError("Invalid option {0}".format(action_type))
        assert path is not '' if action_type == 'export' else True, AssertionError("Please provide path including file name if you want to export.")

        PolarisInterface.navi.open_site_management_window()

        logger.info('Select the offline site {0}.'.format(site))

        # This step was incorporated to handle site name changes from CamelCase to upper case
        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site)))
        except errorhandler.NoSuchElementException:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline site']['id'].format(site.upper())))

        logger.info('Click the {0} button for offline site {1}.'.format(action_type, site))
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['offline {0}'.format(action_type)]['id'].format(site)))

        if action_type == 'export':
            PolarisInterface.navi.ok_to_synchronize()
            logger.info('Offline site {0} is exported to {1}.'.format(site, ntpath.abspath(path)))

            self.file_dialog(ntpath.abspath(path), 'Save')

            PolarisInterface.navi.verify_popup_message(color='green')
        elif action_type == 'config':
            PolarisInterface.navi.ok_to_synchronize()
            try:
                PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['local site load']['id'])) # if IsolatedStorage is not cleared
            except errorhandler.NoSuchElementException:
                pass
        else:
            PolarisInterface.navi.verify_popup_message(color='red')
            sleep(10)

        # windows that pop up after take action_type on the site needs to be handled within this function
        # otherwise can not close site management dialog unless make it a separate function in navigation.py
        logger.info('Close Site Management dialog')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['wizard ok']['id']))
