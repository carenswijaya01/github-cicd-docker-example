FROM node:alpine

WORKDIR /usr/src/app

COPY ./index.js .
COPY ./package.json .
COPY ./package-lock.json .

RUN npm i

CMD [ "npm", "run", "start" ]
