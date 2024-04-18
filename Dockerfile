FROM node:lts

# Create app directory
WORKDIR /app

# Install Nodemon
RUN npm install -g nodemon

# Install app dependencies
COPY package*.json ./
RUN npm install


# Bundle app source
COPY . .
USER node

EXPOSE 3000
CMD npm run dev

