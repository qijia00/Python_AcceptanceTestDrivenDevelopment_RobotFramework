import os
import ast
import json
import copy
import ntpath

import cv2
import pytesseract
import numpy as np
from time import sleep
from PIL import Image
from PIL import ImageGrab
from difflib import SequenceMatcher

from robot.api import logger

from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface


class VisualAnalysisKeywords(PolarisInterface):
    def __init__(self):
        super(VisualAnalysisKeywords, self).__init__()
        self.reference_ui_path = r'./artifacts/reference_coordinates.json'
        self.points_of_interest = list()

        self.prev_frame = None

        self.max_resolution = (5000, 5000)

        # Delete the file during init to remove residual

        PolarisInterface.visual = self

    @keyword
    def find_text_clipping(self, match_ratio=0.8):
        """ Finds all clipped text in Polaris window
        
        This keyword detects all clipped texts from the current Polaris window.
        Clipped text is determined by the detection of '...' characters indicating
        that WPF was unable to display all of the text within the allocated space.        
        """
        self.update_polaris_location()

        ui_elements = dict()
        _ref_bounding_rectangle = map(int, PolarisInterface.boundingbox)

        for ui in PolarisInterface.webdriver.find_elements_by_class_name('TextBlock'):
            _bounding_rectangle = PolarisInterface.webdriver.get_boundingrect(ui)

            if _bounding_rectangle:
                _bounding_rectangle = map(int, PolarisInterface.webdriver.relative_position(ui))

                if _ref_bounding_rectangle[0] < _bounding_rectangle[0] <= (_ref_bounding_rectangle[0] + _ref_bounding_rectangle[2]) and \
                   _ref_bounding_rectangle[1] < _bounding_rectangle[1] <= (_ref_bounding_rectangle[1] + _ref_bounding_rectangle[3]):

                    ui_elements[ui] = _bounding_rectangle
            else:
                continue

        #PolarisInterface.screenshot.capture_screenshot(filename='./results/artifacts/temp.png', crop=False)
        #ref_img = cv2.imread('./artifacts/temp.png')

        ref_img = cv2.imread(self.screenshot.capture_screenshot(filename='analysis.png', publish=False))

        #screen_pil = ImageGrab.grab()
        #ref_img = np.array(screen_pil.getdata(), dtype='uint8').reshape((screen_pil.size[1], screen_pil.size[0], 3))

        border = 0.01
        clipped_text = list()
        unidentified_text = list()
        for ui in ui_elements:
            crop_img = ref_img[int(ui_elements[ui][1] * (1 - border)):
                               int((ui_elements[ui][1] + ui_elements[ui][3]) * (1 + border)),
                               int(ui_elements[ui][0] * (1 - border)):
                               int((ui_elements[ui][0] + ui_elements[ui][2]) * (1 + border))]

            try:
                crop_img = cv2.resize(crop_img, None, fx=5, fy=5, interpolation=cv2.INTER_CUBIC)
                crop_img = cv2.medianBlur(crop_img, 5)
                crop_img = cv2.bilateralFilter(crop_img, 9, 25, 25)
            except:
                logger.warn('Text clipping visual filtering failed')

            actual = ui.get_attribute('Name')
            derived = pytesseract.image_to_string(Image.fromarray(crop_img))
            derived = derived.replace('\n', ' ').replace('\r', ' ')

            logger.info('\nACTUAL {0}'.format(actual), also_console=True)
            logger.info('DERIVED {0}'.format(derived.encode('utf-8')), also_console=True)

            if SequenceMatcher(None, actual, derived).ratio() < match_ratio:
                unidentified_text.append(actual)

            if '...' in derived:
                clipped_text.append(actual)
                logger.info('CLIPPING TEXT FOUND!', also_console=True)

        if unidentified_text:
            error_message = 'Low confidence match for text:\n'

            for text in unidentified_text:
                if text not in clipped_text:
                    error_message += '{0}\n'.format(text)

            logger.warn(error_message)

        if clipped_text:
            error_message = 'Found clipped text for:\n'

            for text in clipped_text:
                error_message += '{0}\n'.format(text)

            raise AssertionError(error_message)

    @keyword
    def extract_ui_coordinates(self, label='', reference=False):
        """ Extract position of all UI components
        
        Extracts the bounding rectangles of all UI components in the current Polaris screen.
        Their reference position is then calculated based on the top-left corner (0, 0) coordinate.
        
        """
        ui_coordinates = list()
        reference_box = map(int, PolarisInterface.webdriver.get_boundingrect(PolarisInterface.window_ui))
        #logger.info('MAIN BOX {0}'.format(reference_box))
        for ui in PolarisInterface.webdriver.find_elements_by_xpath('.//*'):
            item_bounding_box = PolarisInterface.webdriver.get_boundingrect(ui)
            if item_bounding_box:
                item_bounding_box = map(int, item_bounding_box.split(','))
                if reference_box[0] < item_bounding_box[0] <= reference_box[0] + reference_box[2] and \
                   reference_box[1] < item_bounding_box[1] <= reference_box[1] + reference_box[3]:
                    relative_item_box = [round(float(item_bounding_box[0] - reference_box[0]) / self.max_resolution[0], 4),
                                         round(float(item_bounding_box[1] - reference_box[1]) / self.max_resolution[1], 4),
                                         round(float(item_bounding_box[2]) / self.max_resolution[0], 4),
                                         round(float(item_bounding_box[3]) / self.max_resolution[1], 4)]

                    ui_coordinates.append(relative_item_box)
                    #logger.info('RELATIVE: {0} | ACTUAL: {1}'.format(relative_item_box, item_bounding_box), also_console=True)

        if reference:
            assert label, AssertionError('Please enter a reference label')

            json_ref = dict()
            # Save the json entry to the reference coordinate path

            target_path = ntpath.dirname(self.reference_ui_path)
            if not ntpath.exists(target_path):
                os.makedirs(target_path)

            if ntpath.exists(self.reference_ui_path):
                with open(self.reference_ui_path, 'r') as f:
                    data = f.read()
                    json_ref = json.loads(data)

            json_ref[label] = ui_coordinates

            with open(self.reference_ui_path, 'w') as f:
                f.write(json.dumps(json_ref))

        return ui_coordinates

    @keyword
    def validate_ui_placement(self, label, threshold=5):
        """ Validates the place UI placement
        
        Validates the placement of all UI elements against a reference dataset.
        All UI positions are calculated from the top-left as its origin.
        Changes to the aspect ratio will lead to unstable results.        
        """

        # TODO: Current implementation relies on top-left (0, 0) as origin.  Need to extrapolate that to all corners.

        assert ntpath.exists(self.reference_ui_path), IOError('Unable to open {0}'.format(ntpath.abspath(self.reference_ui_path)))

        _threshold = float(threshold) / 100

        with open(self.reference_ui_path, 'r') as f:
            data = f.read()
            json_data = json.loads(data)

        assert label in json_data.keys(), AssertionError('Unable to find {0} in the reference data.'.format(label))

        ref_data = json_data[label]
        ref_data = [str(item) for item in ref_data]

        extracted_data = self.extract_ui_coordinates()
        extracted_data = [str(item) for item in extracted_data]

        # First stage pass, filter out identically positioned UI elements
        common = set(ref_data).intersection(extracted_data)

        if len(common) == len(ref_data):
            return

        self.points_of_interest = common
        logger.info('First visual analysis pass failed.  Continuing to second pass...')

        # Second stage pass, filter 1% deviation from reference coordinates
        ref_data = set(ref_data).difference(common)
        extracted_data = set(extracted_data).difference(common)

        ref_data = [ast.literal_eval(item) for item in ref_data]
        extracted_data = [ast.literal_eval(item) for item in extracted_data]

        #logger.info('REF DATA {0}'.format(ref_data))
        #logger.info('EXTRACTED DATA {0}'.format(extracted_data))

        common = list()
        for i in ref_data:
            for h in extracted_data:
                try:
                    for x, y in zip(i, h):
                        assert y * (1 - _threshold) < x <= y * (1 + _threshold)
                    common.append(i)
                except AssertionError:
                    continue

        for item in common:
            extracted_data.remove(item)

        if len(common) != len(ref_data):
            self.points_of_interest = extracted_data
            raise AssertionError('{0} UI elements were found that did not exist in the reference layout'
                                 .format(len(extracted_data)))

    def motion_detection(self, action):
        """ Detects action outcome with image processing

        Determines whether or not an action has taken place by comparing the application frames 
        before and after the action.

        Variable
            - action: start or stop
        """

        if action == 'start':
            self.prev_frame = cv2.imread(self.screenshot.capture_screenshot(filename='motion.png', publish=False))
            self.prev_frame = cv2.medianBlur(self.prev_frame, 5)
            return
        elif action == 'stop':
            sleep(1)
            current_frame = cv2.imread(self.screenshot.capture_screenshot(filename='motion.png', publish=False))
            blur_frame = cv2.medianBlur(current_frame, 5)
            diff_frame = cv2.absdiff(self.prev_frame, blur_frame)
            gray_frame = cv2.cvtColor(diff_frame, cv2.COLOR_BGR2GRAY)
            threshold = cv2.threshold(gray_frame, 25, 255, cv2.THRESH_BINARY)[1]

            threshold = cv2.dilate(threshold, None, iterations=2)
            (_, contours, _) = cv2.findContours(threshold.copy(), cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

            #cv2.imwrite('motion_diff.png', threshold)
            return True if len(contours) > 0 else False

    def extract_dominant_color(self, target):
        ref_img = cv2.imread(self.screenshot.capture_screenshot(filename='analysis.png', publish=False))

        ui_coord = PolarisInterface.webdriver.relative_position(target)

        crop_img = ref_img[int(ui_coord[1]): int(ui_coord[1] + ui_coord[3]),
                           int(ui_coord[0]): int(ui_coord[0] + ui_coord[2])]

        b, g, r = cv2.split(crop_img)

        avg_b = np.mean(b)
        avg_g = np.mean(g)
        avg_r = np.mean(r)

        threshold = 15

        if (avg_r - avg_g)/avg_r > 0 and abs(avg_r - avg_g)/avg_r * 100 > threshold:
            return 'red'
        elif (avg_g - avg_r)/avg_g > 0 and abs(avg_g - avg_r)/avg_g * 100 > threshold:
            return 'green'
        elif (abs(avg_r - avg_g)/avg_r) * 100 < threshold:
            return 'yellow'
        else:
            return 'unknown {0}'.format([avg_r, avg_g, avg_b])

    def get_points_of_interest(self):
        toreturn = copy.copy(self.points_of_interest)
        self.points_of_interest = list()

        return toreturn
