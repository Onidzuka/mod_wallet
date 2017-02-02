FROM project.tengri.vpn:5000/dependencies
RUN apk add --no-cache nodejs tzdata

COPY Gemfile* /tmp/
WORKDIR /tmp
RUN bundle install

ENV app /app
RUN mkdir $app
WORKDIR $app
COPY . $app
