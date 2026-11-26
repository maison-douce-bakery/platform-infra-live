locals {
  name = "mdb-prod-ingest-open-meteo"

  # The bucket comes from the datalake stack.
  datalake_bucket_name = "mdb-prod-datalake-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}"

  # Bump after each image build.
  ingest_image_digest = "sha256:58a99af1f468be2f72cdc8d3cb5dd74c754e7ec64a2029b76643e84a6e3f79fc"

  image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.region}.amazonaws.com/mdb/ingest-open-meteo@${local.ingest_image_digest}"
}
