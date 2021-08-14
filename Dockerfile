FROM node:14 as build-stage

ARG ENV
ARG GH_TOKEN

WORKDIR /usr/src/staticserver

COPY package*.json ./
COPY .npmrc ./

RUN npm ci --only=production 
#build the app
WORKDIR /usr/src/staticserver/node_modules/@fails-components/app
RUN npm run build
#build the lectureapp
WORKDIR /usr/src/staticserver/node_modules/@fails-components/lectureapp
RUN npm run build


FROM nginx:1.21
COPY ./nginx.conf /etc/nginx/templates/default.conf.template
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/app/build/ /usr/share/nginx/html/static/app
COPY --from=build-stage /usr/src/staticserver/node_modules/@fails-components/lectureapp/build/ /usr/share/nginx/html/static/lecture

VOLUME ["/usr/share/nginx/htmlsecuredfiles"]

