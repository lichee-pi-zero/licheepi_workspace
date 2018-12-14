#!/usr/bin/env python
# init_py_dont_write_bytecode

#init_boilerplate

from time import sleep

from fabric.api import *
from fabric.colors import *
from fabric.context_managers import *
from fabric.contrib.project import *


import multiprocessing
total_cpu_threads = multiprocessing.cpu_count()


LICHEE_ZERO_BRMIN_ALPHA_DD_IMG_PATH = './lichee_zero-brmin_alpha.dd'
LICHEE_ZERO_BRMIN_ALPHA_TAR_PATH = './brmin_dd.tar.bz2'

def sleepAndWait(prompt,second_s):
    print(prompt)
    sleep(second_s)

def ensureUnmount(sd_dev):
    for i in range(0,5+1):
        with settings(warn_only=True):
            for j in range(0,2+1):
                local('sudo umount %s%d' % (sd_dev,j))
    sleepAndWait('SLEEP A SECOND TO LET SYSTEM READY',10)


def threaded_local(command):
    local(command, capture=True)

def dd_image(sd_dev, img_path):
    ensureUnmount(sd_dev)

    local('sudo dd if=/dev/zero of=%s bs=1024 count=10' % sd_dev)
    sleepAndWait('sleep a second to let system ready',10)

    local('sudo dd if=%s of=%s bs=1G' % (img_path, sd_dev))

    local('sync')
    sleepAndWait('sleep a second to let system ready',10)

    ensureUnmount(sd_dev)

def lichee_zero_brmin_alpha_dd(sd_dev):
    dd_image(sd_dev, LICHEE_ZERO_BRMIN_ALPHA_DD_IMG_PATH)
