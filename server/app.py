#################################################################
# falcon-player-controller-uploadr                              #
# Copyright (c) 2017 atomicnumber1                              #
#################################################################


import os
import subprocess
import logging
import logging.handlers


from flask import Flask
from flask_restful import (reqparse, Api, Resource)


BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPTS_DIR = os.path.join(BASE_DIR, 'scripts')
LOG_FILENAME = os.path.join(BASE_DIR, 'logs', 'falcon_player_controller.log')

logger = logging.getLogger('FalconPlayerController')
logger.setLevel(logging.DEBUG)

# Add the log message handler to the logger
handler = logging.handlers.RotatingFileHandler(
              LOG_FILENAME, maxBytes=10*1024*1024, backupCount=5)

logger.addHandler(handler)

FPPApp = Flask(__name__)
FPPApi = Api(FPPApp)

ACTIONS_SUPPORTED = [
    'start',
    'pause',
    'stop',
    'reboot',
    'shutdown'
]

STATUS_CODES = {
    'Success': 0,
    'PlayError': 1,
    'PauseError': 2,
    'StopError': 3,
    'RebootError': 4,
    'ShutdownError': 5,
    'SSIDUpdated': 6,
    'SSIDNotUpdated': 7,
    'SSIDCheckError': 8,
    'SSIDUpdateError': 9,
}
def gen_response(status, msg):
    return {'status': status, 'msg': msg}

# Info
# shows info about supported actions
class Info(Resource):
    def get(self):
        return gen_response(STATUS_CODES['Success'], ACTIONS_SUPPORTED)

# Playlist
# performs the requested playlist actions
class Playlist(Resource):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.actions = {
            'play': lambda x: self.play_playlist(x),
            'pause': lambda x: self.pause_playlist(),
            'stop': lambda x: self.stop_playlist(),
        }
        self.default = lambda x: gen_response(STATUS_CODES['Success'], list(self.actions.keys()))

    def get(self, action, playlist):
        return self.actions.get(action, self.default)(playlist)

    def play_playlist(self, playlist):

        if playlist == 'audio':
            try:
                subprocess.check_call(['bash', '{}/StartAudioPlaylist.sh'.format(SCRIPTS_DIR)])
                return gen_response(STATUS_CODES['Success'], 'Playing Audio Playlist')
            except subprocess.CalledProcessError as e:
                logger.error('Error Occurred during execution of StartAudioPlaylist:\n{}'.format(e))
                return gen_response(STATUS_CODES['PlayError'], 'Ooops! Something\'s Wrong')

        elif playlist == 'video':
            try:
                subprocess.check_call(['bash', '{}/StartVideoPlaylist.sh'.format(SCRIPTS_DIR)])
                return gen_response(STATUS_CODES['Success'], 'Playing Video Playlist')
            except subprocess.CalledProcessError as e:
                logger.error('Error Occurred during execution of StartVideoPlaylist:\n{}'.format(e))
                return gen_response(STATUS_CODES['PlayError'], 'Ooops! Something\'s Wrong')
        return gen_response(STATUS_CODES['PlayError'], 'Yikes! No Such Playlist!')

    def pause_playlist(self, **kwargs):
        logger.warning("[pause_playlist] Not Implemented function.")
        return gen_response(STATUS_CODES['PauseError'], 'Oops! Not Implemented yet')

    def stop_playlist(self, **kwargs):
        try:
            subprocess.Popen(['bash', '{}/stopfpp.sh'.format(SCRIPTS_DIR)])
            return gen_response(STATUS_CODES['Success'], 'Stopped Playlist')
        except Exception as e:
            logger.error('Error Occurred during execution of stopfpp:\n{}'.format(e))
            return gen_response(STATUS_CODES['StopError'], 'Ooops! Something\'s Wrong')

class System(Resource):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.parser = reqparse.RequestParser()
        self.parser.add_argument('wifi_ssid')

        self.actions = {
            'reboot': self.reboot,
            'shutdown': self.shutdown,
            'check_ssid': self.check_ssid,
        }
        self.default = lambda: gen_response(STATUS_CODES['Success'], list(self.actions.keys()) + list('update_ssid'))

    def get(self, action):
        return self.actions.get(action, self.default)()

    def post(self, action):
        args = self.parser.parse_args()
        if not args['wifi_ssid']:
            return gen_response(STATUS_CODES['SSIDUpdateError'], 'WiFi SSID can\'t be null. Please provide a valid WiFi SSID.')
        elif not str(args['wifi_ssi']).isalnum():
            return gen_response(STATUS_CODES['SSIDUpdateError'], 'Only alphanumeric characters are allowed. Please provide a valid WiFi SSID.')
        return self.update_ssid(args['wifi_ssid'])

    def reboot(self):
        try:
            subprocess.Popen(['bash', '{}/reboot.sh'.format(SCRIPTS_DIR)])
            return gen_response(STATUS_CODES['Success'], 'Rebooting Pi in 10 secs!')
        except Exception as e:
            logger.error('Error Occurred while Rebooting:\n{}'.format(e))
            return gen_response(STATUS_CODES['RebootError'], 'Ooops! Something\'s Wrong')

    def shutdown(self):
        try:
            subprocess.Popen(['bash', '{}/shutdown.sh'.format(SCRIPTS_DIR)])
            return gen_response(STATUS_CODES['Success'], 'Shutting down Pi in 10 secs!')
        except Exception as e:
            logger.error('Error Occurred while Shutting down:\n{}'.format(e))
            return gen_response(STATUS_CODES['ShutdownError'], 'Ooops! Something\'s Wrong')

    def check_ssid(self):
        try:
            ssid_status = subprocess.check_output(['bash', '{}/check_ssid.sh'.format(SCRIPTS_DIR)])
            if ssid_status == '1':
                return gen_response(STATUS_CODES['SSIDUpdated'], 'WiFi SSID is already Updated.\n Note: You can only update once.')
            else:
                return gen_response(STATUS_CODES['SSIDNotUpdated'], 'WiFi SSID not updated! Please update WiFi SSID.')
        except subprocess.CalledProcessError as e:
            logger.error('Error Occurred while Checking for wifi ssid:\n{}'.format(e))
            return gen_response(STATUS_CODES['SSIDCheckError'], 'Ooops! Something\'s Wrong')

    def update_ssid(self, wifi_ssid):
        try:
            subprocess.check_call(['bash', '{}/update_ssid.sh'.format(SCRIPTS_DIR), wifi_ssid])
            logger.info('WiFi SSID Updated to {}'.format(wifi_ssid))
            return gen_response(STATUS_CODES['Success'], 'WiFi SSID is Updated! System will now reboot.')
        except subprocess.CalledProcessError as e:
            logger.error('Error Occurred while Updating WiFi SSID:\n')
            logger.error(e)
            return gen_response(STATUS_CODES['SSIDUpdateError'], 'Ooops! Something\'s Wrong')

##
## Actually setup the Api resource routing here
##
FPPApi.add_resource(Info, '/')
FPPApi.add_resource(System, '/<action>')
FPPApi.add_resource(Playlist, '/<action>/<playlist>')


if __name__ == "__main__":
    FPPApp.secret_key = 'C(@WDiuTP796%yZH*zcfOssgvdifhYmZ'

    from gevent.wsgi import WSGIServer
    address = ("0.0.0.0", 2017)
    server = WSGIServer(address, FPPApp,
        log=logger, error_log=logger)
    try:
        logger.info("Server running on port %s:%d. Ctrl+C to quit" % address)
        server.serve_forever()
    except KeyboardInterrupt:
        server.stop()
        logger.info("Bye bye")
