from robot.libraries.BuiltIn import BuiltIn
from .base import HybridCore
from .keywords import ConnectionKeywords
from .keywords import LoginKeywords
from .keywords import MappingKeywords
from .keywords import NavigationKeywords
from .keywords import PerformanceKeywords
from .keywords import ProfileKeywords
from .keywords import ScreenshotKeywords
from .keywords import SiteKeywords
from .keywords import StructureKeywords
from .keywords import SystemInformationKeywords
from .keywords import UserKeywords
from .keywords import VisualAnalysisKeywords
from .keywords import ZoneKeywords


__version__ = '0.2'


class PolarisLibrary(HybridCore):

    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    ROBOT_LIBRARY_VERSION = __version__
    ROBOT_LISTENER_API_VERSION = 2

    def __init__(self,
                 run_on_failure='Capture Screenshot',
                 screenshot_root_directory='./results/artifacts/screenshots/'):

        self.ROBOT_LIBRARY_LISTENER = self
        self.keyword_on_failure = run_on_failure
        self.screenshot_root_directory = screenshot_root_directory

        self.last_keyword = ''

        self.libraries = [ConnectionKeywords(),
                          LoginKeywords(),
                          MappingKeywords(),
                          NavigationKeywords(),
                          PerformanceKeywords(),
                          ProfileKeywords(),
                          ScreenshotKeywords(),
                          SiteKeywords(),
                          StructureKeywords(),
                          SystemInformationKeywords(),
                          UserKeywords(),
                          VisualAnalysisKeywords(),
                          ZoneKeywords()]

        HybridCore.__init__(self, self.libraries)

        self.keywords['set_screenshot_directory'](self.screenshot_root_directory)

    def _start_keyword(self, name, attributes):
        self.last_keyword = attributes['kwname']

    def _end_keyword(self, name, attributes):
        BuiltIn().run_keyword('Set Implicit Wait')

    def _end_test(self, name, attributes):
        if attributes['status'] == 'FAIL' and "exit-on-failure mode is in use" not in attributes['message']:
            if self.last_keyword == 'Validate Ui Placement':
                coord = filter(lambda x: isinstance(x, VisualAnalysisKeywords),
                               self.libraries).pop().get_points_of_interest()
                BuiltIn().run_keyword('Capture Screenshot', 'coord={0}'.format(coord))
            else:
                BuiltIn().run_keyword(self.keyword_on_failure)

            try:
                BuiltIn().run_keyword('Plot Performance')
            except:
                pass

    def _close(self):
        try:
            self.keywords['stop_monitor_performance']()
            self.keywords['disconnect_from_polaris']()
        except:
            pass
