#!/bin/bash
set +m  # Disable job control

args=("$@")
for i in "${!args[@]}"; do
    echo "Index: $i - Value: ${args[$i]}"
done

testsug=("test1" "test2" "test3")
for i in "${!testsug[@]}"; do
    echo "suggestion $i: ${testsug[$i]}"   
done