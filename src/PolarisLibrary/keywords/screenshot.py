import os
import re
import ast
import errno
import shutil

import cv2
import numpy

from robot.api import logger
from robot.utils import get_link_path
from robot.libraries.BuiltIn import BuiltIn
from robot.libraries.BuiltIn import RobotNotRunningError

from PolarisLibrary.base import keyword
from PolarisLibrary.utils.types import is_falsy
from PolarisLibrary.base import PolarisInterface


class ScreenshotKeywords(PolarisInterface):

    def __init__(self):
        super(ScreenshotKeywords, self).__init__()

        self._screenshot_index = {}
        self._screenshot_path_stack = []
        self.screenshot_root_directory = None
        self.max_resolution = (5000, 5000)

        PolarisInterface.screenshot = self

    @keyword
    def set_screenshot_directory(self, path, persist=False):
        """ Sets default screenshot directory
        """
        path = os.path.abspath(path)

        try:
            shutil.rmtree(path)
        except WindowsError:
            pass

        self._create_directory(path)

        if is_falsy(persist):
            self._screenshot_path_stack.append(self.screenshot_root_directory)

        self.screenshot_root_directory = path

    @keyword
    def capture_screenshot(self, filename='screenshot-{index}.png', crop=True, coord=[], publish=True):
        """ Captures a screenshot
        """
        path, link = self._get_screenshot_paths(filename)
        self._create_directory(path)

        PolarisInterface.webdriver.save_screenshot(path)

        # This is a fix to compensate Winium inability to take a isolated screenshot of the application.
        # By default, it Winium takes a screenshot of the desktop.
        if crop:
            _bounding_box = PolarisInterface.webdriver.get_boundingrect(PolarisInterface.window_ui)
            if _bounding_box != PolarisInterface.boundingbox:
                PolarisInterface.boundingbox = _bounding_box

            _bounding_box = map(int, _bounding_box)
            _bounding_box = numpy.array(_bounding_box)
            _bounding_box[_bounding_box < 0] = 0
            _bounding_box = _bounding_box.tolist()

            img = cv2.imread(path)
            crop_img = img[_bounding_box[1]:(_bounding_box[1] + _bounding_box[3]),
                           _bounding_box[0]:(_bounding_box[0] + _bounding_box[2])]

            if coord:
                for coordinate in ast.literal_eval(coord):
                    cv2.rectangle(crop_img,
                                  (int(coordinate[0] * self.max_resolution[0]),
                                   int(coordinate[1] * self.max_resolution[1])),
                                  (int((coordinate[0] + coordinate[2]) * self.max_resolution[0]),
                                   int((coordinate[1] + coordinate[3]) * self.max_resolution[1])),
                                  (0, 255, 0),
                                  3)

            cv2.imwrite(path, crop_img)

        if self.str2bool(publish):
            msg = (
                '</td></tr><tr><td colspan="3"><a href="{}">'
                '<img src="{}" width="640px"></a>'.format(link, link)
            )

            logger.info(msg, html=True)

        return path

    def _create_directory(self, path):
        target_dir = os.path.dirname(path)
        if not os.path.exists(target_dir):
            try:
                os.makedirs(target_dir)
            except OSError as exc:
                if exc.errno == errno.EEXIST and os.path.isdir(target_dir):
                    pass
                else:
                    raise

    def _get_screenshot_directory(self):

        # Use screenshot root directory if set
        if self.screenshot_root_directory is not None:
            return self.screenshot_root_directory

        # Otherwise use RF's log directory
        return self._get_log_dir()

    # should only be called by set_screenshot_directory
    def _restore_screenshot_directory(self):
        self.screenshot_root_directory = self._screenshot_path_stack.pop()

    def _get_screenshot_paths(self, filename_template):
        screenshotdir = self._get_screenshot_directory()

        filename = filename_template.format(
            index=self._get_screenshot_index(filename_template))

        # try to match {index} but not {{index}} (plus handle
        # other variants like {index!r})
        if re.search(r'(?<!{){index(![rs])?(:.*?)?}(?!})', filename_template):
            # make sure the computed filename doesn't exist. We only
            # do this if the template had the {index} formatting
            # sequence (or one of it's variations)
            while os.path.exists(os.path.join(screenshotdir, filename)):
                filename = filename_template.format(
                    index=self._get_screenshot_index(filename_template))

        filename = filename.replace('/', os.sep)
        logdir = self._get_log_dir()
        path = os.path.join(screenshotdir, filename)
        link = get_link_path(path, logdir)
        return path, link

    def _get_screenshot_index(self, filename):
        if filename not in self._screenshot_index:
            self._screenshot_index[filename] = 0
        self._screenshot_index[filename] += 1
        return self._screenshot_index[filename]

    def _get_log_dir(self):
        try:
            logfile = BuiltIn().get_variable_value('${LOG FILE}')
        except RobotNotRunningError:
            logfile = os.getcwd()
        if logfile != 'NONE':
            logdir = os.path.dirname(logfile)
        else:
            logdir = BuiltIn().get_variable_value('${OUTPUTDIR}')
        return logdir
