import csv
import re
import sys
from os.path import basename

rows = []
cur = None

with open(sys.argv[1]) as f:
    for line in f:
        line = line.rstrip("\n")
        if line.startswith("Running: "):
            cur = {"name": basename(line.split(" ", 1)[1]), "count": 0,
                   "cpu": [], "gpu": [], "Cleanup": "", "Initialize": "", "Run": "", "WarmUp": ""}
            rows.append(cur)
        elif line.startswith("Warning: "):
            if cur is not None and cur["count"] == 0 and cur["Run"] == "":
                rows.pop()
            cur = {"name": basename(line.split()[1]), "count": 0,
                   "cpu": [], "gpu": [], "Cleanup": "", "Initialize": "", "Run": "", "WarmUp": ""}
            rows.append(cur)
            cur = None
        elif cur is not None:
            m = re.match(r"CPU: ([^,]+), GPU: ([^,]+), both: \d+", line)
            if m:
                cur["count"] += 1
                cur["cpu"].append(m.group(1))
                cur["gpu"].append(m.group(2))
            m = re.match(r"\s+(Cleanup|Initialize|Run|WarmUp): (\S+) second", line)
            if m:
                cur[m.group(1)] = m.group(2)

w = csv.writer(sys.stdout, lineterminator="\n")
w.writerow(["name", "run", "count", "cpu_1", "cpu_2", "gpu_1", "gpu_2",
            "cleanup", "initialize", "warmup"])
for r in rows:
    w.writerow([r["name"], r["Run"], r["count"],
                r["cpu"][0] if r["cpu"] else "", r["cpu"][-1] if r["cpu"] else "",
                r["gpu"][0] if r["gpu"] else "", r["gpu"][-1] if r["gpu"] else "",
                r["Cleanup"], r["Initialize"], r["WarmUp"]])
