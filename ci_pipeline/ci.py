"""Build legacy file maps and one-request-per-role installation bundles."""

import json
import os
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
COMPUTERS = ROOT / "computers"
PIPELINE = ROOT / "cd_pipeline"
RELEASES = ROOT / "releases"
REPOSITORY = "TheCakeOfRice/computercraft"


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


branch = git("branch", "--show-current")
version = git("rev-parse", "--short=12", "HEAD")
base_api = f"https://api.github.com/repos/{REPOSITORY}/contents"
raw_base = f"https://raw.githubusercontent.com/{REPOSITORY}/{branch}"
file_map: dict[str, list[str]] = {}
bundles: dict[str, dict[str, object]] = {}

RELEASES.mkdir(exist_ok=True)

for cpu_dir in sorted(path for path in COMPUTERS.iterdir() if path.is_dir()):
    role = cpu_dir.name
    pipeline_dir = cpu_dir / "_cd_pipeline"
    pipeline_dir.mkdir(exist_ok=True)

    # Retain the old updater files for installations migrating from older builds.
    for source in PIPELINE.glob("*.lua"):
        shutil.copy(source, pipeline_dir / f"_{source.name}")

    files: dict[str, str] = {}
    urls: list[str] = []
    for source in sorted(cpu_dir.rglob("*.lua")):
        relative = source.relative_to(cpu_dir).as_posix()
        files[relative] = source.read_text()
        repo_path = source.relative_to(ROOT).as_posix()
        urls.append(f"{base_api}/{repo_path}?ref={branch}")

    files["install.lua"] = (ROOT / "install.lua").read_text()

    file_map[role] = urls
    bundle = {"version": version, "role": role, "files": files}
    bundles[role] = bundle
    (RELEASES / f"{role}.json").write_text(json.dumps(bundle, separators=(",", ":")))

(ROOT / "ci_pipeline" / "file_map.json").write_text(json.dumps(file_map, indent=4))

manifest = {
    "schema": 1,
    "channels": {
        "stable": {
            "version": version,
            "roles": {
                role: f"{raw_base}/releases/{role}.json" for role in sorted(bundles)
            },
        }
    },
}
(RELEASES / "manifest.json").write_text(json.dumps(manifest, indent=2))
print(f"Built {len(bundles)} role bundles for {branch}@{version}")
