#!/usr/bin/env python3
"""Capture the real browser parity harness through Chrome DevTools."""

from __future__ import annotations

import argparse
import base64
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import urllib.request

import websocket


def wait_for_url(url: str, timeout: float = 20) -> None:
    deadline = time.time() + timeout
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(url, timeout=1):
                return
        except Exception:
            time.sleep(0.1)
    raise RuntimeError(f"Timed out waiting for {url}")


def capture(repo: Path, output: Path, chrome: str, probe_output: Path | None) -> None:
    output.mkdir(parents=True, exist_ok=True)
    profile = tempfile.mkdtemp(prefix="thinking-orbs-chrome-")
    vite = subprocess.Popen(
        ["npm", "run", "dev", "--", "--host", "127.0.0.1", "--port", "5177"],
        cwd=repo,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT,
    )
    browser = subprocess.Popen(
        [
            chrome,
            "--headless=new",
            "--disable-background-networking",
            "--remote-allow-origins=*",
            "--remote-debugging-port=9223",
            f"--user-data-dir={profile}",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        wait_for_url("http://127.0.0.1:5177/parity.html")
        wait_for_url("http://127.0.0.1:9223/json/version")
        request = urllib.request.Request(
            "http://127.0.0.1:9223/json/new?http://127.0.0.1:5177/parity.html",
            method="PUT",
        )
        with urllib.request.urlopen(request) as response:
            target = json.load(response)
        socket = websocket.create_connection(target["webSocketDebuggerUrl"], timeout=30)
        socket.send(
            json.dumps(
                {
                    "id": 1,
                    "method": "Runtime.evaluate",
                    "params": {
                        "expression": "(async()=>{while(!window.orbCapture){await new Promise(r=>setTimeout(r,25));}return window.orbCapture({format:'png'});})()",
                        "awaitPromise": True,
                        "returnByValue": True,
                    },
                }
            )
        )
        while True:
            response = json.loads(socket.recv())
            if response.get("id") == 1:
                break
        socket.close()
        if "exceptionDetails" in response:
            raise RuntimeError(response["exceptionDetails"])
        images = response["result"]["result"]["value"]
        for key, data_url in images.items():
            encoded = data_url.split(",", 1)[1]
            (output / f"{key}.png").write_bytes(base64.b64decode(encoded))
        print(f"Generated {len(images)} web captures at {output}")
        if probe_output is not None:
            probe_output.mkdir(parents=True, exist_ok=True)
            expression = """(()=>{const out={};for(const r of [0.35,0.5,1,2,5]){for(const dark of [true,false]){const c=document.createElement('canvas');c.width=40;c.height=40;const x=c.getContext('2d');x.setTransform(2,0,0,2,0,0);const g=Math.round((dark?0.7:0.3)*255);x.fillStyle=`rgba(${g},${g},${g},0.65)`;x.beginPath();x.arc(10,10,r,0,Math.PI*2);x.fill();out[`probe-r${r}-${dark?'d':'l'}`]=c.toDataURL('image/png');}}for(const dark of [true,false]){const c=document.createElement('canvas');c.width=40;c.height=40;const x=c.getContext('2d');x.setTransform(2,0,0,2,0,0);const g=Math.round((dark?0.7:0.3)*255);x.fillStyle=`rgba(${g},${g},${g},0.15)`;for(let i=0;i<24;i++){x.beginPath();x.arc(10+Math.sin(i*1.7)*0.8,10+Math.cos(i*2.3)*0.8,1.3,0,Math.PI*2);x.fill();}out[`probe-overlap-${dark?'d':'l'}`]=c.toDataURL('image/png');}return out;})()"""
            socket = websocket.create_connection(target["webSocketDebuggerUrl"], timeout=30)
            socket.send(json.dumps({"id": 2, "method": "Runtime.evaluate", "params": {"expression": expression, "returnByValue": True}}))
            while True:
                probe_response = json.loads(socket.recv())
                if probe_response.get("id") == 2:
                    break
            socket.close()
            probes = probe_response["result"]["result"]["value"]
            for key, data_url in probes.items():
                (probe_output / f"{key}.png").write_bytes(base64.b64decode(data_url.split(",", 1)[1]))
            print(f"Generated {len(probes)} web raster probes at {probe_output}")
    finally:
        browser.terminate()
        vite.terminate()
        browser.wait(timeout=10)
        vite.wait(timeout=10)
        shutil.rmtree(profile, ignore_errors=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", nargs="?", default="build/parity/web")
    parser.add_argument(
        "--chrome",
        default="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    )
    parser.add_argument("--probe-output")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parent.parent
    probe_output = (repo / args.probe_output).resolve() if args.probe_output else None
    capture(repo, (repo / args.output).resolve(), args.chrome, probe_output)


if __name__ == "__main__":
    main()
