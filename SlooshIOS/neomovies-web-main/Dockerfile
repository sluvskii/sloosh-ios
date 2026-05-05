FROM node:23-alpine

RUN apk add --no-cache git

WORKDIR /app

RUN git clone https://gitlab.com/foxixus/neomovies-web .

RUN npm install

EXPOSE 4173

CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
