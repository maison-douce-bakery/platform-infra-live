locals {
  name              = "mdb-dev-dagu"
  capacity_provider = "mdb-dev-ec2"

  # The image creates user dagu as uid/gid 1000 and drops to it after the entrypoint.
  dagu_uid = 1000

  dagu_image = "ghcr.io/dagucloud/dagu:2.27.0-alpine@sha256:bfe39d9ee261fcb69992308ef0419229e31ced8474032a9f507181b3edc86787"
}
