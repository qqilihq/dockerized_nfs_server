#!/bin/bash
set -e

export_base="/exports/"

# (optionally) allow to specify custom export options through environment
export_options=${EXPORT_OPTIONS:-rw,sync,insecure,no_subtree_check,no_root_squash}

### Handle `docker stop` for graceful shutdown
function shutdown {
    echo "- Shutting down nfs-server.."
    service nfs-kernel-server stop
    echo "- Nfs server is down"
    exit 0
}

trap "shutdown" SIGTERM
####

echo "Export points:"
echo "$export_base *($export_options,fsid=0)" | tee /etc/exports

read -a exports <<< "${@}"
for export in "${exports[@]}"; do
    src=`echo "$export" | sed 's/^\///'` # trim the first '/' if given in export path
    src="$export_base$src"
    mkdir -p $src
    chmod 777 $src
    echo "$src *($export_options)" | tee -a /etc/exports
done

echo -e "\n- Initializing nfs server.."
rpcbind
service nfs-kernel-server start

echo "- Nfs server is up and running.."

## Run forever
sleep infinity
