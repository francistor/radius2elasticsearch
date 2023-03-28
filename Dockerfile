# syntax=docker/dockerfile:1

FROM golang:1.18-alpine AS build

WORKDIR /radius2elasticsearch
# Now we are in /radius2elastic folder

# Copy dependencies...
COPY go.mod ./
COPY go.sum ./
RUN go mod download

# ... and our code
COPY *.go ./
COPY resources ./resources/
# Avoid linking externally to libc which will give a file not found error when executing
RUN CGO_ENABLED=0 go build -o radius2elasticsearch

## Deploy
FROM gcr.io/distroless/base-debian11
WORKDIR /

COPY --from=build --chown=nonroot:nonroot /radius2elasticsearch/radius2elasticsearch /radius2elasticsearch/radius2elasticsearch
COPY --from=build --chown=nonroot:nonroot /radius2elasticsearch/resources/ /radius2elasticsearch/resources/

USER nonroot:nonroot

# Cannot use ENTRYPOINT, which will use sh
CMD ["/radius2elasticsearch/radius2elasticsearch", "-boot", "/radius2elasticsearch/resources/searchRules.json"]



