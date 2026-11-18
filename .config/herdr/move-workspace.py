#!/usr/bin/python3
# Move the current herdr workspace up or down one row in the sidebar, among its siblings - the other worktrees of its
# repo for a worktree, the top-level rows otherwise.
import json
import os
import socket
import subprocess
import sys


def main():
    direction = sys.argv[1] if len(sys.argv) > 1 else ""
    if direction not in ("up", "down"):
        sys.exit("usage: move-workspace.py up|down")

    workspaces = json.loads(subprocess.check_output(["herdr", "workspace", "list"]))["result"]["workspaces"]
    rows = get_sidebar_rows(workspaces)
    moved = move_workspace(rows, os.environ["HERDR_ACTIVE_WORKSPACE_ID"], -1 if direction == "up" else 1)
    if moved:
        write_order([workspace_id for row in rows for workspace_id in row["parents"] + row["children"]])


# The sidebar's top-level rows, the way herdr draws them: a repo with both its main checkout and a linked worktree open
# is one block, drawn where its first member sits in herdr's list, with every main-checkout workspace as a parent and
# every worktree beneath them. Everything else is a row of its own.
def get_sidebar_rows(workspaces):
    members_by_repo = {}
    for workspace in workspaces:
        worktree = workspace.get("worktree")
        if worktree:
            members_by_repo.setdefault(worktree["repo_key"], []).append(workspace)

    grouped_repos = {
        repo_key
        for repo_key, members in members_by_repo.items()
        if any(member["worktree"]["is_linked_worktree"] for member in members)
        and not all(member["worktree"]["is_linked_worktree"] for member in members)
    }

    rows = []
    rows_by_repo = {}
    for workspace in workspaces:
        worktree = workspace.get("worktree")
        if not worktree or worktree["repo_key"] not in grouped_repos:
            rows.append({"parents": [workspace["workspace_id"]], "children": []})
            continue

        row = rows_by_repo.get(worktree["repo_key"])
        if not row:
            row = {"parents": [], "children": []}
            rows_by_repo[worktree["repo_key"]] = row
            rows.append(row)
        row["children" if worktree["is_linked_worktree"] else "parents"].append(workspace["workspace_id"])
    return rows


# Moves the workspace one place within the rows, in place, and returns whether anything moved.
def move_workspace(rows, workspace_id, offset):
    row_index = next(index for index, row in enumerate(rows) if workspace_id in row["parents"] + row["children"])
    row = rows[row_index]

    if workspace_id in row["children"]:
        return swap(row["children"], row["children"].index(workspace_id), offset)

    # A group's parents are always drawn together, so a parent swaps with the one beside it, and only one at the edge of
    # the group takes the whole group past the next row.
    if swap(row["parents"], row["parents"].index(workspace_id), offset):
        return True
    return swap(rows, row_index, offset)


def swap(items, index, offset):
    target = index + offset
    if target < 0 or target >= len(items):
        return False

    items[index], items[target] = items[target], items[index]
    return True


# The herdr CLI has no move command, so this goes straight to its socket. Moving every workspace as one block, with no
# anchor, sets the whole order at once.
def write_order(workspace_ids):
    request = {
        "id": "move-workspace",
        "method": "workspace.move_block",
        "params": {"workspace_ids": workspace_ids, "before_workspace_id": None},
    }
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.connect(os.environ["HERDR_SOCKET_PATH"])
        connection.sendall((json.dumps(request) + "\n").encode())
        response = json.loads(connection.makefile().readline())
    if "error" in response:
        sys.exit(response["error"].get("message", "move failed"))


main()
