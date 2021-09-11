FROM node:14 as build-stage

ARG ENV

WORKDIR /usr/src/staticserver

COPY package*.json ./
COPY .npmrc ./

RUN --mount=type=secret,id=GH_TOKEN export GH_TOKEN=`cat /run/secrets/GH_TOKEN`; npm ci --only=production 
#build the app
WORKDIR /usr/src/staticserver/node_modules/@fails-components/app
RUN npm run build
#build the lectureapp
WORKDIR /usr/src/staticserver/node_modules/@fails-components/lectureapp
RUN npm run build

WORKDIR /usr/src/staticserver
RUN npm i -g oss-attribution-generator && mkdir -p oss-attribution && generate-attribution

FROM nginx:1.21
COPY ./nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/app/build/ /usr/share/nginx/html/static/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureapp/build/ /usr/share/nginx/html/static/lecture
COPY --from=build-stage /usr/src/staticserver/oss-attribution/ /usr/share/nginx/html/static/oss/

VOLUME ["/usr/share/nginx/htmlsecuredfiles"]

