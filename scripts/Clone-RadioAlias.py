#!/usr/bin/env python3
"""Clone stock mx_game_over into a dedicated mx_nr_stones alias fastfile.

OAT cannot author T4 snd_alias_list_t from CSV. The working path is:

1. Link a tiny donor FF that copies stock mx_game_over from nazi_zombie_prototype.ff
2. Same-length patch mx_game_over -> mx_nr_stones (both 12 chars; wav names both 16)
3. Main mod link -l's nr_radio.ff and includes sound,mx_nr_stones so the alias
   lands in mod.ff without hijacking game-over.

Streamed audio is NOT in the FF; Install.ps1 must copy the loose WAV.
"""
from __future__ import annotations

import argparse
import shutil
import struct
import subprocess
import sys
import zlib
from pathlib import Path

DONOR_ALIAS = b"mx_game_over"
TARGET_ALIAS = b"mx_nr_stones"
DONOR_WAV = b"mx_game_over.wav"
TARGET_WAV = b"mx_nr_stones.wav"
CHUNK = 0x10000
FF_HEADER_LEN = 12


def _die(msg: str, code: int = 1) -> None:
    print(f"Clone-RadioAlias: {msg}", file=sys.stderr)
    raise SystemExit(code)


def write_zone(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(">game,T4\nsound,mx_game_over\n", encoding="utf-8", newline="\n")


def decompress_ff(data: bytes) -> tuple[bytes, bytes, str]:
    if len(data) < FF_HEADER_LEN:
        _die("donor fastfile is too small")
    header, body = data[:FF_HEADER_LEN], data[FF_HEADER_LEN:]
    try:
        return header, zlib.decompress(body), "stream"
    except zlib.error:
        pass
    out = bytearray()
    i = 0
    while i + 2 <= len(body):
        size = struct.unpack_from(">H", body, i)[0]
        i += 2
        if size == 0:
            break
        if i + size > len(body):
            _die("truncated zlib chunk in donor fastfile")
        chunk = body[i : i + size]
        i += size
        try:
            out.extend(zlib.decompress(chunk))
        except zlib.error:
            out.extend(zlib.decompress(chunk, wbits=-15))
    if not out:
        _die("could not decompress donor fastfile")
    return header, bytes(out), "chunks"


def compress_ff(header: bytes, zone: bytes, mode: str) -> bytes:
    if mode == "stream":
        return header + zlib.compress(zone, 9)
    parts = [header]
    for off in range(0, len(zone), CHUNK):
        block = zone[off : off + CHUNK]
        if len(block) < CHUNK:
            block = block + b"\x00" * (CHUNK - len(block))
        packed = zlib.compress(block, 9)
        parts.append(struct.pack(">H", len(packed)))
        parts.append(packed)
    return b"".join(parts)


def patch_zone(zone: bytes) -> bytes:
    if DONOR_ALIAS not in zone:
        _die("donor fastfile does not contain mx_game_over")
    patched = zone.replace(DONOR_WAV, TARGET_WAV).replace(DONOR_ALIAS, TARGET_ALIAS)
    if TARGET_ALIAS not in patched:
        _die("patch failed to write mx_nr_stones")
    if DONOR_ALIAS in patched:
        _die("donor alias still present after patch")
    return patched


def link_donor(root: Path, game_path: Path, linker: Path, out_ff: Path) -> None:
    zones = game_path / "zone" / "english"
    proto = zones / "nazi_zombie_prototype.ff"
    if not proto.is_file():
        _die(f"missing donor map fastfile: {proto}")
    if not linker.is_file():
        _die(f"missing OAT linker: {linker}")
    out_ff.parent.mkdir(parents=True, exist_ok=True)
    args = [
        str(linker),
        "--asset-search-path",
        "src;stock/weapons;zone_source",
        "--output-folder",
        str(out_ff.parent),
        "-l",
        str(proto),
        "nr_radio",
    ]
    log = root / "tools" / "nr_radio.link.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w", encoding="utf-8") as fh:
        proc = subprocess.run(args, cwd=root, stdout=fh, stderr=subprocess.STDOUT)
    produced = out_ff.parent / "nr_radio.ff"
    if proc.returncode != 0 or not produced.is_file():
        tail = log.read_text(encoding="utf-8", errors="replace").splitlines()[-25:]
        _die("OAT failed to copy stock mx_game_over into nr_radio.ff\n" + "\n".join(tail))
    if produced.resolve() != out_ff.resolve():
        shutil.copy2(produced, out_ff)


def main() -> None:
    if len(DONOR_ALIAS) != len(TARGET_ALIAS) or len(DONOR_WAV) != len(TARGET_WAV):
        _die("alias/wav names must be equal length for in-place FF patching")
    parser = argparse.ArgumentParser()
    parser.add_argument("--game-path", default=r"C:\Call Of Duty World At War")
    parser.add_argument("--root", default="")
    args = parser.parse_args()
    root = Path(args.root).resolve() if args.root else Path(__file__).resolve().parents[1]
    write_zone(root / "zone_source" / "nr_radio.zone")
    donor = root / "build" / "nr_radio.donor.ff"
    out_ff = root / "build" / "nr_radio.ff"
    linker = root / "tools" / "oat-032" / "Linker.exe"
    game_path = Path(args.game_path)
    link_donor(root, game_path, linker, donor)
    header, zone, mode = decompress_ff(donor.read_bytes())
    patched = patch_zone(zone)
    out_ff.write_bytes(compress_ff(header, patched, mode))
    print(f"Clone-RadioAlias: wrote {out_ff} ({mode} compress, {out_ff.stat().st_size} bytes)")


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # pragma: no cover - build-host diagnostics
        _die(str(exc))
        sys.exit(1)
