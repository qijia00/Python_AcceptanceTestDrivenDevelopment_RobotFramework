import ast
from time import sleep

from robot.api import logger
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface
from PolarisLibrary.base import ui_reference as ui_ref


class SystemInformationKeywords(PolarisInterface):
    def __init__(self):
        super(SystemInformationKeywords, self).__init__()

    @keyword
    def change_system_name(self, name, complete=True):
        """ Change System Name
        Change system name in the system information page
        
        - name:  name of the system to change to
        - complete:  finish action and close page
        """

        self.open_system_info_page()

        # Set system name
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system name']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system name']['id']).send_keys(name)

        if isinstance(complete, str):
            complete = PolarisInterface.str2bool(complete)

        if complete:
            # Close UI to complete name change
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['wizard ok']['id']))

            # Accept the warning dialog
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['yes button']['id']))

    @keyword
    def change_system_gps(self, longitude, latitude, complete=True):
        """ Change System GPS
        Change system GPS location
        
        - longitude:  GPS longitude
        - latitude:  GPS latitude
        - complete:  finish action and close page
        """

        self.open_system_info_page()

        # Set system longitude
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system longitude']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system longitude']['id']).send_keys(longitude)

        # Set system latitutde
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system latitude']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system latitude']['id']).send_keys(latitude)

        if isinstance(complete, str):
            complete = PolarisInterface.str2bool(complete)

        if complete:
            # Close UI to complete name change
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['wizard ok']['id']))

    @keyword
    def change_system_address(self, address, complete=True):
        """ Change System Address
        
        - address:  System address
        - complete:  finish action and close page
        """

        self.open_system_info_page()

        # Set system address
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system address']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system address']['id']).send_keys(address)

        if isinstance(complete, str):
            complete = PolarisInterface.str2bool(complete)

        if complete:
            # Close UI to complete name change
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['wizard ok']['id']))

    @keyword
    def change_customer_name(self, customer, complete=True):
        """ Change System Customer Name
        
        - customer:  system customer name
        - complete:  finish action and close page
        """

        self.open_system_info_page()

        # Set customer information
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system contact']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system contact']['id']).send_keys(customer)

        if isinstance(complete, str):
            complete = PolarisInterface.str2bool(complete)

        if complete:
            # Close UI to complete name change
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['wizard ok']['id']))

    @keyword
    def change_additional_information(self, info, complete=True):
        """ Change System Additional Information
        
        - info:  additional system information
        - complete:  finish action and close page
        """

        self.open_system_info_page()

        # Set customer information
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system additional info']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['system additional info']['id']).send_keys(info)

        if isinstance(complete, str):
            complete = PolarisInterface.str2bool(complete)

        if complete:
            # Close UI to complete name change
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['wizard ok']['id']))

    @keyword
    def change_system_information(self, name='', longitude='', latitude='', address='', customer='', info=''):
        """ Change System Information
        
        All arguments are optional and will only be changed if they are provided
        
        - name:  name of the system to change to
        - longitude:  GPS longitude
        - latitude:  GPS latitude
        - address:  System address
        - customer:  system customer name
        - info:  additional system information
        """

        if name:
            self.change_system_name(name, complete=False)

        if longitude or latitude:
            self.change_system_gps(longitude, latitude, complete=False)

        if address:
            self.change_system_address(address, complete=False)

        if customer:
            self.change_customer_name(customer, complete=False)

        if info:
            self.change_additional_information(info, complete=False)

        # Close UI to complete name change
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['wizard ok']['id']))

        if name:
            # Accept the warning dialog
            PolarisInterface.webdriver.click(
                PolarisInterface.webdriver.find_element_by_accessibility_id(
                    ui_ref.mapping['yes button']['id']))

    def open_system_info_page(self):
        PolarisInterface.webdriver.implicitly_wait(0)
        try:
            PolarisInterface.webdriver.find_element_by_class_name('EditSystemInformationView')
        except errorhandler.NoSuchElementException:
            PolarisInterface.navi.go_to('system information')
        finally:
            PolarisInterface.webdriver.implicitly_wait(PolarisInterface.wait)
