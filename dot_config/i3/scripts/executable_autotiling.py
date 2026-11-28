#!/usr/bin/env python3
"""Zero-dependency dynamic autotiling daemon for i3 using raw i3 IPC."""
import json
import os
import socket
import struct
import subprocess

MAGIC = b"i3-ipc"
HDR_FMT = "<6sII"
HDR_SIZE = struct.calcsize(HDR_FMT)

RUN_COMMAND = 0
SUBSCRIBE = 2
GET_TREE = 4


def get_socket_path() -> str:
    sock = os.environ.get("I3SOCK")
    if sock and os.path.exists(sock):
        return sock
    return subprocess.check_output(["i3", "--get-socketpath"], text=True).strip()


def send_msg(conn: socket.socket, msg_type: int, payload: bytes = b"") -> None:
    conn.sendall(struct.pack(HDR_FMT, MAGIC, len(payload), msg_type) + payload)


def recv_msg(conn: socket.socket) -> tuple[int, bytes]:
    hdr = b""
    while len(hdr) < HDR_SIZE:
        chunk = conn.recv(HDR_SIZE - len(hdr))
        if not chunk:
            raise EOFError("i3 IPC socket closed")
        hdr += chunk
    magic, length, msg_type = struct.unpack(HDR_FMT, hdr)
    if magic != MAGIC:
        raise ValueError("Invalid i3 IPC magic")
    body = b""
    while len(body) < length:
        chunk = conn.recv(length - len(body))
        if not chunk:
            raise EOFError("i3 IPC socket closed")
        body += chunk
    return msg_type, body


def rpc(sock_path: str, msg_type: int, payload: bytes = b"") -> object:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as c:
        c.connect(sock_path)
        send_msg(c, msg_type, payload)
        _, body = recv_msg(c)
        return json.loads(body.decode("utf-8"))


def find_focused(node: dict, parent: dict | None = None) -> tuple[dict | None, dict | None]:
    if node.get("focused"):
        return node, parent
    for child in node.get("nodes", []) + node.get("floating_nodes", []):
        res = find_focused(child, node)
        if res[0] is not None:
            return res
    return None, None


def main() -> int:
    try:
        sock_path = get_socket_path()
    except Exception:
        return 1

    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sub:
        sub.connect(sock_path)
        send_msg(sub, SUBSCRIBE, b'["window"]')
        _, ack = recv_msg(sub)
        if not json.loads(ack).get("success"):
            return 1

        while True:
            try:
                _, body = recv_msg(sub)
            except (EOFError, OSError):
                break
            ev = json.loads(body.decode("utf-8"))
            if ev.get("change") not in ("focus", "new"):
                continue
            try:
                tree = rpc(sock_path, GET_TREE)
            except OSError:
                break
            focused, parent = find_focused(tree)
            if not focused or not parent:
                continue
            if focused.get("floating") in ("user_on", "auto_on") or focused.get("fullscreen_mode", 0) != 0:
                continue
            if parent.get("layout") in ("tabbed", "stacked"):
                continue
            rect = focused.get("rect", {})
            w, h = rect.get("width", 0), rect.get("height", 0)
            if w <= 0 or h <= 0:
                continue
            cmd = b"split vertical" if h > w else b"split horizontal"
            try:
                rpc(sock_path, RUN_COMMAND, cmd)
            except OSError:
                break
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
