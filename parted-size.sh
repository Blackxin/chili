#!/bin/bash

parted --script /dev/sdc -- \
   mklabel gpt             \
   mkpart primary fat32      1MiB 2MiB set 1 bios on name 1 BIOS  \
   mkpart primary fat32      2MiB 3MiB set 2 esp  on name 2 EFI   \
   mkpart primary linux-swap 3MiB 2GB                name 3 SWAP  \
   mkpart primary ext4       2GB 100%                name 4 ROOT  \
   align-check optimal 1
