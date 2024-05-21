#!/bin/bash

# exit script if return code != 0
set -e

# release tag name from buildx arg, stripped of build ver using string manipulation
RELEASETAG="${1//-[0-9][0-9]/}"

# target arch from buildx arg
TARGETARCH="${2}"

if [[ -z "${RELEASETAG}" ]]; then
	echo "[warn] Release tag name from build arg is empty, exiting script..."
	exit 1
fi

if [[ -z "${TARGETARCH}" ]]; then
	echo "[warn] Target architecture name from build arg is empty, exiting script..."
	exit 1
fi

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /usr/local/bin/


# pacman packages
####

# define pacman packages
pacman_packages=""

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aur packages
####

# define aur packages
aur_packages="gonic"

# call aur install script (arch user repo)
source aur.sh

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

# create file with contents of here doc, note EOF is NOT quoted to allow us to expand current variable 'install_paths'
# we use escaping to prevent variable expansion for PUID and PGID, as we want these expanded at runtime of init.sh
cat <<EOF > /tmp/permissions_heredoc

# get previous puid/pgid (if first run then will be empty string)
previous_puid=\$(cat "/root/puid" 2>/dev/null || true)
previous_pgid=\$(cat "/root/pgid" 2>/dev/null || true)

# if first run (no puid or pgid files in /tmp) or the PUID or PGID env vars are different
# from the previous run then re-apply chown with current PUID and PGID values.
if [[ ! -f "/root/puid" || ! -f "/root/pgid" || "\${previous_puid}" != "\${PUID}" || "\${previous_pgid}" != "\${PGID}" ]]; then

	# set permissions inside container - Do NOT double quote variable for install_paths otherwise this will wrap space separated paths as a single string
	chown -R "\${PUID}":"\${PGID}" ${install_paths}

fi

# write out current PUID and PGID to files in /root (used to compare on next run)
echo "\${PUID}" > /root/puid
echo "\${PGID}" > /root/pgid

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /usr/local/bin/init.sh
rm /tmp/permissions_heredoc

# env vars
####

cat <<'EOF' > /tmp/envvars_heredoc

export GONIC_MUSIC_PATH=$(echo "${GONIC_MUSIC_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${GONIC_MUSIC_PATH}" ]]; then
	echo "[info] GONIC_MUSIC_PATH defined as '${GONIC_MUSIC_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] GONIC_MUSIC_PATH not defined,(via -e GONIC_MUSIC_PATH), defaulting to '/config/music'" | ts '%Y-%m-%d %H:%M:%.S'
	export GONIC_MUSIC_PATH="/config/music"
fi

export GONIC_PODCAST_PATH=$(echo "${GONIC_PODCAST_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${GONIC_PODCAST_PATH}" ]]; then
	echo "[info] GONIC_PODCAST_PATH defined as '${GONIC_PODCAST_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] GONIC_PODCAST_PATH not defined,(via -e GONIC_PODCAST_PATH), defaulting to '/config/podcasts'" | ts '%Y-%m-%d %H:%M:%.S'
	export GONIC_PODCAST_PATH="/config/podcasts"
fi

export GONIC_PLAYLISTS_PATH=$(echo "${GONIC_PLAYLISTS_PATH}" | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${GONIC_PLAYLISTS_PATH}" ]]; then
	echo "[info] GONIC_PLAYLISTS_PATH defined as '${GONIC_PLAYLISTS_PATH}'" | ts '%Y-%m-%d %H:%M:%.S'
else
	echo "[info] GONIC_PLAYLISTS_PATH not defined,(via -e GONIC_PLAYLISTS_PATH), defaulting to '/config/playlists'" | ts '%Y-%m-%d %H:%M:%.S'
	export GONIC_PLAYLISTS_PATH="/config/playlists"
fi

EOF

# cleanup
cleanup.sh