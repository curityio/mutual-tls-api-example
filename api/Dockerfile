FROM node:16.6.0-alpine

RUN apk --no-cache add curl
#RUN apk --no-cache add openssl

RUN addgroup -g 1001 apigroup
RUN adduser -u 1001 -G apigroup -h /home/apiuser -D apiuser

WORKDIR /usr/local/api
COPY api/dist/                      /usr/local/api/dist/
COPY api/package*.json              /usr/local/api/
RUN npm install --production

USER apiuser
CMD ["npm", "run", "startApi"]
