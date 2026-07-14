#!/bin/zsh

# Build an isolated project copy and run the GMTL suite with retries for the
# GameMaker asset compiler's intermittent macOS access violations.
set -euo pipefail

script_dir=$(cd -- "$(dirname "$0")" && pwd)
repo_root=$(cd -- "$script_dir/.." && pwd)
source_project_dir="$repo_root/Selkie's Moon ~ until we meet again ~"
test_project_parent="$repo_root/output/gmtl-project"
project_dir="$test_project_parent/Selkie's Moon ~ until we meet again ~"
project_file="$project_dir/Selkies Moon.yyp"
output_dir="$repo_root/output/Selkies Moon"
marker_file="$output_dir/.run-gmtl-tests.txt"
results_dir="$repo_root/test-results"
run_log="$results_dir/gmtl-run.log"
build_log="$results_dir/gmtl-build.log"
remote_install_dir="$HOME/gamemakerstudio2/GM_MAC/Selkies_Moon"

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
    print -u2 "No GameMaker runtime found in /Users/Shared/GameMakerStudio2-LTS2026/Cache/runtimes or /Users/Shared/GameMakerStudio2/Cache/runtimes."
    exit 1
fi

gm_user_dir=""
for user_root in \
    "$HOME/Library/Application Support/GameMakerStudio2-LTS2026" \
    "$HOME/Library/Application Support/GameMakerStudio2"; do
    [[ -d "$user_root" ]] || continue
    for candidate in "$user_root"/*(N); do
        [[ -d "$candidate" ]] || continue
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

runner_bin="$runtime_dir/mac/YoYo Runner.app/Contents/MacOS/Mac_Runner"
if [[ ! -x "$runner_bin" ]]; then
    print -u2 "Mac runner is missing at $runner_bin."
    exit 1
fi

mkdir -p "$results_dir"
mkdir -p "$output_dir"
mkdir -p "$remote_install_dir"
rm -rf "$test_project_parent"
mkdir -p "$test_project_parent"
rsync -a --delete --exclude='.DS_Store' "$source_project_dir/" "$project_dir/"
find "$project_dir/options" -mindepth 1 -maxdepth 1 -type d ! -name main -exec rm -rf {} +
: > "$marker_file"
: > "$run_log"
: > "$build_log"

cleanup() {
    rm -f "$marker_file"
}

trap cleanup EXIT INT TERM

max_attempts=${GMTL_TEST_ATTEMPTS:-6}
attempt=1
igor_status=0
runner_status=0
suite_summary=""
test_summary=""

while (( attempt <= max_attempts )); do
    rm -f "$output_dir/game.ios" "$output_dir/debug.log"
    print "GMTL build attempt $attempt of $max_attempts" | tee -a "$run_log" "$build_log"

    set +e
    "$igor_bin" mac Run \
        -j=1 \
        --runtimePath="$runtime_dir" \
        --runtime=VM \
        --project="$project_file" \
        --user="$gm_user_dir" \
        --licencefile="$gm_user_dir/licence.plist" \
        --assetCompiler=--sdlm | tee -a "$build_log" "$run_log"
    igor_status=${pipestatus[1]}
    set -e

    suite_summary=$(grep "Test Suites:" "$run_log" | tail -n 1 || true)
    test_summary=$(grep "Tests:" "$run_log" | tail -n 1 || true)

    if [[ -n "$suite_summary" && -n "$test_summary" ]]; then
        break
    fi

    game_size=0
    if [[ -f "$output_dir/game.ios" ]]; then
        game_size=$(stat -f %z "$output_dir/game.ios")
    fi

    if (( game_size > 1048576 )); then
        print "Igor did not produce GMTL summaries; launching built runner directly." | tee -a "$run_log"

        set +e
        (
            cd "$output_dir"
            "$runner_bin" \
                -game "$output_dir/game.ios" \
                -debugoutput "$output_dir/debug.log" \
                -output "$output_dir/debug.log" \
                -runTest
        ) | tee -a "$run_log"
        runner_status=${pipestatus[1]}
        set -e

        if [[ -f "$output_dir/debug.log" ]]; then
            cat "$output_dir/debug.log" >> "$run_log"
        fi

        suite_summary=$(grep "Test Suites:" "$run_log" | tail -n 1 || true)
        test_summary=$(grep "Tests:" "$run_log" | tail -n 1 || true)

        if [[ -n "$suite_summary" && -n "$test_summary" ]]; then
            break
        fi

        if (( runner_status != 134 && runner_status != 139 )); then
            print -u2 "Direct runner exited with status $runner_status."
            exit "$runner_status"
        fi
    elif (( igor_status != 134 && igor_status != 139 )); then
        print -u2 "Igor exited with status $igor_status and did not produce a usable $output_dir/game.ios."
        exit "$igor_status"
    fi

    if (( attempt >= max_attempts )); then
        break
    fi

    print "GameMaker crashed before GMTL summaries; retrying." | tee -a "$run_log" "$build_log"
    attempt=$((attempt + 1))
done

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
