import ast
import socket
import ntpath
import subprocess
from time import sleep
from urlparse import urlparse

from robot.api import logger
from selenium import webdriver
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface, WinAppDriverInterface, WinAppDriverInterfaceMouse, WiniumInterface
from PolarisLibrary.base import ui_reference as ui_ref


class ConnectionKeywords(PolarisInterface):

    def __init__(self):
        super(ConnectionKeywords, self).__init__()

    @keyword
    def connect_to_polaris(self, url, driver='win7', polaris='', wait=10, auth=()):
        """ 
        """
        _driver = driver.lower()

        PolarisInterface.hostname = urlparse(url).hostname

        if auth:
            if isinstance(auth, (str, unicode)):
                try:
                    PolarisInterface.remote_username, PolarisInterface.remote_password = ast.literal_eval(auth)
                except ValueError:
                    raise ValueError("Unable to parse auth {0}\n"
                                     "Please provide auth in format ('user', 'password')")
            else:
                PolarisInterface.remote_username, PolarisInterface.remote_password = auth

        if polaris:
            PolarisInterface.selenium_capabilities['app'] = polaris
        else:
            PolarisInterface.selenium_capabilities['app'] = PolarisInterface.executable

        if _driver == 'win7':
            _polaris_folder = ntpath.dirname(PolarisInterface.selenium_capabilities['app'])
            _winium_exe = r'{0}webdrivers\Winium.Desktop.Driver.exe'.format(PolarisInterface.root_dir)
            logger.info(_winium_exe, also_console=True)

            if 'localhost' in url or '127.0.0.1' in url:
                try:
                    PolarisInterface.webdriver_exe = subprocess.Popen(args=[_winium_exe, ''], cwd=_polaris_folder)

                except Exception as e:
                    logger.info("Inside exception")
                    logger.info(e, also_console=True)
                    raise EnvironmentError('Unable to launch winium!')

            _webdriver = WiniumInterface

        elif _driver == 'win10':
            _webdriver = WinAppDriverInterface

        elif _driver == 'win10mouse':
            _webdriver = WinAppDriverInterfaceMouse

        else:
            _webdriver = WiniumInterface

        try:
            PolarisInterface.webdriver = _webdriver(url, PolarisInterface.selenium_capabilities)
        except socket.error:
            logger.info("Unable to connect to {0}".format(url))

        PolarisInterface.wait = int(wait)

        PolarisInterface.webdriver.implicitly_wait(PolarisInterface.wait)
        self.polaris_startup()

    @keyword
    def set_implicit_wait(self, wait=''):
        """ Sets implicit wait time for UI elements
        
        If the optional wait variable is not provided, the wait time will be set to the default time
        set upon initial connection.
        """

        try:
            if wait:
                PolarisInterface.webdriver.implicitly_wait(int(wait))
            else:
                PolarisInterface.webdriver.implicitly_wait(PolarisInterface.wait)
        except:
            pass

    @keyword
    def disconnect_from_polaris(self):
        """ Disconnect from Polaris
        """

        if PolarisInterface.webdriver:
            try:
                PolarisInterface.webdriver.close()
            except errorhandler.WebDriverException:
                pass

        if PolarisInterface.webdriver_exe:
            try:
                PolarisInterface.webdriver_exe.kill()
            except:
                pass

        sleep(15)

    @keyword
    def console_output(self, output):
        """ Control logger output to console"""
        try:
            output = ast.literal_eval(str(output).lower().title())
        except ValueError:
            output = False
            raise ValueError('Unable to convert {0}'.format(output))

        PolarisInterface.output_console = output

    @keyword
    def click_ui(self, target):
        """ Find and click a UI element
        
        Finds a ui based on element id (automation id) and clicks it.
        Target input corresponds to internal UI dictionary not the element id.
        For debugging use only.
        """
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping[target]['id']))

    def polaris_startup(self):
        assert isinstance(PolarisInterface.webdriver, webdriver.Remote)
        logger.info("Inside Polaris start-up")

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['max button']['id'], 30)
        self.navi.maximize_application()

        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['eula accept']['id']))
        except errorhandler.NoSuchElementException:
            pass

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['connect to a site']['id'], 30)

    @keyword
    def find_ui_by_name(self, target):
        return PolarisInterface.webdriver.find_element_by_name(target)

    @keyword
    def find_uis_by_name(self, target):
        return PolarisInterface.webdriver.find_elements_by_name(target)

    @keyword
    def find_uis_by_class_name(self, target):
        return PolarisInterface.webdriver.find_elements_by_class_name(target)

    @keyword
    def find_ui_by_id(self, target):
        return PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping[target]['id'])

    @keyword
    def main_polaris(self):
        return PolarisInterface.window_ui

    @keyword
    def get_webdriver(self):
        return PolarisInterface.webdriver
