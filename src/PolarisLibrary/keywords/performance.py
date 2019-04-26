import os
import time
import winrm
import psutil
import threading

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.dates import date2num
from matplotlib.figure import figaspect

from matplotlib.dates import HourLocator, MinuteLocator, SecondLocator, DateFormatter
from robot.api import logger

from datetime import datetime
from PolarisLibrary.base import keyword
from PolarisLibrary.base import PolarisInterface


class PerformanceKeywords(PolarisInterface):
    def __init__(self):
        super(PerformanceKeywords, self).__init__()
        self.event = threading.Event()
        self.performance_records = list()
        self.plot_index = 1
        self.tick_period = 15
        self.graph_sizes = {'small': (80, 640, 0.6), 'normal': (100, 800, 0.5),
                            'large': (150, 960, 0.4), 'xlarge': (200, 1280, 0.3)}
        self.graph_size = self.graph_sizes['normal']
        self.worker = None

    @keyword
    def monitor_performance(self, target='Hubsense'):
        """ Start monitoring program resources
        
        Spawns a thread to monitor and record CPU and memory utilization at 1Hz.
        The default program target is 'Encelium.Ecs.Polaris.exe'.
        
        Keywords 'Stop monitor performance' and 'validate performance' are used in conjunction with this keyword.
        """
        if 'localhost' in PolarisInterface.hostname or '127.0.0.1' in PolarisInterface.hostname:
            polaris = [proc for proc in psutil.process_iter(attrs=['name', 'cpu_percent', 'memory_info']) if
                       proc.info['name'] == '{0}.exe'.format(target)]

            assert polaris, AssertionError('Unable to identify process {0}'.format(target))
            polaris = polaris[0].pid
        else:
            polaris = target

        self.event.set()
        del self.performance_records[:]

        try:
            del self.worker
        except NameError:
            pass

        self.worker = threading.Thread(target=self.performance_thread, args=(self.event,
                                                                             polaris,
                                                                             self.tick_period,
                                                                             self.record_performance))
        self.worker.setDaemon(True)
        self.worker.start()

    @keyword
    def stop_monitor_performance(self):
        """ Stops the thread that monitors and records program performance
        """

        self.event.clear()
        self.worker.join()

    @keyword
    def validate_performance(self, mem_threshold=None, cpu_threshold=None, clean=False):
        """ Validate performance thresholds
        
        Ensures that both the CPU and memory utilization do not surpass the specified thresholds.
        CPU threshold indicates the maximum CPU utilization % allowed.
        Memory threshold indicates the maximum memory in MB allowed.
                
        If clean is set to True, all previous data will be deleted and cleaned.
        
        This keyword should be called periodically in order to track the performance of the application.        
        """

        self.plot_performance()
        x_time, y_cpu, y_mem = zip(*self.performance_records)

        if mem_threshold:
            try:
                mem_threshold = int(mem_threshold)
            except ValueError:
                raise ValueError("Invalid memory threshold input")

            assert max(y_mem) < mem_threshold, AssertionError('Exceeded {0}MB memory threshold'.format(mem_threshold))

        if cpu_threshold:
            try:
                cpu_threshold = int(cpu_threshold)
            except ValueError:
                raise ValueError("Invalid cpu threshold input")

            assert max(y_cpu) < cpu_threshold, AssertionError('Exceeded {0}% CPU threshold'.format(cpu_threshold))

        if isinstance(clean, str) and str(clean).lower() == 'true':
            del self.performance_records[:]

    @keyword
    def plot_performance(self):
        """ Creates a graph of both CPU and memory utilization
        
        The resulting graph is saved in the Polaris screenshot folder.
        This keyword is called every time the 'validate performance' keyword is called.
        """

        if not len(self.performance_records):
            logger.info("No performance records to display!  Call keyword 'Monitor Performance' prior.")
            return

        path = PolarisInterface.screenshot.screenshot_root_directory

        if not os.path.exists(path):
            os.makedirs(path)

        x_time, y_cpu, y_mem = zip(*self.performance_records)

        w, h = figaspect(self.graph_size[2])
        fig, ax = plt.subplots(2, sharex=True, figsize=(w, h))

        ax[0].set_ylim(bottom=0, top=max(y_mem) * 1.05)
        ax[0].set_xlim(left=x_time[0], right=x_time[len(x_time) - 1])
        ax[0].plot_date(x_time, y_mem, 'r-', marker='.')
        ax[0].set_title('Polaris Performance')
        ax[0].set_ylabel('Memory Utilization (MB)')
        ax[0].grid()

        ax[1].set_ylim(bottom=0, top=100)
        ax[1].set_xlim(left=x_time[0], right=x_time[len(x_time) - 1])
        ax[1].plot_date(x_time, y_cpu, 'b-', marker='.')
        ax[1].set_ylabel('CPU Utilization (%)')
        ax[1].set_xlabel('Time')
        ax[1].fmt_xdata = DateFormatter('%H:%M:%S')
        ax[1].grid()

        filename = r'\performance_{0}.png'.format(self.plot_index)
        self.plot_index += 1

        fig.autofmt_xdate()
        fig.savefig(path + filename, dpi=self.graph_size[0])

        msg = (
            '</td></tr><tr><td colspan="3"><a href="{0}">'
            '<img src="{1}" width="{2}px"></a>'.format('./artifacts/screenshots' + filename,
                                                       './artifacts/screenshots' + filename,
                                                       self.graph_size[1])
        )

        logger.info(msg, html=True)

    @keyword
    def set_graph_size(self, size):
        """ Sets graph size
        
        There are 4 different sizes to choose from:
        
            Small - pixel width of 480px
            Normal - pixel width of 640px
            Large - pixel width of 960px 
            Xlarge - pixel width of 1280
        """

        _size = str(size).lower()

        assert _size in self.graph_sizes.keys(), AssertionError(
            'Please select from the following: {0}'.format([i.title() for i in self.graph_sizes.keys()]))

        self.graph_size = self.graph_sizes[_size]

    @keyword
    def set_performance_period_time(self, period):
        """ Sets the time between performance queries
        
        *Variables*
            - period - time in seconds
        """

        assert int(period), AssertionError('Invalid {0}.  Please provide a time in seconds')

        if not self.event.isSet():
            logger.info('Changing performance period from {0} to {1}'.format(self.tick_period, period))
            self.tick_period = int(period)
        else:
            logger.info('Unable to change performance period while monitoring application performance.')

    def record_performance(self, cpu, memory):
        self.performance_records.append((date2num(datetime.now()), cpu, memory))

    def performance_thread(self, event, target, period, callback=None):
        """ Thread that records program performance
        """

        remote = False
        cpu = None
        mem = None

        if 'localhost' not in PolarisInterface.hostname and '127.0.0.1' not in PolarisInterface.hostname:
            remote_session = winrm.Session(PolarisInterface.hostname, auth=(PolarisInterface.remote_username,
                                                                            PolarisInterface.remote_password))
            remote = True

        while event.isSet():
            if not remote:
                polaris = psutil.Process(target)

                mem = round(float(polaris.memory_info().vms / 1024 / 1024), 2)
                cpu = round(float(polaris.cpu_percent()), 2)

            else:
                cpu_response = remote_session.run_ps('Get-counter "\Process({0})\% Processor Time" | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue'
                                                     .format(target.rstrip('.exe')))
                try:
                    cpu = round(float(cpu_response.std_out.rstrip()), 2)
                except:
                    pass

                mem_response = remote_session.run_ps('Get-Process -Name {0} | Select-Object -ExpandProperty WorkingSet'
                                                     .format(target.rstrip('.exe')))
                try:
                    mem = round(float(mem_response.std_out.rstrip()) / 1024 / 1024, 2)
                except:
                    pass

            if callback and isinstance(cpu, float) and isinstance(mem, float):
                callback(cpu, mem)
            else:
                pass

            time.sleep(period)
