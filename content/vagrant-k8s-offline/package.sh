#!/bin/bash

image_space="registry.cn-hangzhou.aliyuncs.com/modoso"

images=(
    "kube-apiserver:v1.30.7"
    "kube-controller-manager:v1.30.7"
    "kube-proxy:v1.30.7"
    "kube-scheduler:v1.30.7"
    "pause:3.9"
    "coredns:v1.12.1,coredns/coredns:v1.12.1"
)

function check_docker(){
    docker ps >/dev/null 2>&1 && return 0 || ( echo "[ERR] docker unavailable.", return 1)
}

function download_and_save_images(){
    for image_line in ${images[@]}
    do
       origin_tag=${image_line//,*}
       as_tag=${image_line//*,}
       timeout 10 docker pull "${image_space}/${origin_name}" > /dev/null && return 0 || return 1
       if test "${origin_tag}" = "${as_tag}"; then
           docker tag  "${image_space}/${origin_name}" "${image_space}/${as_tag}"
       fi
       docker save ${image_space}/${as_tag} -o ${as_tag}.tar 
    done
}

function download_libraries(){
    docker pull "${image_space}/k8s_package:1.0.0"
    
}