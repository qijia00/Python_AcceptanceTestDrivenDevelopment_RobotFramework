from time import sleep
from robot.api import logger

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface, WiniumInterface, WinAppDriverInterface
from PolarisLibrary.base import ui_reference as ui_ref


class MappingKeywords(PolarisInterface):
    def __init__(self):
        super(MappingKeywords, self).__init__()

    @keyword
    def find_devices(self):
        """ Finds devices on the network 

        Scans the network for Encelium devices.
        """

        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id'])
        PolarisInterface.webdriver.click(menu)

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['refresh list']['id'])
        if ui.is_enabled():
            PolarisInterface.webdriver.click(ui)

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh list']['id'], 30)

    @keyword
    def map_ecu(self, ip_addr, area):
        """ Maps an ECU to an unmapped manager area

        Maps an ECU with the correct IP address to an manager area
        """

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['mapping menu']['id'], 30)
        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id'])
        PolarisInterface.webdriver.click(menu)

        ecu_list = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['map ecu list']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ecu = ecu_list.find_element_by_id(ui_ref.mapping['map ecu']['id'].format(ip_addr))
        else:
            ecu = ecu_list.find_element('accessibility id', ui_ref.mapping['map ecu']['id'].format(ip_addr))

        manager_area = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control area']['id'].format(area))
        PolarisInterface.webdriver.drag_and_drop(ecu, manager_area, analysis=PolarisInterface.visual.motion_detection)

    @keyword
    def identify_ecu(self, ip_addr):
        """ Identifies the ECU
        
        Ecu identification can be either via WINKING for wireless managers or otherwise for Dali
        """

        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id'])
        PolarisInterface.webdriver.click(menu)

        ecu_list = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['map ecu list']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ecu = ecu_list.find_element_by_id(ui_ref.mapping['map ecu']['id'].format(ip_addr))
        else:
            ecu = ecu_list.find_element('accessibility id', ui_ref.mapping['map ecu']['id'].format(ip_addr))

        PolarisInterface.webdriver.click(ecu)
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['map identify node']['id']))

        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['map identify node']['id'], 30)

    @keyword
    def unmap_ecu(self, ip_addr):
        """ Unmaps an ECU from a manager area
        """

        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id'])
        PolarisInterface.webdriver.click(menu)

        ecu_list = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['map ecu list']['id'])

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            ecu = ecu_list.find_element_by_id(ui_ref.mapping['map ecu']['id'].format(ip_addr))
        else:
            ecu = ecu_list.find_element('accessibility id', ui_ref.mapping['map ecu']['id'].format(ip_addr))

        PolarisInterface.webdriver.click(ecu)
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['map unmap']['id']))

    @keyword
    def map_node(self, node_id, zone, profile=None):
        """ Maps a device node onto a zone
            
            - Node ID only supports the full long id (18 chars long)
            - Zone corresponds to the name of the zone to map the node
            - If profile is provided, the corresponding profile will be opened
        """

        # Open the profile configuration
        if profile:
            target_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['control profile']['id'].format(profile))
            PolarisInterface.webdriver.click(target_ui)
            PolarisInterface.webdriver.double_click(target_ui, PolarisInterface.visual.motion_detection)

        # Open the mapping tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id']))

        # Open the mapping tool
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping tool']['id']))

        # Refresh node list
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['refresh list']['id']))

        # Wait for device list
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh list']['id'], 15)

        target_node = None
        for i in range(0, 5):
            try:
                # Try to find it through the mapping tool list
                target_node = PolarisInterface.webdriver.scroll_to_element(
                    ui_ref.mapping['mapping node']['id'].format(node_id),
                    ui_ref.mapping['mapping node list']['id'],
                    ui_ref.mapping['mapping node template']['id'],
                    PolarisInterface.visual.motion_detection)

            except:
                # Try to find it in the wireless manager list
                logger.info('Unable to find node in Mapping Tool.  Switching to Zigbee Network')

                # Go to Zigbee Network UI
                PolarisInterface.webdriver.click(
                    PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping network tool']['id']))

                # Try to find it through the mapping tool list
                try:
                    target_node = PolarisInterface.webdriver.scroll_to_element(
                        ui_ref.mapping['mapping node']['id'].format(node_id),
                        ui_ref.mapping['mapping node list']['id'],
                        ui_ref.mapping['mapping node template']['id'],
                        PolarisInterface.visual.motion_detection)
                except:
                    pass

            try:
                assert target_node
                break
            except AssertionError:
                logger.info('{0} attempt unsuccessful'.format(i + 1))
                continue

        # Find the target zone
        target_zone = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['profile zone']['id'].format(zone))

        # Map node to zone
        PolarisInterface.webdriver.drag_and_drop(target_node, target_zone,
                                                 analysis=PolarisInterface.visual.motion_detection)

    @keyword
    def unmap_node(self, node_id, profile=None):
        """ Unmaps a node from the system
        
            - Node ID only supports the full long id (18 chars long)
            - If profile is provided, the corresponding profile will be opened
        """

        # Open the profile configuration
        if profile:
            target_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['control profile']['id'].format(profile))
            PolarisInterface.webdriver.click(target_ui)
            PolarisInterface.webdriver.double_click(target_ui, PolarisInterface.visual.motion_detection)

        # Open the mapping tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id']))

        # Open the network tool
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping network tool']['id']))

        # Wait for device list
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh list']['id'], 15)

        # Find the device node
        target_node = PolarisInterface.webdriver.scroll_to_element(ui_ref.mapping['mapping node']['id'].format(node_id),
                                                                   ui_ref.mapping['mapping node list']['id'],
                                                                   ui_ref.mapping['mapping node template']['id'])
        PolarisInterface.webdriver.click(target_node)

        # Open additional actions
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['mapping additional actions']['id']))

        # Unmap node
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['mapping node unmap']['id']))

    @keyword
    def remove_node_from_network(self, node_id, profile=None):
        """ Removes a node from the network
        
            - Node ID only supports the full long id (18 chars long)
            - If profile is provided, the corresponding profile will be opened
        """

        # Open the profile configuration
        if profile:
            target_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['control profile']['id'].format(profile))
            PolarisInterface.webdriver.click(target_ui)
            PolarisInterface.webdriver.double_click(target_ui, PolarisInterface.visual.motion_detection)

        # Open the mapping tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping menu']['id']))

        # Open the mapping tool
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['mapping network tool']['id']))

        # Wait for device list
        PolarisInterface.webdriver.waitforclickable(ui_ref.mapping['refresh list']['id'], 15)

        # Find the device node
        target_node = PolarisInterface.webdriver.scroll_to_element(ui_ref.mapping['mapping node']['id'].format(node_id),
                                                                   ui_ref.mapping['mapping node list']['id'],
                                                                   ui_ref.mapping['mapping node template']['id'])
        PolarisInterface.webdriver.click(target_node)

        # Open additional actions
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['mapping additional actions']['id']))

        # Unmap node
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['mapping node remove from network']['id']))
