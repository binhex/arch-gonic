#!/usr/bin/dumb-init /bin/bash

root_folder='/config/gonic'

# create all paths
mkdir -p "${root_folder}/music" "${root_folder}/podcasts" "${root_folder}/playlists" "${root_folder}/cache" "${root_folder}/db"

# run app
/usr/bin/gonic