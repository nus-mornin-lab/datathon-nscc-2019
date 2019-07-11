# syntax=docker/dockerfile:experimental
FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-get update && \
    apt-get install --no-install-recommends -y curl wget

# install miniconda
ENV CONDA_PREFIX=/opt/conda CONDA_VERSION=4.6.14
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p ${CONDA_PREFIX} && \
    rm ~/miniconda.sh && \
    ${CONDA_PREFIX}/bin/conda clean -tipsy && \
    cat ${CONDA_PREFIX}/etc/profile.d/conda.sh >> /etc/bash.bashrc && \
    echo "conda activate base" >> /etc/bash.bashrc && \
    find ${CONDA_PREFIX} -follow -type f -name '*.a' -delete && \
    find ${CONDA_PREFIX} -follow -type f -name '*.js.map' -delete && \
    ${CONDA_PREFIX}/bin/conda clean -afy
RUN --mount=type=cache,id=conda,target=/opt/conda/pkgs \
    ${CONDA_PREFIX}/bin/conda update -n base --all

# pin packages
RUN . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    conda config --system --add pinned_packages cudatoolkit=9.0 && \
    conda config --env --add pinned_packages defaults::tensorflow && \
    conda config --env --add pinned_packages defaults::tensorflow-base && \
    conda config --env --add pinned_packages defaults::tensorflow-gpu && \
    conda config --env --add pinned_packages defaults::tensorflow-estimator && \
    conda config --env --add pinned_packages pytorch::pytorch && \
    conda config --env --add pinned_packages pytorch::torchvision

# install python libraries
COPY environment.yml environment.yml
RUN --mount=type=cache,id=conda,target=/opt/conda/pkgs \
    . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    conda env update -f environment.yml

# install jupyter lab and ipywidgets (requires nodejs)
ENV NODE_VERSION=node_11.x
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo "deb https://deb.nodesource.com/${NODE_VERSION} xenial main" >> /etc/apt/sources.list.d/nodesource.list && \
    echo "deb-src https://deb.nodesource.com/${NODE_VERSION} xenial main" >> /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    jupyter lab clean && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

# install R and jupyter kernel for R
ENV DEBIAN_FRONTEND noninteractive
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    echo "deb https://cloud.r-project.org/bin/linux/ubuntu xenial-cran35/" >> /etc/apt/sources.list.d/r.list && \
    apt-get update && \
    apt-get install -y \
        libopenblas-dev \
        r-base-dev \
        libxml2-dev \
        libssh2-1-dev \
        libssl-dev && \
    . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    Rscript -e "install.packages('IRkernel'); IRkernel::installspec(prefix = '${CONDA_PREFIX}')"

# enable arbitrary user other than root to install packages
RUN chmod a=u -R ${CONDA_PREFIX}

COPY docker-entrypoint.sh docker-cmd.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/docker-cmd.sh"]
