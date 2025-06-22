#libAV stage to be removed after libav is released with fixes
#FROM emscripten/emsdk as libavstage

#RUN apt-get update -y && apt-get upgrade -y && apt-get install -y pkg-config git

#WORKDIR /usr/src

#RUN git clone https://github.com/Yahweasel/libav.js.git

#WORKDIR /usr/src/libav.js
#RUN  git checkout 2aab58662ca6b0ba24eac71dd33918925bd799a8

#RUN make build-opus

#FROM node:18-bookworm-slim as libavcodecstage

#WORKDIR /usr/src
#RUN git clone https://github.com/ennuicastr/libavjs-webcodecs-polyfill.git
# clone a specific branch until merged

#WORKDIR /usr/src/libavjs-webcodecs-polyfill
#RUN git checkout e148ad33037c8575e27b8f9500d119c4523d23c5

#RUN make
# end temporary code

FROM node:22-bookworm-slim AS build-stage

ARG ENV

WORKDIR /usr/src/staticserver

COPY package*.json ./
COPY .npmrc ./
# next line is a dummy to prevent parallel execution
#COPY --from=libavstage /usr/src/libav.js/dist/libav-*opus*.js /tmp/
RUN --mount=type=secret,id=GH_TOKEN export GH_TOKEN=`cat /run/secrets/GH_TOKEN`; npx browserslist@latest --update-db
RUN --mount=type=secret,id=GH_TOKEN export GH_TOKEN=`cat /run/secrets/GH_TOKEN`; npm ci --only=production 
#build the app
WORKDIR /usr/src/staticserver/node_modules/@fails-components/app
RUN mkdir -p /usr/src/staticserver/node_modules/@fails-components/app/node_modules -p && mv /usr/src/staticserver/node_modules/@fails-components/appexperimental/public/iconexp.svg /usr/src/staticserver/node_modules/@fails-components/appexperimental/public/icon.svg && ln -s /usr/src/staticserver/node_modules/qr-scanner /usr/src/staticserver/node_modules/@fails-components/app/node_modules/qr-scanner
RUN export REACT_APP_VERSION=$(npm pkg get version | sed 's/"//g'); \
    export REACT_APP_JUPYTER_PROXY_DOMAINS="pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev";\
    npm run build
# tempcode for libav
#COPY --from=libavstage /usr/src/libav.js/dist/libav-*opus* /usr/src/staticserver/node_modules/libav.js/
#COPY --from=libavcodecstage /usr/src/libavjs-webcodecs-polyfill/libavjs-* /usr/src/staticserver/node_modules/libavjs-webcodecs-polyfill/
# build the experimental app
WORKDIR /usr/src/staticserver/node_modules/@fails-components/appexperimental
RUN mkdir -p /usr/src/staticserver/node_modules/@fails-components/appexperimental/node_modules -p \
    && mv /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/public/iconexp.svg /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/public/icon.svg \
    && ln -s /usr/src/staticserver/node_modules/qr-scanner /usr/src/staticserver/node_modules/@fails-components/appexperimental/node_modules/qr-scanner \
    && ln -s /usr/src/staticserver/node_modules/libav.js /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/node_modules/libav.js \
    && ln -s /usr/src/staticserver/node_modules/pdfjs-dist /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/node_modules/pdfjs-dist \ 
    && ln -s /usr/src/staticserver/node_modules/libavjs-webcodecs-polyfill /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/node_modules/libavjs-webcodecs-polyfill \
    && mkdir -p /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/node_modules/@mediapipe \
    && ln -s /usr/src/staticserver/node_modules/@mediapipe/tasks-vision /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/node_modules/@mediapipe/tasks-vision \
    && ln -s /usr/src/staticserver/node_modules/libav.js /usr/src/staticserver/node_modules/@fails-components/lectureapp/node_modules/libav.js \
    && ln -s /usr/src/staticserver/node_modules/pdfjs-dist /usr/src/staticserver/node_modules/@fails-components/lectureapp/node_modules/pdfjs-dist \ 
    && ln -s /usr/src/staticserver/node_modules/libavjs-webcodecs-polyfill /usr/src/staticserver/node_modules/@fails-components/lectureapp/node_modules/libavjs-webcodecs-polyfill \
    && mkdir -p /usr/src/staticserver/node_modules/@fails-components/lectureapp/node_modules/@mediapipe \
    && ln -s /usr/src/staticserver/node_modules/@mediapipe/tasks-vision /usr/src/staticserver/node_modules/@fails-components/lectureapp/node_modules/@mediapipe/tasks-vision
RUN export REACT_APP_VERSION=$(npm pkg get version | sed 's/"//g');\
    export PUBLIC_URL=/static/experimental/app/;\
    export REACT_APP_JUPYTER_PROXY_DOMAINS="pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev";\
    npm run build
#build the lectureapp
WORKDIR /usr/src/staticserver/node_modules/@fails-components/lectureapp
RUN export REACT_APP_VERSION=$(npm pkg get version | sed 's/"//g'); \
    export REACT_APP_JUPYTER_PROXY_DOMAINS="pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev";\
    npm run build
#build the experimental lectureapp
WORKDIR /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental
RUN export REACT_APP_VERSION=$(npm pkg get version | sed 's/"//g'); \
    export PUBLIC_URL=/static/experimental/lecture/;\
    export REACT_APP_JUPYTER_PROXY_DOMAINS="pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev";\
    npm run build

WORKDIR /usr/src/staticserver
RUN npm i -g oss-attribution-generator && mkdir -p oss-attribution && generate-attribution

FROM node:22-bookworm-slim AS jupyter-build

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y git pipx wget

RUN mkdir -p ~/miniconda3 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh && \
    bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3 &&\
    rm -rf ~/miniconda3/miniconda.sh && \
     ~/miniconda3/bin/conda init bash
RUN ~/miniconda3/bin/conda create -y -n failscomponents --override-channels --strict-channel-priority -c conda-forge -c nodefaults \
    jupyterlab=4.4 \
    nodejs=22 \
    git copier=7 jinja2-time \
    jupyterlite-core=0.6.2 \
    jupyterlite-pyodide-kernel=0.6.1 \
    jupyterlite-xeus=4.0.3

RUN ~/miniconda3/bin/conda run -n failscomponents pip install \
    fails-components-jupyter-applet-view==0.0.2 \
    fails-components-jupyter-filesystem-extension==0.0.2 \
    fails-components-jupyter-interceptor==0.0.2 \
    fails-components-jupyter-launcher==0.0.2

WORKDIR /usr/src/jupyterlite/

COPY jupyter/*.yml ./
COPY jupyter/*.json ./
RUN ~/miniconda3/bin/conda run -n failscomponents jupyter lite build


FROM nginx:stable AS staticserver-noassets
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/app/build/ /usr/share/nginx/html/static/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureapp/build/ /usr/share/nginx/html/static/lecture
#workaround to remove old service worker
RUN cp /usr/share/nginx/html/static/lecture/sw.js /usr/share/nginx/html/static/lecture/service-worker.js

COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/appexperimental/build/ /usr/share/nginx/html/static/experimental/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/build/ /usr/share/nginx/html/static/experimental/lecture
#workaround to remove old service worker
RUN cp /usr/share/nginx/html/static/experimental/lecture/sw.js /usr/share/nginx/html/static/experimental/lecture/service-worker.js

COPY --from=build-stage /usr/src/staticserver/oss-attribution/ /usr/share/nginx/html/static/oss/
RUN mkdir -p /usr/share/nginx/html/config
COPY ./nginx.conf.noassets /etc/nginx/templates/default.conf.template
COPY ./40-copy-fails-env.sh /docker-entrypoint.d

RUN echo "pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev" | tr ' ' '\n' | sed 's/$/ 1;/' > /etc/nginx/allowed_jupyter_proxy_hosts.conf
COPY --from=jupyter-build /usr/src/jupyterlite/jupyterLiteFailsOut/ /usr/share/nginx/html/jupyter/

FROM nginx:stable
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/app/build/ /usr/share/nginx/html/static/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureapp/build/ /usr/share/nginx/html/static/lecture
#workaround to remove old service worker
RUN cp /usr/share/nginx/html/static/lecture/sw.js /usr/share/nginx/html/static/lecture/service-worker.js

COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/appexperimental/build/ /usr/share/nginx/html/static/experimental/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureappexperimental/build/ /usr/share/nginx/html/static/experimental/lecture
#workaround to remove old service worker
RUN cp /usr/share/nginx/html/static/experimental/lecture/sw.js /usr/share/nginx/html/static/experimental/lecture/service-worker.js

COPY --from=build-stage /usr/src/staticserver/oss-attribution/ /usr/share/nginx/html/static/oss/
RUN mkdir -p /usr/share/nginx/html/config
COPY ./nginx.conf /etc/nginx/templates/default.conf.template
COPY ./40-copy-fails-env.sh /docker-entrypoint.d

RUN echo "pypi.org files.pythonhosted.org cdn.jsdelivr.net raw.githubusercontent.com repo.prefix.dev shards.prefix.dev" | tr ' ' '\n' | sed 's/$/ 1;/' > /etc/nginx/allowed_jupyter_proxy_hosts.conf
COPY --from=jupyter-build /usr/src/jupyterlite/jupyterLiteFailsOut/ /usr/share/nginx/html/jupyter/

VOLUME ["/usr/share/nginx/htmlsecuredfiles"]

