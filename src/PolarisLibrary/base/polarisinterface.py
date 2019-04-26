import re
import ast
import ntpath
import random
import selenium.webdriver
from time import sleep
import lackey as img_finder
from robot.api import logger

from selenium.webdriver.common.by import By
from selenium.common import exceptions as selenium_errors
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.touch_actions import TouchActions
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions


from PolarisLibrary.base import ui_reference as ui_ref


class PolarisInterface(object):
    wait = 0
    navi = None
    visual = None
    hostname = 'localhost'
    root_dir = None
    webdriver = None
    window_ui = None
    webdriver_exe = None
    screenshot = None
    selenium_actions = None

    remote_username = ''
    remote_password = ''

    output_console = False

    boundingbox = list()
    selenium_capabilities = dict()

    window_name = 'OSRAM | HUBSENSE'
    executable = r'C:\Projects\Automation\Polaris_4_auto\Hubsense.exe'

    def __init__(self):
        _path = ntpath.abspath(__file__)
        PolarisInterface.root_dir = _path[:_path.find('src')]

    def update_polaris_location(self):
        for ui in self.webdriver.find_elements_by_name(PolarisInterface.window_name):
            if ui.get_attribute('ClassName') == 'Window':
                PolarisInterface.window_ui = ui
                PolarisInterface.boundingbox = PolarisInterface.webdriver.get_boundingrect(ui)
                PolarisInterface.webdriver.default_handle = ast.literal_eval(ui.get_attribute('NativeWindowHandle'))
                break

    def hide_menu_if_visible(self):
        sleep(1)
        logger.info('Trying to find if the menu is hidden')

        _boundingbox = ast.literal_eval(PolarisInterface.webdriver.find_element_by_accessibility_id(
            ui_ref.mapping['inner menu']['id']).get_attribute('ClickablePoint'))

        logger.info('Polaris box {0}'.format(self.boundingbox), also_console=self.output_console)
        logger.info('Burger click point {0}'.format(_boundingbox), also_console=self.output_console)

        if int(PolarisInterface.boundingbox[0]) < int(_boundingbox[0]) and int(_boundingbox[0] > 0):
            logger.info('Burger menu open, closing it!')
            ui = PolarisInterface.webdriver.find_element_by_accessibility_id(ui_ref.mapping['burger menu']['id'])
            PolarisInterface.webdriver.click(ui)

            sleep(1)
            logger.info('Burger menu should now be closed!', also_console=self.output_console)
        else:
            logger.info('Burger menu is closed!', also_console=self.output_console)

    def str2bool(self, str_input):
        """ Change string to bool
        """

        if isinstance(str_input, bool):
            return str_input

        try:
            return ast.literal_eval(str(str_input).title())
        except ValueError:
            raise ValueError('Invalid input.  Please select from [True or False]')


class WiniumInterface(selenium.webdriver.Remote):
    def __init__(self, command_executor=None, desired_capabilities=None,
                 browser_profile=None, proxy=None,
                 keep_alive=False, file_detector=None):

        self.default_handle = None

        super(WiniumInterface, self).__init__(command_executor, desired_capabilities,
                                              browser_profile, proxy, keep_alive, file_detector)

    def drag_and_drop(self, source, target, parent=None, analysis=None):
        if analysis:
            analysis('start')

        actions = ActionChains(self)

        if not parent:
            actions.drag_and_drop(source, target).perform()

            if analysis:
                for i in range(1, 6):
                    if not analysis('stop'):
                        actions.perform()
                    else:
                        logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                            target.get_attribute('AutomationId'), i))
                        return

                logger.info('Unable to validate click after 10 tries')

        _target_box = self.get_boundingrect(target)
        _parent_box = self.get_boundingrect(parent)

        # Find overlap between boxes
        _overlap_box = list()

        # Check left and top coordinates
        _overlap_box.append(_target_box[0] if _target_box[0] > _parent_box[0] else _parent_box[0])
        _overlap_box.append(_target_box[1] if _target_box[1] > _parent_box[1] else _parent_box[1])

        # Check width and height
        _overlap_box.append(_target_box[2] if _overlap_box[0] + _target_box[2] < _overlap_box[0] + _parent_box[2] else
                            _parent_box[0] + _parent_box[2] - _overlap_box[0])

        _overlap_box.append(_target_box[3] if _overlap_box[1] + _target_box[3] < _overlap_box[1] + _parent_box[3] else
                            _parent_box[1] + _parent_box[3] - _overlap_box[1])

        x = random.randint(_overlap_box[0], _overlap_box[0] + _overlap_box[2])
        y = random.randint(_overlap_box[1], _overlap_box[1] + _overlap_box[3])

        source_position = ast.literal_eval(source.get_attribute('ClickablePoint'))

        rel_x = -1 * (source_position[0] - x)
        rel_y = -1 * (source_position[1] - y)

        actions.drag_and_drop_by_offset(source, rel_x, rel_y).perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def click(self, target, analysis=None):
        if analysis:
            analysis('start')

        actions = ActionChains(self)
        actions.click(target)
        actions.perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def long_click(self, target):
        """ Implements as a simple click
        """

        self.click(target)

    def double_click(self, target, analysis=None):
        if analysis:
            analysis('start')

        actions = ActionChains(self)
        actions.double_click(target).perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def select_combobox_item(self, combobox, item, child=''):
        ui = self.find_element_by_accessibility_id(combobox)
        self.click(ui)

        item_list = ui.find_elements_by_class_name('ListBoxItem' if not child else child)
        assert item in [i.get_attribute('Name') for i in item_list], AssertionError('Item "{0}" not found!'.format(item))

        self.click(ui.find_element_by_name(item))

    def find_element_by_accessibility_id(self, _id):
        return self.find_element_by_id(_id)

    def find_elements_by_accessibility_id(self, _id):
        return self.find_elements_by_id(_id)

    def get_boundingrect(self, target):
        """ Gets a bounding rectangle of the target UI
        Returns a list containing the left, top, width, height
        """

        bounding_box = target.get_attribute('BoundingRectangle')

        try:
            bounding_box = ast.literal_eval(bounding_box)
        except ValueError:
            bounding_box = None

        return bounding_box

    def switch_to_default(self):
        try:
            self.switch_to.window(self.default_handle)
        except selenium_errors.WebDriverException:
            pass

    def scroll_to_element(self, target, parent_element, target_element, analysis=None):
        _mouse = img_finder.Mouse()

        items = self.find_element_by_accessibility_id(parent_element)
        item_list = items.find_elements_by_class_name(target_element)
        self.click(items)

        parent_boundingbox = self.get_boundingrect(items)

        if parent_element in (ui_ref.mapping['mapping node list']['id']):
            mode = 'telerik'
        else:
            mode = 'default'

        if mode == 'default':
            target_ui = self.find_element_by_accessibility_id(target)
            self.implicitly_wait(0)

            target_position = ast.literal_eval(target_ui.get_attribute('ClickablePoint'))
            direction = -1 if target_position[1] > parent_boundingbox[1] else 1

            try:
                if not parent_boundingbox[0] < target_position[0] < parent_boundingbox[0] + parent_boundingbox[2] \
                        or not parent_boundingbox[1] < target_position[1] < parent_boundingbox[1] + parent_boundingbox[3]:
                    _mouse.wheel(_mouse.WHEEL_DOWN if direction == -1 else _mouse.WHEEL_UP, 1)
                    return self.scroll_to_element(target, parent_element, target_element)

                else:
                    return target_ui

            except selenium_errors.NoSuchElementException:
                _pre_move_pos = item_list[len(item_list) - 1].get_attribute('ClickablePoint')
                _mouse.wheel(_mouse.WHEEL_DOWN if direction == -1 else _mouse.WHEEL_UP, 1)
                _post_move_pos = item_list[len(item_list) - 1].get_attribute('ClickablePoint')

                if _pre_move_pos != _post_move_pos:
                    return self.scroll_to_element(target, parent_element, target_element)
                else:
                    raise LookupError('Unable to find {0}'.format(target))

        elif mode == 'telerik':
            # Handle Telerik optimized (non virtualized UI here)
            # Top Button - autoid LineUp
            # Bottom Button - autoid LineDown
            # Slider - classname Thumb

            # Strategy, click the scroll buttons until until you find it.
            # Go to the top first then all the way back to bottom

            try:
                top_ui = items.find_element_by_id('LineUp')
                top_boundingbox = self.get_boundingrect(top_ui)
                top_limit = top_boundingbox[1] + top_boundingbox[3]

                bottom_ui = items.find_element_by_id('LineDown')
                bottom_boundingbox = self.get_boundingrect(bottom_ui)
                bottom_limit = bottom_boundingbox[1]

                thumb_ui = items.find_element_by_class_name('Thumb')
                thumb_boundingbox = self.get_boundingrect(thumb_ui)
                thumb_t_limit = thumb_boundingbox[1]
                thumb_b_limit = thumb_boundingbox[1] + thumb_boundingbox[3] + bottom_boundingbox[3]

                self.implicitly_wait(0)

                # Go to the top
                while top_limit < thumb_t_limit:
                    self.click(top_ui)
                    thumb_boundingbox = self.get_boundingrect(thumb_ui)
                    thumb_t_limit = thumb_boundingbox[1]

                    sleep(0.1)

                # Start searching
                while bottom_limit > thumb_b_limit:
                    try:
                        print target

                        target_ui = items.find_element_by_id(target)
                        return target_ui
                    except selenium_errors.NoSuchElementException:
                        for i in range(0, 6):
                            self.click(bottom_ui)
                            thumb_boundingbox = self.get_boundingrect(thumb_ui)
                            thumb_b_limit = thumb_boundingbox[1] + thumb_boundingbox[3]

                            sleep(0.1)

            except selenium_errors.NoSuchElementException:
                target_ui = self.find_element_by_accessibility_id(target)

            assert target_ui, LookupError('Unable to find {0}'.format(target))

        self.implicitly_wait(PolarisInterface.wait)

    def relative_position(self, target):
        """ Extract the relative position of a UI target
        """

        abs_window_pos = self.get_boundingrect(PolarisInterface.window_ui)
        abs_target_pos = self.get_boundingrect(target)

        rel_target_pos = list(abs_target_pos)
        rel_target_pos[0] = rel_target_pos[0] - abs_window_pos[0]
        rel_target_pos[1] = rel_target_pos[1] - abs_window_pos[1]

        return rel_target_pos

    def waitfor(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.visibility_of_element_located((By.ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))

    def waitforclickable(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.element_to_be_clickable((By.ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))


class WinAppDriverInterface(selenium.webdriver.Remote):
    def __init__(self, command_executor=None, desired_capabilities=None,
                 browser_profile=None, proxy=None,
                 keep_alive=False, file_detector=None):

        By.ACCESSIBILITY_ID = 'accessibility id'
        self.default_handle = None

        super(WinAppDriverInterface, self).__init__(command_executor, desired_capabilities,
                                                    browser_profile, proxy, keep_alive, file_detector)

    def find_element_by_accessibility_id(self, target):
        return self.find_element(By.ACCESSIBILITY_ID, target)

    def find_elements_by_accessibility_id(self, target):
        return self.find_elements(By.ACCESSIBILITY_ID, target)

    def drag_and_drop(self, source, target, parent=None, analysis=None):
        if analysis:
            analysis('start')

        touch = TouchActions(self)

        _source_coord = ast.literal_eval(source.get_attribute('ClickablePoint'))

        if not parent:
            _target_coord = ast.literal_eval(target.get_attribute('ClickablePoint'))
            logger.info('Source {0} Target {1}'.format(_source_coord, _target_coord), also_console=PolarisInterface.output_console)

            self.click(source)
            touch.tap_and_hold(_source_coord[0], _source_coord[1])
            sleep(1)
            touch.release(_target_coord[0], _target_coord[1]).perform()

            if analysis:
                for i in range(1, 6):
                    if not analysis('stop'):
                        touch.perform()
                    else:
                        logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                            target.get_attribute('AutomationId'), i))
                        return

                logger.info('Unable to validate click after 10 tries')

        _target_box = self.get_boundingrect(target)
        _parent_box = self.get_boundingrect(parent)

        # Find overlap between boxes
        _overlap_box = list()

        # Check left and top coordinates
        _overlap_box.append(_target_box[0] if _target_box[0] > _parent_box[0] else _parent_box[0])
        _overlap_box.append(_target_box[1] if _target_box[1] > _parent_box[1] else _parent_box[1])

        # Check width and height
        _overlap_box.append(_target_box[2] if _overlap_box[0] + _target_box[2] < _overlap_box[0] + _parent_box[2] else
                            _parent_box[0] + _parent_box[2] - _overlap_box[0])

        _overlap_box.append(_target_box[3] if _overlap_box[1] + _target_box[3] < _overlap_box[1] + _parent_box[3] else
                            _parent_box[1] + _parent_box[3] - _overlap_box[1])

        x = random.randint(_overlap_box[0], _overlap_box[0] + _overlap_box[2])
        y = random.randint(_overlap_box[1], _overlap_box[1] + _overlap_box[3])

        self.click(source)
        touch.tap_and_hold(_source_coord[0], _source_coord[1])
        sleep(1)
        touch.release(x, y).perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    touch.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def double_click(self, target, analysis=None):
        """ Implements double click as double tap for WinAppDriver
        """

        if analysis:
            analysis('start')

        logger.info('Tapped {0}'.format(target.get_attribute('AutomationId')), also_console=PolarisInterface.output_console)

        touch = TouchActions(self)
        touch.double_tap(target).perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    touch.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def click(self, target, analysis=None):
        """ Implements as single tap for WinAppDriver
        
        Due to the inconsistency with Polaris touch behavior, a touch tap is actually implemented as 
        touch and hold, wait then release.
        
        If Polaris touch response if fixed, this should revert back to a simple tap call to WinAppDriver
        """

        if analysis:
            analysis('start')

        touch = TouchActions(self)
        touch.tap(target)
        touch.perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    touch.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def long_click(self, target):
        """ Implements as a long tap
        """

        touch = TouchActions(self)
        touch.long_press(target).perform()

    def get_boundingrect(self, target):
        """ Gets a bounding rectangle of the target UI
        Returns a list containing the left, top, width, height
        """

        bounding_box = target.get_attribute('BoundingRectangle')
        bounding_box = re.search('Left:(-?\d+).*Top:(-?\d+).*Width:(-?\d+).*Height:(-?\d+)', bounding_box).groups()

        return [int(i) for i in bounding_box]

    def scroll_to_element(self, target, parent_element, target_element, analysis=None):
        items = self.find_element_by_accessibility_id(parent_element)
        item_list = items.find_elements_by_class_name(target_element)
        self.click(items)

        parent_boundingbox = self.get_boundingrect(items)

        if parent_element in (ui_ref.mapping['mapping node list']['id']):
            mode = 'telerik'
        else:
            mode = 'default'

        if mode == 'default':
            records = [i.get_attribute('AutomationId') for i in item_list]

            self.implicitly_wait(0)
            target_ui = self.find_element_by_accessibility_id(target)

            target_position = ast.literal_eval(target_ui.get_attribute('ClickablePoint'))
            direction = Keys.PAGE_DOWN + Keys.PAGE_DOWN if target_position[1] > parent_boundingbox[1] else \
                Keys.PAGE_UP + Keys.PAGE_UP

            try:
                if not parent_boundingbox[0] < target_position[0] < parent_boundingbox[0] + parent_boundingbox[2] \
                        or not parent_boundingbox[1] < target_position[1] < parent_boundingbox[1] + parent_boundingbox[3]:
                    items.send_keys(direction)
                    return self.scroll_to_element(target, parent_element, target_element)

                else:
                    return target_ui

            except selenium_errors.NoSuchElementException:
                _pre_move_pos = item_list[-1].get_attribute('ClickablePoint')
                items.send_keys(direction)
                _post_move_pos = item_list[-1].get_attribute('ClickablePoint')

                if _pre_move_pos != _post_move_pos:
                    return self.scroll_to_element(target, parent_element, target_element)
                else:
                    logger.info('Detected the following items {0}'.format(records))
                    raise LookupError('Unable to find {0}'.format(target))

            finally:
                self.implicitly_wait(PolarisInterface.wait)

        elif mode == 'telerik':
            self.implicitly_wait(0)

            # Go to the bottom and record the last element
            if analysis:
                analysis('start')

            items.send_keys(Keys.LEFT_CONTROL + Keys.END)

            if analysis:
                for i in range(1, 6):
                    if not analysis('stop'):
                        items.send_keys(Keys.LEFT_CONTROL + Keys.END)
                    else:
                        logger.warn("Trouble sending keys")
                        break

            elements = items.find_elements_by_class_name(target_element)
            logger.info(elements)
            assert len(elements), 'Unable to find {0}'.format(target)

            last_element = elements[0].get_attribute('AutomationId')

            # Go to the top and start searching
            if analysis:
                analysis('start')

            items.send_keys(Keys.LEFT_CONTROL + Keys.HOME)

            if analysis:
                for i in range(1, 6):
                    if not analysis('stop'):
                        items.send_keys(Keys.LEFT_CONTROL + Keys.HOME)
                    else:
                        logger.warn("Trouble sending keys")
                        break

            temp_element = items.find_element_by_class_name(target_element).get_attribute('AutomationId')

            try:
                items.find_element_by_class_name('Thumb')
                scrollable = True
            except selenium_errors.NoSuchElementException:
                scrollable = False

            if scrollable:
                while last_element != temp_element:
                    try:
                        target_ui = items.find_element(By.ACCESSIBILITY_ID, target)
                        self.implicitly_wait(PolarisInterface.wait)
                        return target_ui
                    except selenium_errors.NoSuchElementException:

                        if analysis:
                            analysis('start')

                        items.send_keys(Keys.PAGE_DOWN)

                        if analysis:
                            for i in range(1, 6):
                                if not analysis('stop'):
                                    items.send_keys(Keys.PAGE_DOWN)
                                else:
                                    logger.warn("Trouble sending keys")
                                    break

                    temp_element = items.find_element_by_class_name(target_element).get_attribute('AutomationId')

            else:
                try:
                    target_ui = items.find_element(By.ACCESSIBILITY_ID, target)
                    self.implicitly_wait(PolarisInterface.wait)
                    return target_ui
                except selenium_errors.NoSuchElementException:
                    pass

            self.implicitly_wait(PolarisInterface.wait)
            raise LookupError('Unable to find {0}'.format(target))

        self.implicitly_wait(PolarisInterface.wait)

    def relative_position(self, target):
        """ Extract the relative position of a UI target
        """

        abs_window_pos = self.get_boundingrect(PolarisInterface.window_ui)
        abs_target_pos = self.get_boundingrect(target)

        rel_target_pos = list(abs_target_pos)
        rel_target_pos[0] = rel_target_pos[0] - abs_window_pos[0]
        rel_target_pos[1] = rel_target_pos[1] - abs_window_pos[1]

        return rel_target_pos

    def waitfor(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.visibility_of_element_located((By.ACCESSIBILITY_ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))

    def waitforclickable(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.element_to_be_clickable((By.ACCESSIBILITY_ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))


class WinAppDriverInterfaceMouse(selenium.webdriver.Remote):
    def __init__(self, command_executor=None, desired_capabilities=None,
                 browser_profile=None, proxy=None,
                 keep_alive=False, file_detector=None):

        By.ACCESSIBILITY_ID = 'accessibility id'
        self.default_handle = None

        self.cal_x = 1.041
        self.cal_y = 1.023

        super(WinAppDriverInterfaceMouse, self).__init__(command_executor, desired_capabilities,
                                                         browser_profile, proxy, keep_alive, file_detector)

    def find_element_by_accessibility_id(self, target):
        return self.find_element(By.ACCESSIBILITY_ID, target)

    def find_elements_by_accessibility_id(self, target):
        return self.find_elements(By.ACCESSIBILITY_ID, target)

    def drag_and_drop(self, source, target, parent=None, analysis=None):
        if analysis:
            analysis('start')

        actions = ActionChains(self)

        _source_coord = ast.literal_eval(source.get_attribute('ClickablePoint'))

        _target_box = self.get_boundingrect(target)
        _source_box = self.get_boundingrect(source)

        actions.move_to_element_with_offset(source,
                                            (_source_box[2] / 2 + _source_box[0]) * self.cal_x - _source_box[0],
                                            (_source_box[3] / 2 + _source_box[1]) * self.cal_y - _source_box[1])
        actions.click_and_hold()
        actions.move_to_element_with_offset(target,
                                            (_target_box[2] / 2 + _target_box[0]) * self.cal_x - _target_box[0],
                                            (_target_box[3] / 2 + _target_box[1]) * self.cal_y - _target_box[1])
        actions.release()

        if not parent:
            _target_coord = ast.literal_eval(target.get_attribute('ClickablePoint'))
            logger.info('Source {0} Target {1}'.format(_source_coord, _target_coord),
                        also_console=PolarisInterface.output_console)

            actions.perform()

            if analysis:
                for i in range(1, 6):
                    if not analysis('stop'):
                        actions.perform()
                    else:
                        logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                            target.get_attribute('AutomationId'), i))
                        return

                logger.info('Unable to validate click after 10 tries')

        _parent_box = self.get_boundingrect(parent)

        # Find overlap between boxes
        _overlap_box = list()

        # Check left and top coordinates
        _overlap_box.append(_target_box[0] if _target_box[0] > _parent_box[0] else _parent_box[0])
        _overlap_box.append(_target_box[1] if _target_box[1] > _parent_box[1] else _parent_box[1])

        # Check width and height
        _overlap_box.append(_target_box[2] if _overlap_box[0] + _target_box[2] < _overlap_box[0] + _parent_box[2] else
                            _parent_box[0] + _parent_box[2] - _overlap_box[0])

        _overlap_box.append(_target_box[3] if _overlap_box[1] + _target_box[3] < _overlap_box[1] + _parent_box[3] else
                            _parent_box[1] + _parent_box[3] - _overlap_box[1])

        x = random.randint(_overlap_box[0], _overlap_box[0] + _overlap_box[2])
        y = random.randint(_overlap_box[1], _overlap_box[1] + _overlap_box[3])

        actions.perform()

        if analysis:
            for i in range(1, 10):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def double_click(self, target, analysis=None):
        """ Implements double click as double tap for WinAppDriver
        """

        if analysis:
            analysis('start')

        logger.info('Tapped {0}'.format(target.get_attribute('AutomationId')),
                    also_console=PolarisInterface.output_console)

        actions = ActionChains(self)
        box = self.get_boundingrect(target)
        actions.move_to_element_with_offset(target,
                                            (box[2] / 2 + box[0]) * self.cal_x - box[0],
                                            (box[3] / 2 + box[1]) * self.cal_y - box[1])
        actions.double_click()
        actions.perform()

        if analysis:
            for i in range(1, 6):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def click(self, target, analysis=None):
        if analysis:
            analysis('start')

        actions = ActionChains(self)
        box = self.get_boundingrect(target)
        actions.move_to_element_with_offset(target,
                                            (box[2]/2 + box[0]) * self.cal_x - box[0],
                                            (box[3]/2 + box[1]) * self.cal_y - box[1])
        actions.click()
        actions.perform()

        if analysis:
            for i in range(1, 6):
                if not analysis('stop'):
                    actions.perform()
                else:
                    logger.warn("Trouble interacting with {0}.  Required {1} additional clicks to activate".format(
                        target.get_attribute('AutomationId'), i))
                    return

            raise AssertionError('Unable to validate click after 10 tries')

    def long_click(self, target):
        """ Implements as a long tap
        """

        self.click(target)

    def get_boundingrect(self, target):
        """ Gets a bounding rectangle of the target UI
        Returns a list containing the left, top, width, height
        """

        bounding_box = target.get_attribute('BoundingRectangle')
        bounding_box = re.search('Left:(-?\d+).*Top:(-?\d+).*Width:(-?\d+).*Height:(-?\d+)', bounding_box).groups()

        return [int(i) for i in bounding_box]

    def scroll_to_element(self, target, parent_element, target_element, analysis=None):
        items = self.find_element_by_accessibility_id(parent_element)
        item_list = items.find_elements_by_class_name(target_element)
        self.click(items)

        parent_boundingbox = self.get_boundingrect(items)

        if parent_element in (ui_ref.mapping['mapping node list']['id']):
            mode = 'telerik'
        else:
            mode = 'default'

        if mode == 'default':
            records = [i.get_attribute('AutomationId') for i in item_list]

            self.implicitly_wait(0)
            target_ui = self.find_element_by_accessibility_id(target)

            target_position = ast.literal_eval(target_ui.get_attribute('ClickablePoint'))
            direction = Keys.PAGE_DOWN + Keys.PAGE_DOWN if target_position[1] > parent_boundingbox[1] else \
                Keys.PAGE_UP + Keys.PAGE_UP

            try:
                if not parent_boundingbox[0] < target_position[0] < parent_boundingbox[0] + parent_boundingbox[2] \
                        or not parent_boundingbox[1] < target_position[1] < parent_boundingbox[1] + parent_boundingbox[
                            3]:
                    items.send_keys(direction)
                    return self.scroll_to_element(target, parent_element, target_element)

                else:
                    return target_ui

            except selenium_errors.NoSuchElementException:
                _pre_move_pos = item_list[-1].get_attribute('ClickablePoint')
                items.send_keys(direction)
                _post_move_pos = item_list[-1].get_attribute('ClickablePoint')

                if _pre_move_pos != _post_move_pos:
                    return self.scroll_to_element(target, parent_element, target_element)
                else:
                    logger.info('Detected the following items {0}'.format(records))
                    raise LookupError('Unable to find {0}'.format(target))

            finally:
                self.implicitly_wait(PolarisInterface.wait)

        elif mode == 'telerik':
            self.implicitly_wait(0)

            try:
                items.find_element_by_class_name('Thumb')
                scrollable = True
            except selenium_errors.NoSuchElementException:
                scrollable = False

            if scrollable:
                # Go to the bottom and record the last element
                if analysis:
                    analysis('start')

                items.send_keys(Keys.LEFT_CONTROL + Keys.END)

                if analysis:
                    for i in range(1, 6):
                        if not analysis('stop'):
                            items.send_keys(Keys.LEFT_CONTROL + Keys.END)
                        else:
                            logger.warn("Trouble sending keys")
                            break

                elements = items.find_elements_by_class_name(target_element)
                logger.info(elements)
                assert len(elements), 'Unable to find {0}'.format(target)

                last_element = elements[0].get_attribute('AutomationId')

                # Go to the top and start searching
                if analysis:
                    analysis('start')

                items.send_keys(Keys.LEFT_CONTROL + Keys.HOME)

                if analysis:
                    for i in range(1, 6):
                        if not analysis('stop'):
                            items.send_keys(Keys.LEFT_CONTROL + Keys.HOME)
                        else:
                            logger.warn("Trouble sending keys")
                            break

                temp_element = items.find_element_by_class_name(target_element).get_attribute('AutomationId')

                while last_element != temp_element:
                    try:
                        target_ui = items.find_element(By.ACCESSIBILITY_ID, target)
                        self.implicitly_wait(PolarisInterface.wait)
                        return target_ui
                    except selenium_errors.NoSuchElementException:
                        if analysis:
                            analysis('start')

                        items.send_keys(Keys.PAGE_DOWN)

                        if analysis:
                            for i in range(1, 6):
                                if not analysis('stop'):
                                    items.send_keys(Keys.PAGE_DOWN)
                                else:
                                    logger.warn("Trouble sending keys")
                                    break

                    temp_element = items.find_element_by_class_name(target_element).get_attribute('AutomationId')

            else:
                try:
                    target_ui = items.find_element(By.ACCESSIBILITY_ID, target)
                    self.implicitly_wait(PolarisInterface.wait)
                    return target_ui
                except selenium_errors.NoSuchElementException:
                    pass

            self.implicitly_wait(PolarisInterface.wait)
            raise LookupError('Unable to find {0}'.format(target))

        self.implicitly_wait(PolarisInterface.wait)

    def relative_position(self, target):
        """ Extract the relative position of a UI target
        """

        abs_window_pos = self.get_boundingrect(PolarisInterface.window_ui)
        abs_target_pos = self.get_boundingrect(target)

        rel_target_pos = list(abs_target_pos)
        rel_target_pos[0] = rel_target_pos[0] - abs_window_pos[0]
        rel_target_pos[1] = rel_target_pos[1] - abs_window_pos[1]

        return rel_target_pos

    def waitfor(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.visibility_of_element_located((By.ACCESSIBILITY_ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))

    def waitforclickable(self, target, timeout):
        wait = WebDriverWait(self, timeout)
        try:
            wait.until(expected_conditions.element_to_be_clickable((By.ACCESSIBILITY_ID, target)))
        except selenium_errors.TimeoutException:
            raise selenium_errors.TimeoutException('Element {0} not found'.format(target))
        logger.info('Element {0} found'.format(target))
