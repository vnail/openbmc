#!/bin/bash
#
# Copyright 2015-present Facebook. All Rights Reserved.
#
# This program file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program in a file named COPYING; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor,
# Boston, MA 02110-1301 USA

. /usr/local/bin/openbmc-utils.sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin

# Because the voltage leak from uS COM pins could cause uS to struck when
# transitting from S5 to S0, we will need to explicitely pull down uS COM
# pins before powering off/reset and restoring COM pins after

pull_down_us_com() {
    # set GPIOL6 and GPIOL7 low
    devmem_clear_bit $(scu_addr 84) 22
    devmem_clear_bit $(scu_addr 84) 23
    gpio_set 94 0
    gpio_set 95 0
    # now, connect uart from BMC to the uS
    gpio_set 32 1
}

restore_us_com() {
    devmem_set_bit $(scu_addr 84) 22
    devmem_set_bit $(scu_addr 84) 23
    # if sol.sh is running, keep uart from uS connected with BMC
    if pidof -x sol.sh > /dev/null 2>&1; then
        gpio_set 32 1
    else
        gpio_set 32 0
    fi
}

while true; do
    if ! wedge_is_us_on 1 '' 0 > /dev/null 2>&1; then
        pull_down_us_com
    else
        restore_us_com
    fi
    usleep 400000               # 400ms
done
