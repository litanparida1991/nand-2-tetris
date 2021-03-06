#!/usr/bin/env bash
#title          :run_tests.sh
#description    :This script will run all the required tests to check if CPU is working
#author         :ghaiklor
#date           :2019-08-19
#version        :0.1
#usage          :bash run_tests.sh
#bash_version   :3.2.57(1)-release
#===================================================================================

set -euo pipefail

PROJECT_ROOT=$PWD
PROJECT_TOOLS_ROOT=$PROJECT_ROOT/tools
COMPILER_SPEC=$PROJECT_ROOT/spec/compiler
CPU_SPEC=$PROJECT_ROOT/spec/cpu
HASM_SPEC=$PROJECT_ROOT/spec/hasm
VM_SPEC=$PROJECT_ROOT/spec/vm
OS_SPEC=$PROJECT_ROOT/spec/os
CPU_SOURCES=$PROJECT_ROOT/src/cpu
COMPUTER_SOURCES=$CPU_SOURCES/computer
OS_SOURCES=$PROJECT_ROOT/src/os

COMPILER_EXECUTABLE=$PROJECT_ROOT/target/debug/compiler
HASM_EXECUTABLE=$PROJECT_ROOT/target/debug/hasm
VM_EXECUTABLE=$PROJECT_ROOT/target/debug/vm

SUCCESS_COLOR="\033[32m"
PENDING_COLOR="\033[33m"
FAILED_COLOR="\033[31m"
DEFAULT_COLOR="\033[39m"

function header() {
    echo -e "$PENDING_COLOR--->"
    echo -e "---> $1"
    echo -e "--->$DEFAULT_COLOR"
}

function success() {
    echo -e "$SUCCESS_COLOR---> $1$DEFAULT_COLOR"
}

function pending() {
    echo -e "$PENDING_COLOR---> $1$DEFAULT_COLOR"
}

function failed() {
    echo -e "$FAILED_COLOR---> $1$DEFAULT_COLOR"
}

# Assembling and testing spec files for CPU, according to Project 1, 2, 3, 4, 5, 6
function cpu_spec() {
    echo

    header "Assembling $CPU_SPEC"
    for asm_file in "$CPU_SPEC"/**/*.asm; do
        "$HASM_EXECUTABLE" --input "$asm_file" --output "$(dirname "$asm_file")/$(basename "$asm_file" .asm).hack"
        success "🙂 $(basename "$asm_file")"
    done

    echo
    header "Testing $CPU_SPEC"
    for tst_file in "$CPU_SPEC"/**/*.tst; do
        # Fill.tst can not be tested automatically
        if [[ $tst_file =~ Fill.tst ]]; then
            continue
        fi

        "$PROJECT_TOOLS_ROOT"/cpu_emulator.sh "$tst_file" > /dev/null 2>&1
        success "🙂 $(basename "$tst_file")"
    done

    echo
    header "Running tests for $CPU_SOURCES"
    for tst_file in "$CPU_SOURCES"/**/*.tst; do
        # Memory.tst can not be tested automatically
        if [[ $tst_file =~ Memory.tst ]]; then
            continue
        fi

        pending "🕰 Simulating $(basename "$tst_file")"
        "$PROJECT_TOOLS_ROOT"/hardware_simulator.sh "$tst_file" > /dev/null 2>&1
    done
}

function hasm_spec() {
    echo

    header "Assembling $HASM_SPEC"
    for asm_file in "$HASM_SPEC"/*.asm; do
        "$HASM_EXECUTABLE" --input "$asm_file" --output "$(dirname "$asm_file")/$(basename "$asm_file" .asm).hack"
        success "🙂 $(basename "$asm_file")"
    done

    echo
    header "Moving assembled files to $COMPUTER_SOURCES"
    for hack_file in "$HASM_SPEC"/*.hack; do
        mv "$hack_file" "$COMPUTER_SOURCES/$(basename "$hack_file")"
        success "🙂 $(basename "$hack_file") -> $COMPUTER_SOURCES/$(basename "$hack_file")"
    done
}

# Running tests for the Project 7, 8
function vm_spec() {
    echo

    header "Translating $VM_SPEC"
    for vm_file in "$VM_SPEC"/**/*.vm; do
        # These are the cases when we need to translate the whole directory
        if [[ $(dirname "$vm_file") =~ fibonacci-element ]]; then
            "$VM_EXECUTABLE" --input "$(dirname "$vm_file")" --output "$(dirname "$vm_file")/FibonacciElement.asm"
            success "🙂 $(basename "$vm_file")"
            continue
        fi

        if [[ $(dirname "$vm_file") =~ nested-call ]]; then
            "$VM_EXECUTABLE" --input "$(dirname "$vm_file")" --output "$(dirname "$vm_file")/NestedCall.asm"
            success "🙂 $(basename "$vm_file")"
            continue
        fi

        if [[ $(dirname "$vm_file") =~ statics-test ]]; then
            "$VM_EXECUTABLE" --input "$(dirname "$vm_file")" --output "$(dirname "$vm_file")/StaticsTest.asm"
            success "🙂 $(basename "$vm_file")"
            continue
        fi

        "$VM_EXECUTABLE" --input "$vm_file" --output "$(dirname "$vm_file")/$(basename "$vm_file" .vm).asm"
        success "🙂 $(basename "$vm_file")"
    done

    header "Running tests for $VM_SPEC"
    for tst_file in "$VM_SPEC"/**/*.tst; do
        pending "🕰 Simulating $(basename "$tst_file")"

        if [[ $tst_file =~ VME.tst ]]; then
            "$PROJECT_TOOLS_ROOT"/vm_emulator.sh "$tst_file" > /dev/null 2>&1
        else
            "$PROJECT_TOOLS_ROOT"/cpu_emulator.sh "$tst_file" > /dev/null 2>&1
        fi
    done
}

function compiler_spec() {
    echo

    header "Compiling $COMPILER_SPEC"
    for jack_file in "$COMPILER_SPEC"/**/*.jack; do
        "$COMPILER_EXECUTABLE" --input "$jack_file" --emit-tokens --emit-ast
        success "🙂 $(basename "$jack_file")"
    done

    echo
    header "Comparing tokens in $COMPILER_SPEC"
    for jack_file in "$COMPILER_SPEC"/**/*.jack; do
        "$PROJECT_TOOLS_ROOT"/text_comparer.sh "$(dirname "$jack_file")/$(basename "$jack_file" .jack).tok" "$(dirname "$jack_file")/$(basename "$jack_file" .jack)T.xml" > /dev/null 2>&1
        success "🙂 $(basename "$jack_file")"
    done

    echo
    header "Comparing ast in $COMPILER_SPEC"
    for jack_file in "$COMPILER_SPEC"/**/*.jack; do
        my_file=$(xmllint --format --c14n --nonet --noblanks "$(dirname "$jack_file")/$(basename "$jack_file" .jack).ast")
        cmp_file=$(xmllint --format --c14n --nonet --noblanks "$(dirname "$jack_file")/$(basename "$jack_file" .jack).xml")
        diff -qwyEbBad <(echo "$my_file") <(echo "$cmp_file")
        success "🙂 $(basename "$jack_file")"
    done
}

function os_spec () {
    echo

    header "Compiling $OS_SPEC"
    for jack_file in "$OS_SPEC"/**/*.jack; do
        "$COMPILER_EXECUTABLE" --input "$jack_file"
        "$COMPILER_EXECUTABLE" --input "$OS_SOURCES"
        mv "$OS_SOURCES"/*.vm "$(dirname "$jack_file")"
        success "🙂 $(basename "$jack_file")"
    done

    header "Running tests for $OS_SPEC"
    for tst_file in "$OS_SPEC"/**/*.tst; do
        pending "🕰 Simulating $(basename "$tst_file")"
        "$PROJECT_TOOLS_ROOT"/vm_emulator.sh "$tst_file" > /dev/null 2>&1
    done
}

hasm_spec
cpu_spec
vm_spec
compiler_spec
os_spec

echo
success "All tests have been passed!"
