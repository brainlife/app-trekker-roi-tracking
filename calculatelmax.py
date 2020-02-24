#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Created on Fri Aug  4 20:06:19 2017
@author: lindseykitchell
"""

import json
import os

# get bvals file path
#bvals= os.environ['BVALS']

with open('config.json') as config_json:
    config = json.load(config_json)

with open(config["dtiinit"]+'/dt6.json') as dt6_json:
    dt6config = json.load(dt6_json)

#get non0 bvals
#f = open(config["bvals"], 'r')
f = open(config["dtiinit"]+"/"+dt6config["files"]["alignedDwBvals"], 'r')
line = f.readline().strip().replace(",", " ")
bvals = line.split(" ")
bvals_non0 = filter(lambda v: v != "0", bvals)
count=len(bvals_non0);

#calculate max lmax (6->2, 15->4, 28->6, etc..)
lmax=0
while (lmax+3)*(lmax+4)/2 <= count:
       lmax+=2

print lmax
