#################################################################
# falcon-player-controller-uploadr                              #
# Copyright (c) 2017 atomicnumber1                              #
#################################################################


import subprocess
import logging
import logging.handlers


from flask import Flask
from flask_restful import reqparse, abort, Api, Resource


SCRIPTS_DIR = '/home/fpp/scripts/'

LOG_FILENAME = '/home/fpp/logs/falcon_player_controller.log'

my_logger = logging.getLogger('FalconPlayerController')
my_logger.setLevel(logging.DEBUG)

# Add the log message handler to the logger
handler = logging.handlers.RotatingFileHandler(
              LOG_FILENAME, maxBytes=10*1024*1024, backupCount=5)

my_logger.addHandler(handler)

app = Flask(__name__)
api = Api(app)

actions_supported = ['start', 'pause', 'stop', 'reboot', 'shutdown']

parser = reqparse.RequestParser()
parser.add_argument('action')
parser.add_argument('playlist')

# Info
# shows info about supported actions
class Info(Resource):
    def get(self):
        return actions_supported

# Do
# performs the requested actions
class Do(Resource):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.actions = {
            'play': lambda x: self.play_palylist(x),
            'pause': lambda x: self.pause_palylist(x),
            'stop': lambda x: self.stop_playlist(),
            'reboot': lambda x: self.reboot(),
            'shutdown': lambda x: self.shutdown(),
        }

    def get(self, action, playlist=None):
        return self.actions.get(action)(playlist)

    def play_playlist(self, playlist):
        if not playlist:
            return ('No Such Playlist!')

        if playlist == 'audio':
            try:
                subprocess.check_call(['bash', '{}/StartVideoPlaylist.sh'.format(SCRIPTS_DIR)])
                return ('Success! Playing Audio Playlist')
            except subprocess.CalledProcessError as e:
                print('Error Occurred during execution of StartAudioPlaylist:\n{}'.format(e))
                return ('Ooops! Something\'s Wrong')
        elif playlist == 'video':
            try:
                subprocess.check_call(['bash', '{}/StartVideoPlaylist.sh'.format(SCRIPTS_DIR)])
                return ('Success! Playing Video Playlist')
            except subprocess.CalledProcessError as e:
                print('Error Occurred during execution of StartVideoPlaylist:\n{}'.format(e))
                return ('Ooops! Something\'s Wrong')

    def pause_playlist(self, **kwargs):
        return ('Oops! Not Implemented yet')

    def stop_playlist(self, **kwargs):
        try:
            subprocess.check_call(['bash', '{}/stopfpp.sh'.format(SCRIPTS_DIR)])
            return ('Success! Stopped Playlist')
        except subprocess.CalledProcessError as e:
            print('Error Occurred during execution of stopfpp:\n{}'.format(e))
            return ('Ooops! Something\'s Wrong')

    def reboot(self, **kwargs):
        try:
            subprocess.Popen(['bash', '{}/reboot.sh'.format(SCRIPTS_DIR)])
            return ('Rebooting Pi in 10 secs!')
        except Exception as e:
            print('Error Occurred while Rebooting:\n{}'.format(e))
            return ('Ooops! Something\'s Wrong')

    def shutdown(self, **kwargs):
        try:
            subprocess.Popen(['bash', '{}/shutdown.sh'.format(SCRIPTS_DIR)])
            return ('Shutting down Pi in 10 secs!')
        except Exception as e:
            print('Error Occurred while Shutting down:\n{}'.format(e))
            return ('Ooops! Something\'s Wrong')

##
## Actually setup the Api resource routing here
##
api.add_resource(Info, '/')
api.add_resource(Do, '/<action>/<playlist>')


if __name__ == "__main__":
    app.secret_key = 'C(@WDiuTP796%yZH*zcfOssgvdifhYmZ'

    from gevent.wsgi import WSGIServer
    address = ("0.0.0.0", 2017)
    server = WSGIServer(address, app,
        log=my_logger, error_log=my_logger)
    try:
        print("Server running on port %s:%d. Ctrl+C to quit" % address)
        server.serve_forever()
    except KeyboardInterrupt:
        server.stop()
        print("Bye bye")
