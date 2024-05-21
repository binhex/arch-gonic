#!/usr/bin/dumb-init /bin/bash

root_folder='/config/gonic'

# create all paths
mkdir -p "${root_folder}/music" "${root_folder}/podcasts" "${root_folder}/playlists" "${root_folder}/cache" "${root_folder}/db"

# mandatory env vars
######

# path to store audio transcodes, covers, etc
export GONIC_CACHE_PATH="${root_folder}/cache"

# path to your music collection (defined via container env var)
#export GONIC_MUSIC_PATH=""

# path to a podcasts directory (defined via container env var)
#export GONIC_PODCAST_PATH=''

# path to new or existing directory with m3u files for subsonic playlists (defined via container env var)
#export GONIC_PLAYLISTS_PATH=''

# optional env vars
######

# optional path to database file
export GONIC_DB_PATH="${root_folder}/db/gonic.db"

# optional host and port to listen on
#export GONIC_LISTEN_ADDR=''

# optional path to a TLS cert (enables HTTPS listening)
#export GONIC_TLS_CERT

# optional path to a TLS key (enables HTTPS listening)
#export GONIC_TLS_KEY

# optional url path prefix to use if behind reverse proxy
#export GONIC_PROXY_PREFIX=''

# optional interval (in minutes) to check for new music
#export GONIC_SCAN_INTERVAL

# optional whether to perform an initial scan at startup
#export GONIC_SCAN_AT_START_ENABLED=''

# optional whether to watch file system for new music and rescan
#export GONIC_SCAN_WATCHER_ENABLED=''

# optional whether the subsonic jukebox api should be enabled
#export GONIC_JUKEBOX_ENABLED=''

# optional extra command line arguments to pass to the jukebox mpv daemon
#export GONIC_JUKEBOX_MPV_EXTRA_ARGS=''

# optional age (in days) to purge podcast episodes if not accessed
#export GONIC_PODCAST_PURGE_AGE=''

# optional files matching this regex pattern will not be imported
#export GONIC_EXCLUDE_PATTERN=''

# optional setting for multi-valued genre tags when scanning
#export GONIC_MULTI_VALUE_GENRE=''

# optional setting for multi-valued artist tags when scanning
#export GONIC_MULTI_VALUE_ARTIST=''

# optional setting for multi-valued album artist tags when scanning
#export GONIC_MULTI_VALUE_ALBUM_ARTIST=''

# optional enable the /debug/vars endpoint
#export GONIC_EXPVAR=''

# run app
/usr/bin/gonic