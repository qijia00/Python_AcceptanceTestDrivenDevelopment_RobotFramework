import os
import glob
import ntpath
import shutil
import sqlite3
import paramiko
from robot.api import logger
from _WebServiceCore import _WebServiceCore


class _Database_Keywords(_WebServiceCore):
    _target_db = None
    _db_path = None

    def _set_db_path(self, db):
        # logger.info(db)
        assert os.path.exists('./artifacts/{0}'.format(db)), AssertionError('Unable to find database')
        self._db_path = './artifacts/{0}'.format(db)

    def _extract_db_files(self, ip_address='', offline=False):

        if not offline:
            # Extract default DB from the ECU
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

            try:
                ssh.connect(hostname=ip_address,
                            port=9003,
                            username='root')
                sftp = ssh.open_sftp()

                if not os.path.exists('./artifacts'):
                    os.makedirs('./artifacts')

                stdin, stdout, stderr = ssh.exec_command('find /firmware/webservice/data -name *.sqlite')
                filelist = stdout.read().splitlines()

                for _file in filelist:
                    sftp.get(_file, './artifacts/{0}'.format(ntpath.basename(_file)))

                sftp.close()
                ssh.close()

                logger.info('Databases successfully retrieved')

            except paramiko.SSHException:
                logger.info('Unable to retrieve databases')

        else:
            files = [y for x in os.walk(str(offline)) for y in glob.glob(os.path.join(x[0], '*.sqlite'))]
            for i in files:
                shutil.copyfile(i, './artifacts/{0}'.format(os.path.basename(i)))

    def _get_all_table_records(self, table, identifier='*'):
        _cmd = 'select {0} from {1} {2}'.format(identifier, table, 'desc' if identifier != '*' else '')

        if self._db_path:
            self._target_db = sqlite3.connect(self._db_path)

            cur = self._target_db.cursor()
            cur.execute(_cmd)
            to_return = cur.fetchall()
            self._target_db.close()

            return to_return
        else:
            return list()
