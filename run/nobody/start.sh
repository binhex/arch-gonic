#!/usr/bin/dumb-init /bin/bash

# create required paths
mkdir -p "${GONIC_MUSIC_PATH}" "${GONIC_PODCAST_PATH}" "${GONIC_PLAYLISTS_PATH}" "${GONIC_CACHE_PATH}" "${GONIC_DB_PATH}"

# run app
/usr/bin/gonic