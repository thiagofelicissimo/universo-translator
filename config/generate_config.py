#!/bin/python3
"""
USAGE: generate_cts.py N
N is the number of universes that need to be generated
"""


import sys

def printElab():
    print("""
def elaboration : Type.
    [] cts.star --> cts.var.
    [] cts.box --> cts.var.
    [] cts.ball --> cts.var.
    [] cts.triangle --> cts.var.
    [] cts.diamond --> cts.var.
    [] cts.sinf --> cts.var.""")
    print()

def printOutput():
    print("def output : Type.")

    for i in range(0,num_univ):
        print(f"    [] cts.enum {'(cts.usucc '*i}cts.uzero{')'*i} --> cts.set{i}.")
    print()

def printQFUF():
    print("def qfuf_specification : Type.")
    for i in range(0, num_univ-1):
        print(f"    [] cts.Axiom cts.set{i} cts.set{i+1} --> cts.true.")

    for i in range(0, num_univ):
        for j in range(0, num_univ):
            print(f"    [] cts.Rule cts.set{i} cts.set{j} cts.set{max(i,j)} --> cts.true.")

    print("    [a] cts.Cumul a a --> cts.true.")
    print()

def printSolver():
    print("def solver : Type.")
    print()

def printEnd():
    print("def end : Type.")
    print()

if __name__ == '__main__':
    num_univ = int(sys.argv[1])
    printElab()
    printOutput()
    printQFUF()
    printSolver()
    printEnd()
