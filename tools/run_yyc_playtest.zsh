#!/bin/zsh

# Build the current checkout as an isolated native macOS YYC app. GameMaker's
# LTS asset loader is intermittently unstable on this project, so emission is
# retried before the generated Xcode project is compiled directly.
set -euo pipefail

script_dir=$(cd -- "$(dirname "$0")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
source_project_dir=${YYC_SOURCE_PROJECT_DIR:-"$repo_root/Selkie's Moon ~ until we meet again ~"}
playtest_project_parent="$repo_root/output/yyc-playtest-project"
project_dir="$playtest_project_parent/Selkie's Moon ~ until we meet again ~"
project_file="$project_dir/Selkies Moon.yyp"
output_dir=${YYC_OUTPUT_DIR:-"$repo_root/output/Selkies Moon"}
generated_project_dir="$output_dir/gamemakerstudio_game"
xcode_project="$generated_project_dir/gamemakerstudio_game.xcodeproj"
derived_data="$generated_project_dir/DerivedData"
app_path="$derived_data/Build/Products/Release/gamemakerstudio_game.app"
build_log=${YYC_BUILD_LOG:-"$repo_root/test-results/yyc-build.log"}
source_icon="$source_project_dir/sprites/spr_logo/7c0dfe86-a547-4d6b-a9ae-6e9cabcb8103.png"

runtime_dir=""
for runtime_root in \
    /Users/Shared/GameMakerStudio2-LTS2026/Cache/runtimes \
    /Users/Shared/GameMakerStudio2/Cache/runtimes; do
    [[ -d "$runtime_root" ]] || continue
    for candidate in "$runtime_root"/runtime-*(N); do
        [[ -d "$candidate" ]] || continue
        runtime_dir="$candidate"
    done
done

if [[ -z "$runtime_dir" ]]; then
    print -u2 "No GameMaker runtime was found."
    exit 1
fi

gm_user_dir=""
for user_root in \
    "$HOME/Library/Application Support/GameMakerStudio2-LTS2026" \
    "$HOME/Library/Application Support/GameMakerStudio2"; do
    [[ -d "$user_root" ]] || continue
    for candidate in "$user_root"/*(N); do
        [[ -f "$candidate/licence.plist" ]] || continue
        gm_user_dir="$candidate"
        break
    done
    [[ -n "$gm_user_dir" ]] && break
done

if [[ -z "$gm_user_dir" ]]; then
    print -u2 "No GameMaker user directory with licence.plist was found."
    exit 1
fi

igor_bin=""
for candidate in \
    "$runtime_dir/bin/igor/osx/arm64/Igor" \
    "$runtime_dir/bin/igor/osx/x64/Igor" \
    "$runtime_dir/bin/Igor"; do
    [[ -x "$candidate" ]] || continue
    igor_bin="$candidate"
    break
done

if [[ -z "$igor_bin" ]]; then
    print -u2 "Igor is missing under $runtime_dir/bin."
    exit 1
fi

if [[ ! -d /Applications/Xcode.app/Contents/Developer ]]; then
    print -u2 "A complete Xcode install is required at /Applications/Xcode.app."
    exit 1
fi

if [[ ! -f "$source_icon" ]]; then
    print -u2 "The source logo is missing at $source_icon."
    exit 1
fi

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

mkdir -p "$repo_root/test-results"
rm -rf "$playtest_project_parent" "$output_dir" "$repo_root/cache/Selkies Moon"
mkdir -p "$playtest_project_parent"
rsync -a --delete --exclude=.DS_Store "$source_project_dir/" "$project_dir/"

# LTS Igor tries to parse every platform options file even for a macOS build.
# Keep only the options that this isolated build actually consumes.
find "$project_dir/options" -mindepth 1 -maxdepth 1 -type d \
    ! -name main ! -name mac -exec rm -rf {} +

: > "$build_log"
max_attempts=${YYC_BUILD_ATTEMPTS:-16}
attempt=1

while (( attempt <= max_attempts )); do
    print "YYC emission attempt $attempt of $max_attempts" | tee -a "$build_log"

    # The LTS wrapper expects these paths before it has reliably created them.
    mkdir -p "$output_dir/Selkies_Moon"
    : > "$output_dir/Selkies_Moon/__yy_certificate.xcconfg"
    mkdir -p "$HOME/gamemakerstudio2/GM_MAC/Selkies_Moon/Selkies_MoonFromPC/Selkies_Moon/Supporting Files"

    set +e
    "$igor_bin" mac Run \
        -j=1 \
        --runtimePath="$runtime_dir" \
        --runtime=YYC \
        --project="$project_file" \
        --user="$gm_user_dir" \
        --licencefile="$gm_user_dir/licence.plist" \
        --assetCompiler=--sdlm 2>&1 | tee -a "$build_log"
    igor_status=${pipestatus[1]}
    set -e

    if [[ -d "$xcode_project" ]]; then
        break
    fi

    if (( igor_status != 0 && igor_status != 1 && igor_status != 134 && igor_status != 139 )); then
        print -u2 "Igor exited with non-retryable status $igor_status."
        exit "$igor_status"
    fi

    sleep 0.25
    attempt=$((attempt + 1))
done

if [[ ! -d "$xcode_project" ]]; then
    print -u2 "GameMaker did not emit an Xcode project after $max_attempts attempts."
    exit 1
fi

# Build the ICNS ourselves. The LTS wrapper can invoke iconutil before its
# destination exists, and its fallback art is not the game's icon.
iconset_dir="$output_dir/SelkiesMoon.iconset"
icon_file="$output_dir/SelkiesMoon.icns"
rm -rf "$iconset_dir"
mkdir -p "$iconset_dir"

sips -z 16 16 "$source_icon" --out "$iconset_dir/icon_16x16.png" >/dev/null
sips -z 32 32 "$source_icon" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "$source_icon" --out "$iconset_dir/icon_32x32.png" >/dev/null
sips -z 64 64 "$source_icon" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "$source_icon" --out "$iconset_dir/icon_128x128.png" >/dev/null
sips -z 256 256 "$source_icon" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$source_icon" --out "$iconset_dir/icon_256x256.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$source_icon" --out "$iconset_dir/icon_512x512.png" >/dev/null
sips -z 1024 1024 "$source_icon" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null
/usr/bin/iconutil -c icns "$iconset_dir" -o "$icon_file"
cp "$icon_file" "$generated_project_dir/gamemakerstudio_game/Supporting Files/icon.icns"

# Local playtests still need a complete bundle seal. Ad-hoc signing avoids a
# login-keychain prompt (and therefore keeps working behind the screen lock),
# while release automation can opt into a Developer ID identity and team.
signing_allowed=${YYC_CODE_SIGNING_ALLOWED:-YES}
signing_identity=${YYC_CODE_SIGN_IDENTITY:--}
development_team=${YYC_DEVELOPMENT_TEAM:-}
xcodebuild -quiet \
    -project "$xcode_project" \
    -scheme gamemakerstudio_game \
    -configuration Release \
    -derivedDataPath "$derived_data" \
    CODE_SIGNING_ALLOWED="$signing_allowed" \
    CODE_SIGN_IDENTITY="$signing_identity" \
    DEVELOPMENT_TEAM="$development_team" \
    PRODUCT_BUNDLE_IDENTIFIER=com.tinyleaf.selkiesmoon \
    build 2>&1 | tee -a "$build_log"

if [[ ! -d "$app_path" ]]; then
    print -u2 "Xcode reported success but did not create $app_path."
    exit 1
fi

print "YYC app: $app_path"

if [[ ${YYC_NO_RUN:-0} != 1 ]]; then
    open -n "$app_path"
fi
