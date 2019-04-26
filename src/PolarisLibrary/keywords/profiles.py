import ast
from time import sleep
from robot.api import logger
from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface, WiniumInterface, WinAppDriverInterface
from PolarisLibrary.base import ui_reference as ui_ref
from selenium.webdriver.remote import errorhandler


class ProfileKeywords(PolarisInterface):
    def __init__(self):
        super(ProfileKeywords, self).__init__()
        self.control_areas_ui = dict()
        self.profiles = dict()
        self.profiles_ui = dict()

    @keyword
    def create_control_area(self, name=None):
        """ Create an empty Polaris control area
        """

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['create control area']['id']))

        if name:
            self.name_control_area(name)

        self.update_control_areas()
        logger.info(self.control_areas_ui, also_console=PolarisInterface.output_console)

    @keyword
    def rename_control_area(self, name, target=None):
        """ Rename a manager area
        """

        if not target:
            self.update_control_areas()
            target_ui = self.control_areas_ui.itervalues().next()
        else:
            assert target in self.control_areas_ui, AssertionError('Unable to find {0}.\n'
                                                                   'Please select from the following.\n{1}'
                                                                   .format(target, self.control_areas_ui.keys()))

            target_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control area']['id'].format(target))

        PolarisInterface.webdriver.click(target_ui)
        self.name_control_area(name)
        self.update_control_areas()

    def name_control_area(self, name):
        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['properties menu']['id'])
        PolarisInterface.webdriver.click(menu)

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control property name']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control property name']['id']).send_keys(name)
        PolarisInterface.webdriver.click(menu)

    @keyword
    def search_profile(self, search_text, profile_type=''):
        """
        :param searchText:
        :return:
        Search for a particular profile
        """
        try:
            # Sending the search text to the search bar
            assert (PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['search bar']['id'])), \
                AssertionError('Cannot find the Search bar')
            search_input = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['search bar']['id'])
            search_input.clear()

            if profile_type:
                search_input.send_keys(profile_type)
            else:
                search_input.send_keys(search_text)

            # Finding the ListBox which is the container for the List items
            assert (PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['search results']['id'])), \
                AssertionError('Cannot find the Search results')
            parent = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['search results']['id'])

            # Finding the TextBlock items inside this ListBox
            assert (parent.find_elements_by_class_name('TextBlock')), \
                AssertionError('Cannot find the Textblock items')
            ui_list = parent.find_elements_by_class_name('TextBlock')
            logger.info(len(ui_list), also_console='True')

            # Initializing a search results list to store the search results
            search_results = []
            profile_name = []

            # Iterate through the List of all the Textblocks ,Each search result will have 3 text-block entries
            # Each listbox item will have 3 entries only the first entry is the name ,so just store that
            for i in xrange(0, len(ui_list), 3):
                name = ui_list[i].get_attribute('Name')
                profile_name.append(name)
                search_results.append(ui_list[i])


            # logger.info('The number of Matching listbox lines : {0}'.format(profile_name), also_console='True')
            # logger.info('The length of search results is : {0}'.format(len(search_results)), also_console='True')

            # Click on each highlighted entry,then check if the profile is within the control area
            for i in search_results:
                logger.info('clicking once', also_console='True')
                if search_text == i.get_attribute('Name'):
                    PolarisInterface.webdriver.click(i)
                    break
                profile_auto_id = "autoControlProfile" + search_text

                # After I click,I am going to find the parent control area and search for this profile
                assert (PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control areas']['id'])), \
                    AssertionError('Cannot find the Master control area')
                container = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control areas']['id'])
                bounding_container = PolarisInterface.webdriver.get_boundingrect(container)

                # Find the profile by automationId
                assert (PolarisInterface.webdriver.find_element_by_accessibility_id(profile_auto_id)), \
                    AssertionError('Cannot find the Profile')
                profile_element = PolarisInterface.webdriver.find_element_by_accessibility_id(profile_auto_id)
                bounding_profile = PolarisInterface.webdriver.get_boundingrect(profile_element)

                # To validate if the Profile rectangle is within All control area rectangle
                # check Left  X co-ordinate first,Left of Profile should be greater than Left of control area
                assert int(bounding_container[0]) < \
                       int(bounding_profile[0]) < \
                       int(bounding_container[0]) + int(bounding_container[2]), \
                    AssertionError('X coordinate of Profile not within control area')

                # Check Top Y co-ordinate ,Top of Profile should be greater than top of control area
                assert int(bounding_container[1]) < \
                       int(bounding_profile[1]) < \
                       int(bounding_container[1]) + int(bounding_container[3]), \
                    AssertionError('Y coordinate of Profile not within control area')

                # Check Right width,Right of Profile should be lesser than right of control area
                assert int(bounding_container[0]) < \
                       int(bounding_profile[0]) + int(bounding_profile[2]) < \
                       int(bounding_container[0]) + int(bounding_container[2]), \
                    AssertionError('Right coordinate of Profile not within control area')

                # Check Bottom height,Height of Profile should be lesser than bottom height of control area
                assert int(bounding_container[1]) < \
                       int(bounding_profile[1]) + int(bounding_profile[3]) < \
                       int(bounding_container[1]) + int(bounding_container[3]), \
                    AssertionError('Bottom coordinate of Profile not within control area')

        except errorhandler.NoSuchElementException:
            logger.info('No Matching Search entry found', also_console='True')
            raise AssertionError('Profile {0} not found.'.format(search_text))

    @keyword
    def create_profile(self, profile, target=None, name=None):
        """ Create a profile in a control area
        """

        # TODO Scrolling through the target control area required

        self.update_control_areas()
        self.update_profiles()
        pre_profile_list = len(self.profiles_ui)

        if not target:

            # Check for existing control areas
            if not self.control_areas_ui:
                logger.info('No control areas found.  Creating a new one', also_console=PolarisInterface.output_console)
                self.create_control_area()

            # If no target is specified, take the last control area created
            target = self.control_areas_ui.iterkeys().next()
            logger.info('No control area specified.  Selecting {0}'.format(target))

        assert target in self.control_areas_ui, AssertionError('Unable to find {0}.\n'
                                                               'Please select from the following.\n{1}'
                                                               .format(target, self.control_areas_ui.keys()))

        # Click on Profiles menu
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['profiles menu']['id']))

        profile_ui = PolarisInterface.webdriver.scroll_to_element(ui_ref.mapping['control profile template']['id'].format(profile),
                                                                  ui_ref.mapping['control profile list']['id'].format(profile),
                                                                  ui_ref.mapping['profile class name']['id'].format(profile))
        target_ui = self.control_areas_ui[target]
        parent_ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control areas']['id'])

        PolarisInterface.webdriver.drag_and_drop(profile_ui, target_ui, parent_ui,
                                                 analysis=PolarisInterface.visual.motion_detection)

        if name:
            for name_ui in PolarisInterface.webdriver.find_elements_by_accessibility_id(
                    ui_ref.mapping['control profile name']['id']):
                if name_ui.is_displayed():
                    name_ui.send_keys(name)
                    break

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profiles menu']['id']))

        self.update_profiles()

        assert len(self.profiles_ui) > pre_profile_list, 'Profile was not created!'

        logger.info(self.profiles_ui,
                    also_console=PolarisInterface.output_console)

    @keyword
    def select_profile(self, profile):
        """ Selects a profile
        """

        self.update_profiles()

        assert profile in self.profiles_ui, AssertionError("Invalid selection.  Please select from {0}"
                                                           .format(self.profiles_ui.keys()))
        # Selecting the profile
        PolarisInterface.webdriver.click(self.profiles_ui[profile])

    @keyword
    def rename_profile(self, profile, name):
        """ Renames a profile name
        """

        assert profile in self.profiles_ui.keys(), AssertionError('Unable to find {0}.\n'
                                                                  'Please select from the following.\n{1}'
                                                                  .format(profile, self.profiles_ui.keys()))

        PolarisInterface.webdriver.click(self.profiles_ui[profile])
        self.name_profile_area(name)

        self.update_profiles()

    @keyword
    def delete_profile(self, profile=''):
        """ Deletes a profile
        """

        if profile:
            self.select_profile(profile)

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['properties menu']['id']))
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['profile property delete']['id']))
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['yes button']['id']))

        self.update_profiles()

    @keyword
    def open_profile(self, profile):
        """ Opens a profile for configuration
        """

        self.update_profiles()

        assert profile in self.profiles_ui, AssertionError("Invalid selection.  Please select from {0}"
                                                           .format(self.profiles_ui.keys()))

        PolarisInterface.webdriver.double_click(self.profiles_ui[profile], PolarisInterface.visual.motion_detection)

    @keyword
    def close_profile(self):
        """ Closes profile configuration
        Returns to main control area display
        """

        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control area button']['id']))

        sleep(1)

    @keyword
    def personal_control(self, control='True', profile=''):
        """ Enable or disable profile personal control
        
        Variables
            *profile*
                - Profile name
            *control*
                - Personal control setting - True or False
        """

        if profile:
            self.select_profile(profile)

        _control = self.str2bool(control)

        ui = PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['profile personal control']['id'])

        cur_val = ui.is_selected()

        if cur_val != _control:
            # Toggle personal control
            PolarisInterface.webdriver.click(ui)

    @keyword
    def access_key(self, access, profile=''):
        """ Assign access key to profile

        Variables
            *profile*
                - Profile name
            *access*
                - Access key
        """

        if profile:
            self.select_profile(profile)

        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['profile access key']['id']).send_keys(access)

    @keyword
    def label_scene(self, scene, label, profile=''):
        """ Creates or renames a scene label
        
        If a profile is specified, the profile will first be selected.  By default,
        the assumption is profile is already open and therefore has access to the scenes names.
                
        Variables
            *scene*
                - Scene name, [S0, S1, S2, S3, S4]
            *label*
                - Scene label
            *profile*
                - profile to open
        """

        _scene = str(scene).title()

        _scenes = ['S0', 'S1', 'S2', 'S3', 'S4']
        assert _scene in _scenes, 'Please select from the following scenes {0}'.format(_scenes)

        if profile:
            self.select_profile(profile)

        # Click the properties tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['properties menu']['id']))

        # Selecting the target scene
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profile scene']['id'].format(_scene)))

        # Changing scene label
        PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['profile scene name']['id']).send_keys(label)

        # Exiting scene label tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profile scene']['id'].format(_scene)))

    @keyword
    def configure_scene(self, scene, zone, brightness, profile=''):
        """ Configure scene settings on profiles 
        """

        _scene = str(scene).title()

        _scenes = ['S0', 'S1', 'S2', 'S3', 'S4']
        assert _scene in _scenes, 'Please select from the following scenes {0}'.format(_scenes)

        _zone = str(zone).title()

        if profile:
            self.select_profile(profile)

        # Click the properties tab
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['properties menu']['id']))

        # Selecting the target scene
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profile scene']['id'].format(_scene)))

        # Find the parent zone
        zone = PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profile scene config']['id'].format(_zone))

        if isinstance(PolarisInterface.webdriver, WiniumInterface):
            target = zone.find_element_by_id(ui_ref.mapping['profile scene slider value']['id'])
        else:
            target = zone.find_element('accessibility id', ui_ref.mapping['profile scene slider value']['id'])

        target.send_keys(brightness)

        # Exiting scene configuration
        PolarisInterface.webdriver.click(
            PolarisInterface.webdriver.find_element_by_accessibility_id(
                ui_ref.mapping['profile scene']['id'].format(_scene)))

    def name_profile_area(self, name):
        menu = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['properties menu']['id'])
        PolarisInterface.webdriver.click(menu)

        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['profile property name']['id']).clear()
        PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['profile property name']['id']).send_keys(name)
        PolarisInterface.webdriver.click(menu)

    @keyword
    def update_control_areas(self):
        """ This function is currently necessary due to the control area naming convention dependence on current time        
        """

        self.control_areas_ui.clear()

        # Locate the listbox containing all control areas
        control_areas = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control areas']['id'])

        # Find all control area instances
        for item in control_areas.find_elements_by_class_name('ControlArea'):
            area = str(item.get_attribute('AutomationId').replace('autoControlArea', ''))

            self.control_areas_ui[area] = item

    @keyword
    def update_profiles(self):
        """ This function is currently necessary due to the profile naming convention dependence on current time        
        """

        self.profiles_ui.clear()

        # Locate the listbox containing all control areas
        control_areas = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['control areas']['id'])

        # Find all control area instances
        for item in control_areas.find_elements_by_class_name('ProfileInstance'):
            profile = str(item.get_attribute('AutomationId').replace('autoControlProfile', ''))

            self.profiles_ui[profile] = item



