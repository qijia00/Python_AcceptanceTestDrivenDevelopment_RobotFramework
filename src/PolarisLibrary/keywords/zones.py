import ast
from time import sleep
from robot.api import logger
from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface, WiniumInterface, WinAppDriverInterface
from PolarisLibrary.base import ui_reference as ui_ref
from selenium.webdriver.remote import errorhandler


class ZoneKeywords(PolarisInterface):
    def __init__(self):
        super(ZoneKeywords, self).__init__()

    @keyword
    def select_zone(self, zone):
        """ Selects a zone
        
        This keyword assumes that the profile has already been opened.  
        This keyword will not open a profile prior to zone selection.
        """

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['profile zone']['id'].format(zone))

        PolarisInterface.webdriver.click(ui)

    @keyword
    def label_zone(self, name, zone=''):
        """ Assign a label to a zone
        
        Variables
            *zone*
                - Reference zone (Z1, Z2, Z3, etc)
            *name*
                - New label fo the specified zone
        """

        if zone:
            self.select_zone(zone)

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['zone name']['id']).send_keys(name)

    @keyword
    def set_zone_occupancy_timeout(self, timeout, zone=''):
        """ Set zone occupancy timeout
        
        Variables
            *zone*
                - Reference zone (Z1, Z2, Z3, etc)
            *timeout*
                - Timeout value for occupancy
        """
        if zone:
            self.select_zone(zone)

        occupancy = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['zone occupancy']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ui = occupancy.find_element_by_id(ui_ref.mapping['zone time']['id'])
        else:
            ui = occupancy.find_element('accessibility id', ui_ref.mapping['zone time']['id'])

        ui.send_keys(timeout)

    @keyword
    def set_zone_comfort_brightness(self, brightness, zone=''):
        """ Set zone comfort brightness
        
        Variables
            *zone*
                - Reference zone (Z1, Z2, Z3, etc)
            *brightness*
                - Comfort brightness setting
        """
        if zone:
            self.select_zone(zone)

        brightness_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['zone comfort brightness']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ui = brightness_ui.find_element_by_id(ui_ref.mapping['zone time']['id'])
        else:
            ui = brightness_ui.find_element('accessibility id', ui_ref.mapping['zone time']['id'])

        ui.send_keys(brightness)

    @keyword
    def set_dimming_sequence_type(self, sequence, zone=''):
        """ Sets dimming sequence type
        """
        self.open_dimming_properties(zone)

        PolarisInterface.webdriver.select_combobox_item(ui_ref.mapping['zone sequence type']['id'], sequence)

        self.close_dimming_properties()

    @keyword
    def set_dimming_off_sequence(self, stage, brightness='', timeout='', zone=''):
        """ Sets dimming off sequence of a zone
        
        Variables
            *stage*
                - Select the stage to configure, Stage 1, Stage 2, Off
            *brightness*
                - Brightness setting
            *timeout*
                - Timeout value, if applicable
            *zone*
                - Target zone to configure
              
        """
        self.open_dimming_properties(zone)

        stage_list = ['Stage 1', 'Stage 2', 'Off State']
        stage = stage.title()
        assert stage in stage_list, AssertionError('Please select from the following {0}'.format(stage_list))

        stage = stage.replace(' ', '')

        if brightness:
            brightness_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['zone dimming brightness template']['id'].format(stage))

            if isinstance(PolarisInterface.webdriver, WiniumInterface):
                ui = brightness_ui.find_element_by_id(ui_ref.mapping['zone slider value']['id'])
            else:
                ui = brightness_ui.find_element('accessibility id', ui_ref.mapping['zone slider value']['id'])

            ui.send_keys(brightness)

        if timeout:
            timeout_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['zone dimming time template']['id'].format(stage))

            if isinstance(PolarisInterface.webdriver, WiniumInterface):
                ui = timeout_ui.find_element_by_id(ui_ref.mapping['zone time']['id'])
            else:
                ui = timeout_ui.find_element('accessibility id', ui_ref.mapping['zone time']['id'])

            ui.send_keys(timeout)

        self.close_dimming_properties()

    @keyword
    def set_dlhv_min_brightness(self, brightness, zone=''):
        """ Sets daylight harvesting mininum brightness
        """
        self.open_dlhv_properties(zone)

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['zone dlhv remainder']['id']))

        brightness_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['zone dlhv min brightness']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ui = brightness_ui.find_element_by_id(ui_ref.mapping['zone time']['id'])
        else:
            ui = brightness_ui.find_element('accessibility id', ui_ref.mapping['zone time']['id'])

        ui.send_keys(brightness)

        self.close_dlhv_properties()

    @keyword
    def open_dlhv_properties(self, zone=''):
        """ Opens DLHV properties of a zone
        """

        if zone:
            self.select_zone(zone)

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['zone daylight harvesting']['id'])

        if not ui.is_selected():
            PolarisInterface.webdriver.click(ui)

    @keyword
    def close_dlhv_properties(self):
        """ Closes DLHV propreties
        """

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['zone daylight harvesting']['id'])

        if ui.is_selected():
            PolarisInterface.webdriver.click(ui)

    @keyword
    def open_dimming_properties(self, zone=''):
        """ Opens dimming properties of a zone
        """

        if zone:
            self.select_zone(zone)

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['zone dimming']['id'])

        if not ui.is_selected():
            # Open Dimming sub tab
            PolarisInterface.webdriver.click(ui)

    @keyword
    def close_dimming_properties(self):
        """ Close dimming properties sub menu
        """

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['zone dimming']['id'])

        if ui.is_selected():
            # Close Dimming sub tab
            PolarisInterface.webdriver.click(ui)
