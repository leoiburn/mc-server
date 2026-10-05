#!/usr/bin/env python3
"""Minecraft Server List Ping. Prints version + MOTD + players, or exits nonzero."""
import json, socket, struct, sys


def varint(n):
    out = b""
    while True:
        b = n & 0x7F
        n >>= 7
        out += struct.pack("B", b | (0x80 if n else 0))
        if not n:
            return out


def read_varint(sock):
    n = shift = 0
    while True:
        b = sock.recv(1)[0]
        n |= (b & 0x7F) << shift
        if not b & 0x80:
            return n
        shift += 7


def ping(host, port, timeout=8):
    with socket.create_connection((host, port), timeout) as s:
        addr = host.encode()
        hs = b"\x00" + varint(763) + varint(len(addr)) + addr + struct.pack(">H", port) + b"\x01"
        s.sendall(varint(len(hs)) + hs)
        s.sendall(varint(1) + b"\x00")  # status request
        read_varint(s)  # packet length
        assert read_varint(s) == 0, "unexpected packet id"
        n = read_varint(s)
        buf = b""
        while len(buf) < n:
            chunk = s.recv(n - len(buf))
            if not chunk:
                raise EOFError("server closed mid-response")
            buf += chunk
        return json.loads(buf.decode("utf-8"))


def demo():
    assert varint(0) == b"\x00"
    assert varint(1) == b"\x01"
    assert varint(300) == b"\xac\x02"
    print("varint ok")


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]:
        demo()
        sys.exit(0)
    host = sys.argv[1]
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 25565
    d = ping(host, port)
    motd = d.get("description")
    if isinstance(motd, dict):
        motd = motd.get("text") or "".join(e.get("text", "") for e in motd.get("extra", []))
    print(f"version : {d['version']['name']}  (protocol {d['version']['protocol']})")
    print(f"motd    : {motd}")
    print(f"players : {d['players']['online']}/{d['players']['max']}")
