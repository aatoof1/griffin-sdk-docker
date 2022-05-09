#!/bin/bash
#Run as the host user's GID and UID or default IDs

# echo $HOST_UID
# echo $HOST_GID

# if [[ ! -z "${HOST_UID}" && ! -z "${HOST_GID}" ]]; then
# 	echo "Starting with UID: $HOST_UID, GID: $HOST_GID"
# 	# ls -an /home/user
# 	# groupmod -g ${HOST_GID} user
# 	# ls -an /home/user
# 	# usermod -u ${HOST_UID} user
# 	# ls -an /home/user
# fi

# su -c "$@"

# exec gosu user "$@"


USER_ID=${HOST_UID:-1000}
GROUP_ID=${HOST_GID:-1000}

echo "Starting with UID: $USER_ID, GID: $GROUP_ID"
#Create group called `user`
groupadd -g $GROUP_ID -o user
#Create user called `user`
useradd -u $USER_ID -o -m -g user -m user

# mv /tmp/zephyr-sdk-${ZEPHYR_SDK_VERSION} /home/user
# chown -R user:user /home/user/zephyr-sdk-${ZEPHYR_SDK_VERSION}

# gosu user bash -c ' \
# cd ~ && \
# bash zephyr-sdk-${ZEPHYR_SDK_VERSION}/setup.sh -t all -h -c'

exec gosu user "$@"

# mv /tmp/zephyr-sdk-${ZEPHYR_SDK_VERSION} ~ && \
# tar xf /tmp/zephyr-sdk-${ZEPHYR_SDK_VERSION}_linux-x86_64.tar.gz && \


# echo 'user ALL = NOPASSWD: ALL' > /etc/sudoers.d/user
# ls -l /etc/sudoers.d
# chmod 0440 /etc/sudoers.d/user
# ls -l /etc/sudoers.d
# #Switch from root to user
# exec gosu user "$@"

# sudo -E -- bash -c ' \
# 	/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}/setup.sh -c && \
# 	chown -R user:user /home/user/.cmake \
# 	'
