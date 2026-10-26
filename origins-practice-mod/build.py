#!/usr/bin/env python3
"""Build verified T6 bytecode and a Windows install ZIP without editing the game."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser()
parser.add_argument('--compiler', default='/workspace/tools/gsc-tool-1.6.0/gsc-tool')
args = parser.parse_args()
relative = Path('scripts/zm/zm_tomb/deathbarrier_practice.gsc')
with tempfile.TemporaryDirectory(prefix='db-practice-build-') as temporary:
    cwd = Path(temporary)
    common = [args.compiler, '-g', 't6', '-s', 'pc']
    subprocess.run(common + ['-m', 'comp', str(root / 'src')], cwd=cwd, check=True)
    binary = cwd / 'compiled/t6' / relative
    data = binary.read_bytes()  # Require a fresh output even if a runner returns 0.
    if len(data) <= 64 or data[:8] != bytes.fromhex('804753430d0a0006'):
        raise SystemExit('Not a valid T6 GSC object')
    subprocess.run(common + ['-m', 'decomp', str(binary)], cwd=cwd, check=True)
    recovered = cwd / 'decompiled/t6' / relative.name
    text = recovered.read_text()
    for required in ['dbp_monitor()', 'dbp_update_hud()', 'dbp_place_marker( ui )',
                     'replacefunc(', 'self.lives = 0;', 'wait 0.5;', 'wait 3;']:
        if required not in text:
            raise SystemExit(f'Missing from decompiled output: {required}')
    subprocess.run(common + ['-m', 'comp', '-y', str(recovered)], cwd=cwd, check=True)
    output = root / 'dist/t6' / relative
    output.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(binary, output)

archive = root / 'dist/Origins-DeathBarrier-Practice.zip'
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
    bundle.write(output, 't6/' + relative.as_posix())
    bundle.write(root / 'src' / relative, 'source/' + relative.name)
    for name in ['README.md', 'install.ps1', 'uninstall.ps1']:
        bundle.write(root / name, name)
print(f'PASS: compiled, checked T6 header, decompiled, recompiled; {len(data)} bytes')
print(archive)
