# docker build -t tungsten-canyon -f tungsten-canyon.dockerfile .
# docker run -it -p 8080:80 tungsten-canyon

FROM --platform=linux/amd64 ubuntu:jammy

MAINTAINER Edward Ward III <edward.ward@occamsolutions.com>

# update and upgrade system dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -qq -y update
RUN apt-get -qq -y upgrade
RUN apt-get -qq -y install \
        gcc \
        g++ \
        wget \
        curl \
        make \
        unzip \
        sudo \
        cmake

# Add tungsten user and group to sudoers
RUN useradd -ms /bin/bash tungsten
RUN echo "tungsten ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN usermod -a -G tungsten tungsten

# Swith to tungsten user
WORKDIR /app
RUN chown -R tungsten:tungsten /app
USER tungsten

# download miniconda Python 3.9
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-py39_23.3.1-0-Linux-x86_64.sh -O miniconda.sh

# check miniconda SHA256 checksum
RUN echo "1564571a6a06a9999a75a6c65d63cb82911fc647e96ba5b729f904bf00c177d3  miniconda.sh" | sha256sum -c -

# install miniconda
RUN bash miniconda.sh -b -p /app/miniconda
ENV PATH="/app/miniconda/bin:${PATH}"

# Update conda
RUN conda update -n base -c defaults conda -y
RUN conda create -n env python=3.9
RUN echo "conda activate env" >> ~/.bashrc
RUN conda install pip -y

#Installing FAISS
RUN conda install --name env -c pytorch faiss-cpu -y

# Use C.UTF-8 locale to avoid issues with ASCII encoding
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Set the working directory to /app
WORKDIR /app
ENV APP /app
ENV LASER $APP/LASER
ENV MODELS $LASER/models

RUN which pip

# Install packages specified in requirements.txt using /app/miniconda/bin/pip
COPY docker/requirements.txt $APP/requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt --verbose

WORKDIR $LASER
COPY docker/install_external_tools.sh $LASER/install_external_tools.sh
RUN sudo chown tungsten:tungsten $LASER/install_external_tools.sh
RUN sudo ./install_external_tools.sh

COPY docker/install_models.sh $LASER/install_models.sh
RUN sudo chown tungsten:tungsten $LASER/install_models.sh
RUN sudo ./install_models.sh

# Download LASER 2.0 and Laser 3.0 models
# Zero paramaters on download_models.sh will limit downloads to LASER 2 languages
WORKDIR $MODELS
COPY docker/download_models.sh $LASER/download_models.sh
RUN sudo chown tungsten:tungsten $LASER/download_models.sh
RUN sudo $LASER/download_models.sh

# Copy app files and test files
WORKDIR $APP
COPY docker/decode.py $APP/decode.py
COPY docker/embed.py $APP/embed.py
COPY docker/romanize_lc.py $LASER/romanize_lc.py
COPY docker/text_processing.py $APP/text_processing.py
COPY docker/embed.sh $APP/embed.sh

RUN sudo chown tungsten:tungsten $APP/decode.py $APP/embed.py \
    $LASER/romanize_lc.py $APP/text_processing.py $APP/embed.sh

# run test
RUN echo "Hello World!" > test.txt
RUN ./embed.sh test.txt test_embed.raw
RUN python decode.py test_embed.raw

RUN sudo apt-get install -y perl

EXPOSE 80

COPY docker/app.py $APP/app.py

CMD ["python", "app.py"]