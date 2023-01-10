FROM node:alpine3.17 as build
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build
EXPOSE 80
ENV PORT=80
# using pm2 would be much better but 🤷
CMD [ "node", "./build/index.js" ]