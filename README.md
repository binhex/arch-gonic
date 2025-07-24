# Application

[Gonic website](https://github.com/sentriz/gonic)

## Description

Free-software subsonic server API implementation, supporting its many clients.

## Build notes

Latest stable Gonic release from Arch User Repository (AUR).

## Usage

```bash
docker run -d \
    -p 4747:4747 \
    --name=<container name> \
    -v <path for media files>:/media \
    -v <path for config files>:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e GONIC_MUSIC_PATH=<path to music files> \
    -e GONIC_PODCAST_PATH=<path to podcast files> \
    -e GONIC_PLAYLISTS_PATH=<path to playlist files> \
    -e HEALTHCHECK_COMMAND=<command> \
    -e HEALTHCHECK_ACTION=<action> \
    -e UMASK=<umask for created files> \
    -e PUID=<UID for user> \
    -e PGID=<GID for user> \
    binhex/arch-gonic
```

Please replace all user variables in the above command defined by <> with the
correct values.

## Access application

`http://<host ip>:4747`

Default username/password: `admin/admin`

## Example

```bash
docker run -d \
    -p 4747:4747 \
    --name=gonic \
    -v /media/music:/media \
    -v /apps/docker/gonic:/config \
    -v /etc/localtime:/etc/localtime:ro \
    -e GONIC_MUSIC_PATH='/media' \
    -e GONIC_PODCAST_PATH='/config/gonic/podcasts' \
    -e GONIC_PLAYLISTS_PATH='/config/gonic/playlists' \
    -e UMASK=000 \
    -e PUID=0 \
    -e PGID=0 \
    binhex/arch-gonic
```

## Notes

User ID (PUID) and Group ID (PGID) can be found by issuing the following command
for the user you want to run the container as:-

```bash
id <username>
```

___
If you appreciate my work, then please consider buying me a beer  :D

[![PayPal donation](https://www.paypal.com/en_US/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=MM5E27UX6AUU4)

[Documentation](https://github.com/binhex/documentation) | [Support forum](https://forums.unraid.nets/topic/64638-support-binhex-nzbhydra2/)
