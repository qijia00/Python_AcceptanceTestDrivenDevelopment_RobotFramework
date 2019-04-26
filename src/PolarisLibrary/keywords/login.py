import json
from time import sleep
from datetime import datetime

from robot.api import logger
from selenium import webdriver
from robot.libraries.BuiltIn import BuiltIn
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.utils.types import is_falsy
from PolarisLibrary.base import ui_reference as ui_ref
from PolarisLibrary.base import keyword

from PolarisLibrary.base import PolarisInterface


class LoginKeywords(PolarisInterface):

    def __init__(self):
        super(LoginKeywords, self).__init__()

    @keyword
    def login(self, username, password, ip_addr='', force_local=False):
        """ Log into Polaris

                Logs into Polaris using the specified username and password.
                If ip_addr is specified, IP address will be modified prior to logging.

                Variables
                    *username*
                        - Username to login with
                    *password*
                        - Password to login with
                    *ip_addr*
                        - Optional parameter to specify an IP address for login
                    *force_local*
                        - Optional parameter to specify load from local, if prompted

                """
        assert isinstance(PolarisInterface.webdriver, webdriver.Remote), AssertionError('Please connect to Polaris prior')

        # Make sure Burger Menu is not open
        PolarisInterface.navi.hide_menu_if_visible()

        # Go to Login Page
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['connect to a site']['id']))

        if ip_addr:
            logger.info('Configuring ECU IP address')
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['rescan ecu']['id']))
            PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['rescan ecu']['id'], 15)
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ip address']['id']).send_keys(ip_addr)

        logger.info('Setting username to {0}'.format(username))
        user_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['username']['id'])
        user_input.send_keys(username)

        logger.info('Setting password to {0}'.format(password))
        pass_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['password']['id'])
        pass_input.send_keys(password)

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['login']['id']))

        PolarisInterface.webdriver.waitfor(ui_ref.mapping['main ui window']['id'], 60)
        logger.info('Site loaded')

    @keyword
    def login_offline(self):
        """ Login to Polaris in Offline Mode

        Polaris requires a process that specifically targets offline login.
        This keyword will login with a blank username and password.
        """
        logger.warn('login_offline is deprecated and not supported in Polaris anymore')
        self.login(username='', password='')

    @keyword
    def logout(self):
        PolarisInterface.navi.go_to('logout')
        PolarisInterface.webdriver.waitfor(ui_ref.mapping['connect to a site']['id'], 30)

    @keyword
    def create_new_site(self, sitename='', password='', customer='', project='', author='', json_payload=''):
        """ Create a new site on a factory default ECU=

        Creates a New site with the specified parameters

        Variables
            *Sitename*
                - Name of the site
            *password*
                - Password for sysadmin to login with
            *Customer*
                - Optional parameter to specify the customer Name for the site
            *Project*
                - Optional parameter to specify the Project Name
            *Author*
                - Optional parameter to specify the Author Name

        Validation should be "New site successfully created.Logging out and You should be in the Login screen
        """
        assert isinstance(PolarisInterface.webdriver, webdriver.Remote), AssertionError('Please connect to Polaris prior')

        if json_payload:
            try:
                site_info = json.loads(json_payload)
                logger.info(site_info)
            except ValueError:
                raise ValueError('Invalid json payload!')

            for item in ('name',
                         'password'):
                assert item in site_info, AssertionError('Unable to find {0}'.format(item))

            _name = site_info['name']
            _password = site_info['password']

            _customer = site_info['customer'] if site_info['customer'] else None
            _project = site_info['project'] if site_info['project'] else None
            _author = site_info['author'] if site_info['author'] else None

        else:
            assert sitename, AssertionError('Please specify a site name')
            assert password, AssertionError('Please specify a site password')

            _name = sitename
            _password = password

            _customer = customer if customer else None
            _project = project if project else None
            _author = author if author else None

        # Make sure Burger Menu is not open
        PolarisInterface.navi.hide_menu_if_visible()

        try:
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['create new site']['id']))
            logger.info('Create new site from Home page')
        except errorhandler.NoSuchElementException:
            raise AssertionError('We are not on Home Page, can\'t continue')

        logger.info('Setting site name to {0}'.format(_name))
        sitename_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['new site name']['id'])
        sitename_input.clear()
        sitename_input.send_keys(_name)

        logger.info('Setting sysadmin password to {0}'.format(_password))
        pass_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['new site password']['id'])
        pass_input.clear()
        pass_input.send_keys(_password)

        if customer:
            logger.info('Setting Customer name')
            cust_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['new site customer']['id'])
            cust_input.clear()
            cust_input.send_keys(_customer)

        if project or author:
            logger.info('Providing Additional Information')
            add_info = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['new site author']['id'])
            add_info.clear()
            add_info.send_keys('Project: {0}\nAuthor: {1}'.format(_project, _author))

        logger.info('Click the [Create] button')
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['new site create']['id']))

        PolarisInterface.webdriver.waitfor(ui_ref.mapping['main ui window']['id'], 60)
        logger.info('Offline site created and loaded')
