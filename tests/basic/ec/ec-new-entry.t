#!/bin/bash

. $(dirname $0)/../../include.rc
. $(dirname $0)/../../volume.rc

cleanup
function num_entries {
        ls -l $1 | wc -l
}

function get_md5sum {
        md5sum $1 | awk '{print $1}'
}

TEST glusterd
TEST pidof glusterd
TEST $CLI volume create $V0 disperse 6 redundancy 2 $H0:$B0/${V0}{0..5}
TEST $CLI volume start $V0
TEST glusterfs --entry-timeout=0 --attribute-timeout=0 -s $H0 --volfile-id $V0 $M0
EXPECT_WITHIN $CHILD_UP_TIMEOUT "6" ec_child_up_count $V0 0
touch $M0/{1..10}
touch $M0/11
for i in {1..10}; do dd if=/dev/zero of=$M0/$i bs=1M count=1; done
TEST $CLI volume replace-brick $V0 $H0:$B0/${V0}5 $H0:$B0/${V0}6 commit force
EXPECT_WITHIN $CHILD_UP_TIMEOUT "6" ec_child_up_count $V0 0
EXPECT_WITHIN $HEAL_TIMEOUT "^0$" get_pending_heal_count $V0
#ls -l gives "Total" line so number of lines will be 1 more
EXPECT "^12$" num_entries $B0/${V0}6
ec_version=$(get_hex_xattr trusted.ec.version $B0/${V0}0)
EXPECT "$ec_version" get_hex_xattr trusted.ec.version $B0/${V0}1
EXPECT "$ec_version" get_hex_xattr trusted.ec.version $B0/${V0}2
EXPECT "$ec_version" get_hex_xattr trusted.ec.version $B0/${V0}3
EXPECT "$ec_version" get_hex_xattr trusted.ec.version $B0/${V0}4
EXPECT "$ec_version" get_hex_xattr trusted.ec.version $B0/${V0}6
file_md5sum=$(get_md5sum $M0/1)
empty_md5sum=$(get_md5sum $M0/11)
TEST kill_brick $V0 $H0 $B0/${V0}0
TEST kill_brick $V0 $H0 $B0/${V0}1
echo $file_md5sum
EXPECT "$file_md5sum" get_md5sum $M0/1
EXPECT "$file_md5sum" get_md5sum $M0/2
EXPECT "$file_md5sum" get_md5sum $M0/3
EXPECT "$file_md5sum" get_md5sum $M0/4
EXPECT "$file_md5sum" get_md5sum $M0/5
EXPECT "$file_md5sum" get_md5sum $M0/6
EXPECT "$file_md5sum" get_md5sum $M0/7
EXPECT "$file_md5sum" get_md5sum $M0/8
EXPECT "$file_md5sum" get_md5sum $M0/9
EXPECT "$file_md5sum" get_md5sum $M0/10
EXPECT "$empty_md5sum" get_md5sum $M0/11

cleanup;
