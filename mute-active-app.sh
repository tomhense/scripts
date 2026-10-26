#!/usr/bin/env bash
set -euo pipefail

for cmd in kdotool pactl jq; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		printf 'Error: required command not found: %s\n' "$cmd" >&2
		exit 1
	fi
done

active_pid=$(kdotool getactivewindow getwindowpid)
if [[ -z $active_pid ]]; then
	printf 'Error: could not determine the active window PID.\n' >&2
	exit 1
fi

# Match sink inputs to their client records using the sink input's client ID
# and the client's index. Select the first whose application or PipeWire
# security PID matches the active window PID, then output its sink-input index.
sink_input=$(
	jq -nr --arg pid "$active_pid" \
		--slurpfile inputs <(pactl --format=json list sink-inputs) \
		--slurpfile clients <(pactl --format=json list clients) '
		[
			$inputs[0][] as $input
			| $clients[0][]
			| select((.index | tostring) == $input.client)
			| select(
				.properties["application.process.id"] == $pid
				or .properties["pipewire.sec.pid"] == $pid
			)
			| $input.index
		]
		| .[0] // empty
	'
)

if [[ -z $sink_input ]]; then
	printf 'No sink input found for active window PID %s\n' "$active_pid"
	exit 0
fi

pactl set-sink-input-mute "$sink_input" toggle
printf 'Toggled mute for sink input %s (PID %s)\n' "$sink_input" "$active_pid"
