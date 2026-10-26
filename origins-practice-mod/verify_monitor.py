#!/usr/bin/env python3
"""Check monitor gameplay logic against the actual supplied original source.

Only instrumentation, explicit namespaces, the constant wait helper and dev
blocks are normalized. A change to the remaining production logic fails.
"""
from pathlib import Path
import difflib
import re

root = Path(__file__).resolve().parent
original_path = Path('/workspace/Recompilable-gscs-for-BO2-zombies-and-multiplayer/ZM/Core/maps/mp/zombies/_zm.gsc')
mod_path = root / 'src/scripts/zm/zm_tomb/deathbarrier_practice.gsc'


def function_body(source, name):
    source = re.sub(r'/#.*?#/', '', source, flags=re.S)
    source = re.sub(r'//[^\n]*', '', source)
    begin = source.index('\n' + name + '()')
    begin = source.index('{', begin)
    depth = 1
    end = begin + 1
    while depth:
        depth += (source[end] == '{') - (source[end] == '}')
        end += 1
    return source[begin:end]


original = function_body(original_path.read_text(), 'player_out_of_playable_area_monitor')
mod = function_body(mod_path.read_text(), 'dbp_monitor')
mod = re.sub(r'^\s*self\.dbp_[^\n]*;\s*$', '', mod, flags=re.M)
mod = re.sub(r'^\s*self thread dbp_[^\n]*;\s*$', '', mod, flags=re.M)
mod = re.sub(r'^\s*self dbp_start_wait\([^\n]*;\s*$', '', mod, flags=re.M)
mod = mod.replace('maps\\mp\\zombies\\_zm::', '')
original = original.replace('wait( get_player_out_of_playable_area_monitor_wait_time() );', 'wait 3;')
normalize = lambda value: re.sub(r'\s+', '', value)
if normalize(original) != normalize(mod):
    print('\n'.join(difflib.unified_diff(original.splitlines(), mod.splitlines())))
    raise SystemExit('FAIL: monitor production logic differs')
print('PASS: production monitor control flow, waits and lethal actions match the original after removing HUD instrumentation')
