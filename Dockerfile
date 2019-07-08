FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# install miniconda
ENV CONDA_PREFIX=/opt/conda CONDA_VERSION=4.6.14
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    ${CONDA_PREFIX}/bin/conda clean -tipsy && \
    cat ${CONDA_PREFIX}/etc/profile.d/conda.sh >> /etc/bash.bashrc && \
    echo "conda activate base" >> /etc/bash.bashrc && \
    find ${CONDA_PREFIX} -follow -type f -name '*.a' -delete && \
    find ${CONDA_PREFIX} -follow -type f -name '*.js.map' -delete && \
    ${CONDA_PREFIX}/bin/conda clean -afy && \
    ${CONDA_PREFIX}/bin/conda update -n base -c defaults conda && \
    ${CONDA_PREFIX}/bin/conda update -n base --all

# install python libraries and jupyter lab
COPY environment.yml environment.yml
RUN . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    conda env update -f environment.yml && \
    jupyter lab clean && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager

# install R and jupyter kernel for R
ENV DEBIAN_FRONTEND noninteractive
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/" > /etc/apt/sources.list.d/r.list && \
    apt-get update && \
    apt-get install -y \
        libopenblas-dev \
        r-base-dev \
        libxml2-dev \
        libssh2-1-dev \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    . ${CONDA_PREFIX}/etc/profile.d/conda.sh && \
    conda activate base && \
    Rscript -e "install.packages('IRkernel'); IRkernel::installspec(prefix = '${CONDA_PREFIX}')"

# enable arbitrary user other than root to install packages
RUN chmod a=u -R ${CONDA_PREFIX}

ENV TINI_VERSION v0.18.0
RUN wget --quiet https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -O /tini && \
    chmod +x /tini

COPY docker-entrypoint.sh docker-cmd.sh /
ENTRYPOINT ["/tini", "--", "/docker-entrypoint.sh"]
CMD ["/docker-cmd.sh"]
