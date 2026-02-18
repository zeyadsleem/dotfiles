import sys
import subprocess
import re
import os
import json

BD_PATH = "/home/zeyad/.local/bin/bd"

def run_bd(args):
    # Try running with --sandbox
    result = subprocess.run([BD_PATH, "--sandbox"] + args, capture_output=True, text=True)
    return result.stdout.strip()

def create_bead(title, desc=""):
    out = run_bd(['create', title, '-d', desc])
    # Fallback to parsing issues.jsonl if bd output is empty/error
    if not out or "Created bead" not in out:
        if os.path.exists(".beads/issues.jsonl"):
            with open(".beads/issues.jsonl", "r") as f:
                last_line = f.readlines()[-1]
                data = json.loads(last_line)
                return str(data.get("id"))
    
    if out:
        match = re.search(r'#(\d+)', out)
        if match:
            return match.group(1)
    return None

def main():
    if len(sys.argv) < 2:
        print("Usage: prd_to_beads.py <prd.md>")
        return

    # Ensure .beads exists
    if not os.path.exists(".beads"):
        os.makedirs(".beads")

    file_path = sys.argv[1]
    with open(file_path, 'r') as f:
        lines = f.readlines()

    epic_id = None
    current_task_id = None

    for line in lines:
        line = line.strip()
        if not line: continue
        
        if line.startswith('# '):
            title = line[2:].strip()
            epic_id = create_bead(title, "Epic")
            print(f"Created Epic: {title} (#{epic_id})")
        elif line.startswith('## '):
            title = line[3:].strip()
            current_task_id = create_bead(title, "Task")
            if epic_id and current_task_id:
                run_bd(['dep', 'add', current_task_id, epic_id])
            print(f"  Created Task: {title} (#{current_task_id})")
        elif line.startswith('- [ ] ') or line.startswith('* ') or line.startswith('- '):
            title = line.replace('- [ ] ', '').replace('* ', '').replace('- ', '').strip()
            sub_id = create_bead(title, "Subtask")
            parent = current_task_id if current_task_id else epic_id
            if parent and sub_id:
                run_bd(['dep', 'add', sub_id, parent])
            print(f"    Created Subtask: {title} (#{sub_id})")

if __name__ == "__main__":
    main()
