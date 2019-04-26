import ntpath

from selenium.webdriver.common.keys import Keys
from selenium.webdriver.remote import errorhandler

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface
from PolarisLibrary.base import ui_reference as ui_ref


class StructureKeywords(PolarisInterface):
    def __init__(self):
        super(StructureKeywords, self).__init__()

    @keyword
    def add_floor(self):
        """ Adds a floor

        Adds a blank floor to the database

        """

        _component_tab = ui_ref.mapping['configure components tab']['id']
        _ui_list = ui_ref.mapping['configure components list']['id']
        _ui_item = ui_ref.mapping['configure components item']['id']
        _category = ui_ref.mapping['configure components zones']['id']
        _site = ui_ref.mapping['site explorer select site']['id']

        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_component_tab))
        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_category))

        _devlist = PolarisInterface.webdriver.find_element_by_accessibility_id(_ui_list)

        _target_element = None
        for item in _devlist.find_elements_by_class_name(_ui_item):
            _name = item.get_attribute('Name')

            if 'Floor' in _name:
                _target_element = item
                break

        PolarisInterface.webdriver.drag_and_drop(
            _target_element, PolarisInterface.webdriver.find_element_by_accessibility_id(_site))

    @keyword
    def delete_floor(self, _target_floor=ui_ref.mapping['site explorer floor']['id']):

        _site_tree = ui_ref.mapping['site tree']['id']

        _tree = PolarisInterface.webdriver.find_element_by_accessibility_id(_site_tree)
        _target_ui = None
        for item in _tree.find_elements_by_class_name(ui_ref.mapping['configure components item']['id']):
            if _target_floor in item.get_attribute('Name'):
                _target_ui = item
                break

        if not _target_ui:
            raise AssertionError('Unable to find a floor')

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['edit content']['id']))

        PolarisInterface.webdriver.click(_target_ui)

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['delete item']['id']))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['select content']['id']))

    @keyword
    def rename_floor(self, new_name, target=ui_ref.mapping['site explorer floor']['id']):

        _properties_tab = ui_ref.mapping['configure properties tab']['id']
        _properties_name = ui_ref.mapping['configure properties name']['id']
        _site_tree = ui_ref.mapping['site tree']['id']

        _tree = PolarisInterface.webdriver.find_element_by_accessibility_id(_site_tree)

        PolarisInterface.webdriver.click(_tree.find_element_by_name(target))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(_properties_tab))

        PolarisInterface.webdriver.find_element_by_accessibility_id(_properties_name).send_keys(new_name)

    @keyword
    def import_floorplan(self, path, target=ui_ref.mapping['site explorer floor']['id']):
        """ Import floor plan

        Import a floor plan
        """

        assert ntpath.exists(path), IOError('Unable to find input file {0}'.format(path))

        _properties_tab = ui_ref.mapping['configure properties tab']['id']
        _expander = ui_ref.mapping['configure floor expander']['id']
        _import_floor = ui_ref.mapping['configure floor plan import']['id']

        _site_tree = ui_ref.mapping['site tree']['id']

        _tree = PolarisInterface.webdriver.find_element_by_accessibility_id(_site_tree)

        PolarisInterface.webdriver.click(_tree.find_element_by_name(target))

        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_properties_tab))
        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_expander))

        _import_floor_element = PolarisInterface.webdriver.find_element_by_accessibility_id(_import_floor)

        if not _import_floor_element.is_displayed():
            PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_expander))

        PolarisInterface.webdriver.click(_import_floor_element)

        PolarisInterface.webdriver.find_element_by_name('File name:').send_keys('{0}\n'.format(ntpath.abspath(path)))

        try:
            ui_list = PolarisInterface.webdriver.find_elements_by_id('1')
            for ui in ui_list:
                if ui.get_attribute('Name') in ('Save', 'Open'):
                    PolarisInterface.webdriver.click(click())
                    break

        except errorhandler.NoSuchElementException:
            PolarisInterface.webdriver.send_keys(Keys.ENTER)
            PolarisInterface.webdriver.send_keys(Keys.ENTER)

        PolarisInterface.webdriver.double_click(_tree.find_element_by_name(target))

    @keyword
    def add_ecu(self, ecu_type):
        """ Adds an ECU type to the floor plan

        """
        _ecu_type = str(ecu_type).lower()

        _component_tab = ui_ref.mapping['configure components tab']['id']
        _ui_list = ui_ref.mapping['configure components list']['id']
        _ui_item = ui_ref.mapping['configure components item']['id']
        _category = ui_ref.mapping['configure components other devices']['id']
        _main_ui = ui_ref.mapping['main ui window']['id']

        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_component_tab))
        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_category))

        _devlist = PolarisInterface.webdriver.find_element_by_accessibility_id(_ui_list)

        _target_element = None
        for item in _devlist.find_elements_by_class_name(_ui_item):
            _name = item.get_attribute('Name')

            if _ecu_type in str(_name).lower():
                _target_element = item
                break

        if not _target_element:
            raise AssertionError('Unable to find {0}'.format(ecu_type))

        PolarisInterface.webdriver.drag_and_drop(_target_element, PolarisInterface.webdriver.find_element_by_accessibility_id(_main_ui))

    @keyword
    def delete_ecu(self, ecu_type, _target_floor=ui_ref.mapping['site explorer floor']['id']):
        _ecu_type = str(ecu_type).lower()

        _site_tree = ui_ref.mapping['site tree']['id']
        _tree = PolarisInterface.webdriver.find_element_by_accessibility_id(_site_tree)

        # first pass
        _target_ui = None
        for item in _tree.find_elements_by_class_name(ui_ref.mapping['configure components item']['id']):
            if _ecu_type in str(item.get_attribute('Name')).lower():
                _target_ui = item
                break

        if not _target_ui:
            PolarisInterface.webdriver.double_click(_tree.find_element_by_name(_target_floor))

            # second pass
            _target_ui = None
            for item in _tree.find_elements_by_class_name(ui_ref.mapping['configure components item']['id']):
                if _ecu_type in str(item.get_attribute('Name')).lower():
                    _target_ui = item
                    break

        assert _target_ui, AssertionError('Unable to find {0}'.format(ecu_type))
        PolarisInterface.webdriver.click(_target_ui)

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['edit content']['id']))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['delete item']['id']))
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['ok button']['id']))

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['select content']['id']))

    @keyword
    def add_sensor(self, sensor_type):
        """
        Adds a sensor type to the floor-plan
        """
        _sensor_type = str(sensor_type).lower()

        _component_tab = ui_ref.mapping['configure components tab']['id']
        _ui_list = ui_ref.mapping['configure components list']['id']
        _ui_item = ui_ref.mapping['configure components item']['id']
        _category = ui_ref.mapping['configure components sensors']['id']
        _main_ui = ui_ref.mapping['main ui window']['id']

        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_component_tab))
        PolarisInterface.webdriver.click(PolarisInterface.webdriver.find_element_by_accessibility_id(_category))

        _devlist = PolarisInterface.webdriver.find_element_by_accessibility_id(_ui_list)

        _target_element = None
        for item in _devlist.find_elements_by_class_name(_ui_item):
            _name = item.get_attribute('Name')

            if _sensor_type in str(_name).lower():
                _target_element = item
                break

        if not _target_element:
            raise AssertionError('Unable to find {0}'.format(_sensor_type))

        PolarisInterface.webdriver.drag_and_drop(_target_element, PolarisInterface.webdriver.find_element_by_accessibility_id(_main_ui))
