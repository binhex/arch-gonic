#!/bin/bash

# exit script if return code != 0
set -e

# app name from buildx arg, used in healthcheck to identify app and monitor correct process
APPNAME="${1}"
shift

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1}"
shift

# target arch from buildx arg
TARGETARCH="${1}"
shift

if [[ -z "${APPNAME}" ]]; then
	echo "[warn] App name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# write APPNAME and RELEASETAG to file to record the app name and release tag used to build the image
echo -e "export APPNAME=${APPNAME}\nexport IMAGE_RELEASE_TAG=${RELEASETAG}\n" >> '/etc/image-build-info'

# ensure we have the latest builds scripts
refresh.sh

# pacman packages
####

# define pacman packages
pacman_packages="mpv ffmpeg"

# install compiled packages using pacman
if [[ -n "${pacman_packages}" ]]; then
	# arm64 currently targetting aor not archive, so we need to update the system first
	if [[ "${TARGETARCH}" == "arm64" ]]; then
		pacman -Syu --noconfirm
	fi
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="gonic"

# call aur install script (arch user repo)
aur.sh --aur-package "${aur_packages}"

# container perms
####

# define comma separated string of install paths
install_paths="/home/nobody"

# split comma separated string into list for install paths
IFS=',' read -ra install_paths_list <<< "${install_paths}"

# process install paths in the list
for i in "${install_paths_list[@]}"; do

	# confirm path(s) exist, if not then exit
	if [[ ! -d "${i}" ]]; then
		echo "[crit] Path '${i}' does not exist, exiting build process..." ; exit 1
	fi

done

# convert comma separated string of install paths to space separated, required for chmod/chown processing
install_paths=$(echo "${install_paths}" | tr ',' ' ')

# set permissions for container during build - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
chmod -R 775 ${install_paths}

# In install.sh heredoc, replace the chown section:
cat <<EOF > /tmp/permissions_heredoc
install_paths="${install_paths}"
EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

# source in utility functions, need process_env_var
source utils.sh

# define environment variables to process
# format: "VAR_NAME:DEFAULT_VALUE:REQUIRED:MASK"
# note: - a default value must not contain a colon, it is the field separator
#       - an empty default means the app default is used, gonic ignores empty env vars
#       - required variables must be supplied, the container exits if not, so the default is not used
#       - the paths under /config/gonic are created by run/nobody/start.sh
env_vars=(
	# paths
	"GONIC_MUSIC_PATH:/config/gonic/music:true:false"
	"GONIC_PODCAST_PATH:/config/gonic/podcasts:true:false"
	"GONIC_PLAYLISTS_PATH:/config/gonic/playlists:true:false"
	"GONIC_CACHE_PATH:/config/gonic/cache:true:false"
	"GONIC_DB_PATH:/config/gonic/db/gonic.db:true:false"

	# web interface
	"GONIC_LISTEN_ADDR::false:false"
	"GONIC_PROXY_PREFIX::false:false"
	"GONIC_TLS_CERT::false:false"
	"GONIC_TLS_KEY::false:false"
	"GONIC_HTTP_LOG::false:false"

	# scanning
	"GONIC_SCAN_INTERVAL::false:false"
	"GONIC_SCAN_AT_START_ENABLED::false:false"
	"GONIC_SCAN_WATCHER_ENABLED::false:false"
	"GONIC_SCAN_EMBEDDED_COVER_ENABLED::false:false"
	"GONIC_EXCLUDE_PATTERN::false:false"
	"GONIC_GENRE_TREE::false:false"

	# multi valued tags
	"GONIC_MULTI_VALUE_GENRE::false:false"
	"GONIC_MULTI_VALUE_ARTIST::false:false"
	"GONIC_MULTI_VALUE_ALBUM_ARTIST::false:false"
	"GONIC_MULTI_VALUE_ISRC::false:false"

	# cache maintenance
	"GONIC_TRANSCODE_CACHE_SIZE::false:false"
	"GONIC_TRANSCODE_EJECT_INTERVAL::false:false"
	"GONIC_COVER_CACHE_SIZE::false:false"
	"GONIC_COVER_EJECT_INTERVAL::false:false"
	"GONIC_PODCAST_PURGE_AGE::false:false"

	# jukebox
	"GONIC_JUKEBOX_ENABLED::false:false"
	"GONIC_JUKEBOX_MPV_EXTRA_ARGS::false:false"

	# debugging
	"GONIC_EXPVAR::false:false"
	"GONIC_PPROF::false:false"
	"GONIC_LOG_DB::false:false"
)

# process each environment variable
if declare -F process_env_var > /dev/null; then

	for env_var in "${env_vars[@]}"; do
		IFS=':' read -r var_name default_value required mask_value <<< "${env_var}"
		process_env_var "${var_name}" "${default_value}" "${required}" "${mask_value}"
	done

else

	# the scripts repository is not up to date, do not exit as the env vars are
	# still passed through to the app by docker
	echo "[warn] process_env_var function not available, skipping gonic env var processing" | ts '%Y-%m-%d %H:%M:%.S'

fi
EOF

# replace env vars placeholder string with contents of file (here doc)
sed -i '/# ENVVARS_PLACEHOLDER/{
    s/# ENVVARS_PLACEHOLDER//g
    r /tmp/envvars_heredoc
}' /usr/bin/init.sh
rm /tmp/envvars_heredoc

# cleanup
cleanup.sh
