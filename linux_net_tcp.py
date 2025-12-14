#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys
from typing import List, Dict


def process_file(procnet: str) -> List[str]:
    """Extract socket lines, skipping header and trailing newline."""
    lines = procnet.strip().splitlines()
    return [line.strip() for line in lines[1:]]


def split_every_n(data: str, n: int) -> List[str]:
    """Split a string into chunks of size n."""
    return [data[i:i + n] for i in range(0, len(data), n)]


def convert_linux_netaddr(address: str) -> str:
    """Convert Linux hex IP:PORT to dotted-decimal format."""
    hex_addr, hex_port = address.split(':')

    addr_bytes = split_every_n(hex_addr, 2)
    addr_bytes.reverse()

    addr = ".".join(str(int(byte, 16)) for byte in addr_bytes)
    port = str(int(hex_port, 16))

    return f"{addr}:{port}"


def format_line(data: Dict[str, str]) -> str:
    """Format output line."""
    return (
        f"{data['seq']:<4} "
        f"{data['uid']:>5} "
        f"{data['local']:>25} "
        f"{data['remote']:>25} "
        f"{data['timeout']:>8} "
        f"{data['inode']:>8}\n"
    )


def main() -> None:
    with open("/proc/net/tcp", "r", encoding="utf-8") as f:
        sockets = process_file(f.read())

    columns = ("seq", "uid", "inode", "local", "remote", "timeout")
    header = {col: col for col in columns}

    rows = []
    for line in sockets:
        fields = re.split(r"\s+", line)

        row = {
            "seq": fields[0],
            "local": convert_linux_netaddr(fields[1]),
            "remote": convert_linux_netaddr(fields[2]),
            "uid": fields[7],
            "timeout": fields[8],
            "inode": fields[9],
        }
        rows.append(row)

    if rows:
        sys.stderr.write(format_line(header))
        for row in rows:
            sys.stdout.write(format_line(row))


if __name__ == "__main__":
    main()
