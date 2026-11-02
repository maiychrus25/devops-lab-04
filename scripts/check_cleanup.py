import os
from pathlib import Path
import subprocess
import tempfile


root = Path(__file__).resolve().parent.parent
with tempfile.TemporaryDirectory(prefix="lab4-cleanup-check-") as temporary:
    directory = Path(temporary)
    trace = directory / "calls"
    fake_remove = directory / "rm"
    fake_remove.write_text('#!/bin/sh\necho file-remove >> "$LAB4_TEST_TRACE"\n')
    fake_remove.chmod(0o755)
    for scenario in ["offline", "foreign", "late-offline"]:
        trace.write_text("")
        docker = directory / "docker"
        if scenario == "offline":
            body = 'exit 1\n'
        elif scenario == "late-offline":
            body = 'if [ "$1" = info ]; then exit 0; fi\nexit 1\n'
        else:
            body = 'if [ "$1" = info ]; then exit 0; fi\ncase "$*" in *--format*) echo unrelated-owner ;; esac\nexit 0\n'
        docker.write_text('#!/bin/sh\necho "$*" >> "$LAB4_TEST_TRACE"\n' + body)
        docker.chmod(0o755)
        environment = {**os.environ, "PATH": str(directory) + os.pathsep + os.environ["PATH"], "LAB4_TEST_TRACE": str(trace)}
        result = subprocess.run(["bash", "scripts/cleanup.sh"], cwd=root, env=environment, capture_output=True, text=True)
        assert result.returncode != 0, f"Cleanup must stop for {scenario} Docker"
        calls = trace.read_text().splitlines()
        assert not any(line.startswith("rm ") or line == "file-remove" for line in calls)
print("Cleanup safety checks: PASS (offline/late-offline daemon and foreign ownership cause no deletion)")
