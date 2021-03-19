#!/usr/bin/env python3

import sys
import re
from collections import namedtuple

ops = {
        'addi':  (0x001, 'i'),
        'addm':  (0x002, 'a'),
        'addpc': (0x004, None),
        'bvs':   (0x008, 'a'),
        'ldai':  (0x010, 'i'),
        'ldam':  (0x020, 'a'),
        'ldapc': (0x040, None),
        'stam':  (0x080, 'a'),
        'stapc': (0x100, None),
        'dw':    (None,  'd'),
        }

Emit = namedtuple('Emit', 'code otype operand offset line')

def get_int(text):
    try:
        try:
            value = int(text)
        except ValueError:
            value = int(text, 16)
        if value < 0 or value > 65535:
            raise ValueError(f"Number out of range: {value}")
    except ValueError:
        value = text.lower()

    return value

def assemble(stream):
    labels = {}
    address = 0
    trans = []
    addr_pattern = re.compile(r"^\((?P<addr>[^)]+)\)(?:\+(?P<offset>\d+))?$")
    for n, line in enumerate(stream, 1):
        # Discard comments
        content = line.partition('#')[0].strip()
        if not content:
            continue

        label, _, rest = content.partition(':')
        if _ == ':':
            labels[label.lower()] = address
            content = rest.strip()
            if not content:
                continue

        splt = content.split()
        instr = splt[0].lower()
        try:
            opcode, otype = ops[instr]
        except KeyError:
            print(f"Syntax error at line {n}", file=sys.stderr)
            return -1

        operand = ' '.join(splt[1:])
        try:
            if otype in ('d', 'i'):
                trans.append(Emit(opcode, otype, get_int(operand), 0, n))
                address = address + (1 if otype == 'd' else 2)
            elif otype == 'a':
                # Recognize address
                ret = addr_pattern.match(operand)
                if ret is None:
                    raise ValueError("Expected a valid addressing operand")
                trans.append(Emit(opcode, otype, get_int(ret['addr']), int(ret['offset'] or '0'), n))
                address = address + 2
            elif otype is None:
                trans.append(Emit(opcode, None, None, 0, n))
                address = address + 1
        except ValueError as e:
            print(f"Error at line {n}: {e}")
            return -1

    for emitting in trans:
        if emitting.code is not None:
            print(f"{emitting.code:04x}")
        operand = None
        if emitting.otype is not None:
            operand = emitting.operand
            if not isinstance(operand, int):
                try:
                    operand = labels[operand]
                except KeyError:
                    print(f"Unknown label {operand} at line {emitting.line}")
                    return -1
            print(f"{operand + emitting.offset:04x}")


def main():
    return assemble(sys.stdin)

if __name__ == '__main__':
    sys.exit(main())
