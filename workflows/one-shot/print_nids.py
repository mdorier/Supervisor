#!/usr/bin/env python
import os
import sys

NID_LIST_VAR = 'COBALT_PARTNAME'

#os.environ[NID_LIST_VAR] = "1-3,5,7,8,21,27-23,9"

def main():
    nidlst = []
    nidstr = os.environ[NID_LIST_VAR]
    nidgroups = nidstr.split(',')
    for nidgroup in nidgroups:
        if (nidgroup.find("-") != -1):
            a, b = nidgroup.split("-", 1)
            a = int(a)
            b = int(b)
            if (a > b):
                tmp = b
                b = a
                a = tmp
            b = b + 1 #need one more for inclusive
        else:
            a = int(nidgroup)
            b = a + 1
        for nid in range(a, b):
            nidlst.append(nid)
    nidlst = sorted(list(set(nidlst)))
    for nid in nidlst:
        print(nid)


if __name__ == "__main__":
    main()
