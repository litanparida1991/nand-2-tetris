#!/usr/bin/env bash

set -eu

function assembly_tests() {
    echo "Assembling examples/cpu..."
    for asm_file in "$PWD"/examples/cpu/**/*.asm; do
        echo "Assembling $asm_file..."
        "$PWD"/tools/assembler.sh "$asm_file" > /dev/null 2>&1
    done

    echo "Running tests for examples/cpu..."
    for tst_file in "$PWD"/examples/cpu/**/*.tst; do
        # Fill.tst can not be tested automatically
        if [[ $tst_file =~ Fill.tst ]]; then
            continue
        fi

        echo "Running $tst_file in cpu emulator..."
        "$PWD"/tools/cpu_emulator.sh "$tst_file" > /dev/null 2>&1
    done
}

function hardware_tests() {
    echo "Running tests for src/cpu..."
    for tst_file in "$PWD"/src/cpu/**/*.tst; do
        # Memory.tst can not be tested automatically
        if [[ $tst_file =~ Memory.tst ]]; then
            continue
        fi

        echo "Running $tst_file in hardware simulator..."
        "$PWD"/tools/hardware_simulator.sh "$tst_file" > /dev/null 2>&1
    done
}

assembly_tests
hardware_tests