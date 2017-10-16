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

# info
# shows info about supported actions
class info():
    def get(self):
        return actions_supported

# do
# performs the requested actions
class do(Resource):

    actions = {
        'play': lambda x: self.play_palylist(x),
        'pause': lambda x: self.pause_palylist(x),
        'stop': lambda x: self.stop_playlist(),
        'reboot': lambda x: self.reboot(),
        'shutdown': lambda x: self.shutdown(),
    }

    def get(self, action, playlist=None):
        return choices.get(action)(playlist)

    def play_playlist(self, playlist):
        if not playlist:
            return ('No Such Playlist!')

        if playlist == 'audio':
            try:
                subprocess.check_call(['bash', '%s/StartVideoPlaylist.sh'.format(SCRIPTS_DIR)])
                return ('Success! Playing Audio Playlist')
            except subprocess.CalledProcessError as e:
                print('Error Occurred during execution of StartAudioPlaylist:\n%s'.format(e))
                return ('Ooops! Something\'s Wrong')
        elif playlist == 'video':
            try:
                subprocess.check_call(['bash', '%s/StartVideoPlaylist.sh'.format(SCRIPTS_DIR)])
                return ('Success! Playing Video Playlist')
            except subprocess.CalledProcessError as e:
                print('Error Occurred during execution of StartVideoPlaylist:\n%s'.format(e))
                return ('Ooops! Something\'s Wrong')

    def pause_playlist(self, playlist):
        return ('Oops! Not Implemented yet')

    def stop_playlist(self, **kwargs):
        try:
            subprocess.check_call(['bash', '%s/stopfpp.sh'.format(SCRIPTS_DIR)])
            return ('Success! Stopped Playlist')
        except subprocess.CalledProcessError as e:
            print('Error Occurred during execution of stopfpp:\n%s'.format(e))
            return ('Ooops! Something\'s Wrong')

    def reboot(self, **kwargs):
        try:
            return ('Rebooting Pi!')
            subprocess.check_call(['shutdown', '-h', 'now'])
        except subprocess.CalledProcessError as e:
            print('Error Occurred while Shutting down execution of stopfpp:\n%s'.format(e))
            return ('Ooops! Something\'s Wrong')

    def shutdown(self, **kwargs):
        try:
            return ('Shutting down Pi!')
            subprocess.check_call(['shutdown', '-h', 'now'])
        except subprocess.CalledProcessError as e:
            print('Error Occurred while Shutting down execution of stopfpp:\n%s'.format(e))
            return ('Ooops! Something\'s Wrong')

##
## Actually setup the Api resource routing here
##
api.add_resource(info, '/')
api.add_resource(do, '/<action>/')
api.add_resource(do, '/<action>/<playlist>')


if __name__ == "__main__":
    app.secret_key = 'C(@WDiuTP796%yZH*zcfOssgvdifhYmZ'

    from gevent.wsgi import WSGIServer
    address = ("localhost", 2017)
    server = WSGIServer(address, app,
        log=my_logger, error_log=my_logger)
    try:
        print("Server running on port %s:%d. Ctrl+C to quit" % address)
        server.serve_forever()
    except KeyboardInterrupt:
        server.stop()
        print("Bye bye")
