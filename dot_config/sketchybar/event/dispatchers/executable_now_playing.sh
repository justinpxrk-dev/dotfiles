#!/usr/bin/env bash

now_playing_artwork_format='null'

# Route triggers to this dispatcher's own bar. sketchybar selects the instance by
# argv[0]; the daemon exports its name as $BAR_NAME, so re-invoke under it — a bare
# `sketchybar` would hit the default instance, not the external bar this serves.
trigger() { (exec -a "${BAR_NAME:?must be set by the sketchybar instance running this dispatcher}" /opt/homebrew/bin/sketchybar "$@"); }

exec media-control stream | while IFS= read -r line; do
	{
		IFS= read -r -d '' diff
		IFS= read -r -d '' playing
		IFS= read -r -d '' artist
		IFS= read -r -d '' bundle_identifier
		IFS= read -r -d '' title
		IFS= read -r -d '' artwork_mime_type
		IFS= read -r -d '' artwork_data
	} < <(
		printf '%s' "$line" |
			jq -j '
				.diff, "\u0000",
				.payload.playing, "\u0000",
				.payload.artist, "\u0000",
				.payload.bundleIdentifier, "\u0000",
				.payload.title, "\u0000",
				.payload.artworkMimeType, "\u0000",
				.payload.artworkData, "\u0000"
			'
	)

	if [[ "$diff" == 'true' ]]; then
		if [[ "$playing" == 'true' ]]; then
			trigger --trigger now_playing_unpause
		elif [[ "$playing" == 'false' ]]; then
			trigger --trigger now_playing_pause
		fi
	elif [[ "$diff" == 'false' ]]; then
		if [[ "$playing" != 'null' ]]; then
			trigger --trigger \
				now_playing_track_change \
				INFO="$(
					jq -nc \
						--arg playing "$playing" \
						--arg artist "$artist" \
						--arg bundle_identifier "$bundle_identifier" \
						--arg title "$title" \
						'{
							playing: $playing,
							artist: $artist,
							bundle_identifier: $bundle_identifier,
							title: $title
						}'
				)"

			if [[ "$artwork_mime_type" != 'null' ]]; then
				now_playing_artwork_format="${artwork_mime_type##*/}"
			fi
		elif [[ "$playing" == 'null' ]]; then
			now_playing_artwork_format='null'
			trigger --trigger now_playing_stop
			continue
		fi
	fi

	if [[ "$artwork_data" != 'null' && "$now_playing_artwork_format" != 'null' ]]; then
		CACHE_DIR="$HOME/.cache/sketchybar/now_playing_artwork"
		mkdir -p "$CACHE_DIR"
		artwork_hash="$(printf '%s' "$artwork_data" | shasum -a 256 | cut -d' ' -f1)"

		artwork_path="$CACHE_DIR/$artwork_hash.$now_playing_artwork_format"
		now_playing_artwork_format='null'
		inactive_artwork_path="$CACHE_DIR/$artwork_hash.inactive.png"

		if [[ ! -f "$artwork_path" ]]; then
			printf '%s' "$artwork_data" |
				base64 -d >"$artwork_path" &&
				magick "$artwork_path" \
					-background none \
					-resize 24x24^ \
					-gravity center \
					-extent 24x24 \
					"$artwork_path" &&
				magick "$artwork_path" \
					-alpha set \
					-channel A \
					-evaluate multiply 0.3 \
					+channel \
					"$inactive_artwork_path"
		fi

		trigger --trigger \
			now_playing_artwork_change \
			INFO="$(
				jq -nc \
					--arg artwork_path "$artwork_path" \
					--arg inactive_artwork_path "$inactive_artwork_path" \
					'{
						artwork_path: $artwork_path,
						inactive_artwork_path: $inactive_artwork_path
					}'
			)"
	fi
done
