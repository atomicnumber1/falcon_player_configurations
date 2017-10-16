#/bin/bash

SRCDIR="${HOME}/code/falcon_player_configurations/server"
VENV="falcon_player_controller"

source ~/.pyenv/versions/falcon_player_controller/bin/activate
cd $SRCDIR
nohup python app.py &> /dev/null &