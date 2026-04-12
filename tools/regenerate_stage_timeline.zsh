#!/bin/zsh

set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
project_dir="$(find "$project_root" -maxdepth 1 -type d -name "Selkie*" | head -n 1)"
if [[ -z "$project_dir" ]]; then
    echo "Could not locate GameMaker project directory." >&2
    exit 1
fi

timeline_dir="$project_dir/timelines/tml_stage"
stage_length="$(
    sed -n 's/^#macro STAGE_LENGTH_FRAMES //p' "$project_dir/scripts/scr_gameplay_helpers/scr_gameplay_helpers.gml" | head -n 1
)"

if [[ -z "$stage_length" ]]; then
    echo "Could not determine STAGE_LENGTH_FRAMES." >&2
    exit 1
fi

find "$timeline_dir" -maxdepth 1 -name 'moment_*.gml' -delete
moment_numbers=()

write_moment_line() {
    local file="$1"
    local line="$2"

    if [[ ! -f "$file" ]]; then
        printf "%s\n" "// Spawn the scheduled stage wave for this timeline moment." > "$file"
    fi

    printf "%s\n" "$line" >> "$file"
}

for (( moment = 90; moment < stage_length; moment += 90 )); do
    moment_numbers+=("$moment")
    write_moment_line "$timeline_dir/moment_${moment}.gml" \
        "GameStageTimelineTurretSpawn(scene_state.target_x, scene_state.camera_y);"
done

for (( moment = 145; moment < stage_length; moment += 145 )); do
    moment_numbers+=("$moment")
    write_moment_line "$timeline_dir/moment_${moment}.gml" \
        "GameStageTimelineBeeWaveSpawn(scene_state.target_x, scene_state.camera_y);"
done

for (( moment = 357; moment < stage_length; moment += 357 )); do
    moment_numbers+=("$moment")
    write_moment_line "$timeline_dir/moment_${moment}.gml" \
        "GameStageTimelineMayflySpawn(scene_state.target_x, scene_state.camera_y);"
done

sorted_moments=("${(@f)$(printf "%s\n" "${moment_numbers[@]}" | sort -n | uniq)}")

{
    printf "%s\n" "{"
    printf "%s\n" "  \"\$GMTimeline\":\"\","
    printf "%s\n" "  \"%Name\":\"tml_stage\","
    printf "%s\n" "  \"momentList\":["

    local first=1
    for moment in "${sorted_moments[@]}"; do
        if (( ! first )); then
            printf "%s\n" ","
        fi

        printf "    {\"\$GMMoment\":\"\",\"%%Name\":\"\",\"evnt\":{\"\$GMEvent\":\"v1\",\"%%Name\":\"\",\"collisionObjectId\":null,\"eventNum\":%d,\"eventType\":0,\"isDnD\":false,\"name\":\"\",\"resourceType\":\"GMEvent\",\"resourceVersion\":\"2.0\",},\"moment\":%d,\"name\":\"\",\"resourceType\":\"GMMoment\",\"resourceVersion\":\"2.0\",}" "$moment" "$moment"
        first=0
    done

    printf "\n"
    printf "%s\n" "  ],"
    printf "%s\n" "  \"name\":\"tml_stage\","
    printf "%s\n" "  \"parent\":{"
    printf "%s\n" "    \"name\":\"stage\","
    printf "%s\n" "    \"path\":\"folders/stage.yy\","
    printf "%s\n" "  },"
    printf "%s\n" "  \"resourceType\":\"GMTimeline\","
    printf "%s\n" "  \"resourceVersion\":\"2.0\","
    printf "%s\n" "}"
} > "$timeline_dir/tml_stage.yy"
