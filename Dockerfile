FROM node:21-alpine

# Create app directory and non-root user

WORKDIR /usr/src/app
RUN addgroup -S appgroup && adduser -S appuser -G appgroup \
	# Copy package files and install dependencies as root
	&& chown -R appuser:appgroup /usr/src/app

# Copy package files and install dependencies as root
COPY package*.json ./
RUN npm install

# Copy the rest of the app code
COPY . .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /usr/src/app

# Switch to non-root user
USER appuser

EXPOSE 5000
CMD [ "npm", "start" ]
