FROM node:20.16.0 as web_compile
WORKDIR /home
COPY . .
RUN <<EOF
cd ktransformers/website/ &&
npm install @vue/cli --registry=https://registry.npmmirror.com/ &&
npm run build --registry=https://registry.npmmirror.com/ &&
rm -rf node_modules
EOF



FROM pytorch/pytorch:2.3.1-cuda12.1-cudnn8-devel as compile_server
WORKDIR /workspace
ENV CUDA_HOME /usr/local/cuda
COPY --from=web_compile /home/ktransformers /workspace/ktransformers
RUN <<EOF
apt update -y &&  apt install -y  --no-install-recommends \
    git \
    wget \
    vim \
    gcc \
    g++ \
    cmake && 
rm -rf /var/lib/apt/lists/* &&
cd ktransformers &&
git submodule init  &&
git submodule update &&
pip install ninja pyproject numpy cpufeature  -i https://pypi.tuna.tsinghua.edu.cn/simple &&
pip install flash-attn  -i https://pypi.tuna.tsinghua.edu.cn/simple &&
CPU_INSTRUCT=NATIVE  KTRANSFORMERS_FORCE_BUILD=TRUE TORCH_CUDA_ARCH_LIST="8.0;8.6;8.7;8.9;9.0+PTX" pip install . --no-build-isolation --verbose  -i https://pypi.tuna.tsinghua.edu.cn/simple &&
pip cache purge
EOF

ENTRYPOINT [ "/opt/conda/bin/ktransformers" ]
