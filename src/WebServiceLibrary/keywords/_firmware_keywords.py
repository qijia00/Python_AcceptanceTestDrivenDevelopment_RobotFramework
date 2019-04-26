import time
import json
from datetime import datetime
from robot.api import logger
from _WebServiceCore import _WebServiceCore


class _Firmware_Keywords(_WebServiceCore):
    def get_ecu_firmware(self):
        """ Get ECU Firmware
        
        Unimplemented        
        """
        logger.warn('Not Implemented')

    def get_ecu_firmare_list(self):
        """ Get ECU Firmware List 
        
        Unimplemented        
        """
        logger.warn('Not Implemented')

    def get_node_firmware(self):
        """ Get Node Firmware
        
        Unimplemented
        """
        logger.warn('Not Implemented')

    def get_node_firmware_list(self):
        """ Get Node Firmware List
        
        Unimplemented
        """
        logger.warn('Not Implemented')

    def upgrade_node_fw(self, json_payload, timeout=660):
        """ Upgrade Node FW

        Sends the Webservice POST to Upgrade the nodes in the json_payload.
        Then it queries the ECU about the \`upgrade node fw\` status till timeout occurs or it is Complete
        Battery-Powered Nodes can wake up after 6min of the POST message, then it takes about 5min to upgrade (660s)

        Variable
            *json_payload*
                - Json with the nodes and policy to upgrade
            *timeout*
                - optional timeout if it needs to be different than 660s

        For more information, visit `/upgrade-node-fw`_.

        .. _/upgrade-node-fw: http://wiki:8090/pages/viewpage.action?pageId=4849856#DataWebServiceAPI-/api/upgrade-node-firmware
        """
        assert int(timeout), ValueError('Invalid timeout parameter')

        try:
            nodes_info = json.loads(json_payload)
            logger.info(nodes_info)
        except ValueError:
            raise ValueError('Invalid json payload!')

        for item in ('Nodes', 'Policy'):
            assert item in nodes_info, AssertionError('Unable to find {0}'.format(item))

        self._assert_json_response_stop_on_error(self._post('upgrade-node-firmware', json_payload))
        time.sleep(2.0)

        assert int(timeout), ValueError('Invalid timeout parameter')

        # Keep checking status of upgrade until it is done
        _timeout = int(timeout)
        error_count = 0

        for i in range(0, _timeout):
            status = self._convert_api_response_from_json_string_to_json_object(self._get('upgrade-node-firmware'))

            if 'Status' in status.keys():
                if 'complete' == status['Status'].lower():
                    logger.info('Upgrade Node Firmware complete.')
                    if 'Failures' in status.keys() and len(status['Failures']) > 0:
                        raise AssertionError("Up/Down/Transgrade failed: {0}".format(status["Failures"]))
                    return
                elif 'in progress' == status['Status'].lower():
                    error_count = 0
                    time.sleep(1.0)
                else:
                    raise AssertionError('Unable to confirm completion of upgrade node FW, Status is Idle!')
            elif 'status-code' in status.keys() and 'status-string' in status.keys():
                if 'Could not query property' in status['status-string']:
                    if error_count < 5:
                        logger.info('{0}. Trying again once more'.format(status['status-string']))
                        error_count += 1
                    else:
                        raise AssertionError(status['status-string'])
                else:
                    raise AssertionError(status['status-string'])

        raise AssertionError('Unable to confirm completion of upgrade node FW')

