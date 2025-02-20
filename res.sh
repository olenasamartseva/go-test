fallocate -l 6G /swapfile && \
chmod 600 /swapfile && \
mkswap /swapfile && \
swapon /swapfile && \
swapon --show && \
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab && \
sysctl vm.swappiness=10 && \
sysctl vm.vfs_cache_pressure=50 && \
echo "vm.swappiness=10" >> /etc/sysctl.conf && \
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
