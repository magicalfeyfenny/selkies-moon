#!/bin/zsh

set -euo pipefail

script_dir=$(cd -- "$(dirname "$0")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
project_dir="$repo_root/Selkie's Moon ~ until we meet again ~"
project_file="$project_dir/Selkie's Moon ~ until we meet again ~.yyp"
marker_file="$project_dir/.run-gmtl-tests.txt"
results_dir="$repo_root/test-results"
run_log="$results_dir/gmtl-run.log"
remote_install_dir="$HOME/gamemakerstudio2/GM_MAC/Selkie_s_Moon_~_until_we_meet_again_~"

runtime_dir=""
for candidate in /Users/Shared/GameMakerStudio2/Cache/runtimes/runtime-*; do
    [[ -d "$candidate" ]] || continue
    runtime_dir="$candidate"
done

if [[ -z "$runtime_dir" ]]; then
    print -u2 "No GameMaker runtime found in /Users/Shared/GameMakerStudio2/Cache/runtimes."
    exit 1
fi

gm_user_dir=""
for candidate in "$HOME/Library/Application Support/GameMakerStudio2"/*; do
    [[ -d "$candidate" ]] || continue
    [[ -f "$candidate/licence.plist" ]] || continue
    gm_user_dir="$candidate"
    break
done

if [[ -z "$gm_user_dir" ]]; then
    print -u2 "No GameMaker user directory with licence.plist was found."
    exit 1
fi

igor_bin="$runtime_dir/bin/igor/osx/arm64/Igor"
runtime_name="${runtime_dir:t}"

if [[ ! -x "$igor_bin" ]]; then
    print -u2 "Igor is missing at $igor_bin."
    exit 1
fi

mkdir -p "$results_dir"
mkdir -p "$remote_install_dir"
: > "$marker_file"

cleanup() {
    rm -f "$marker_file"
}

trap cleanup EXIT INT TERM

set +e
"$igor_bin" mac Run \
    --runtimePath="$runtime_dir" \
    --runtime="$runtime_name" \
    --project="$project_file" \
    --user="$gm_user_dir" \
    --licencefile="$gm_user_dir/licence.plist" | tee "$run_log"
igor_status=${pipestatus[1]}
set -e

if (( igor_status != 0 )); then
    print -u2 "Igor exited with status $igor_status."
    exit "$igor_status"
fi

suite_summary=$(grep "Test Suites:" "$run_log" | tail -n 1 || true)
test_summary=$(grep "Tests:" "$run_log" | tail -n 1 || true)

if [[ -z "$suite_summary" || -z "$test_summary" ]]; then
    print -u2 "GMTL summary lines were not found in $run_log."
    exit 1
fi

print "$suite_summary"
print "$test_summary"

if [[ "$test_summary" == *" 0 total."* ]]; then
    print -u2 "GMTL reported zero tests."
    exit 1
fi

if [[ "$suite_summary" == *" failed, "* || "$test_summary" == *" failed, "* ]]; then
    print -u2 "GMTL reported failing tests."
    exit 1
fi
